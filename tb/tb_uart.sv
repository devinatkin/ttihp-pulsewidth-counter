module tb_uart;

    // Parameters
    parameter DATA_WIDTH = 8;
    parameter BAUD_RATE = 115_200;
    parameter CLK_FREQ = 50_000_000;

    // Clock and Reset
    logic clk;
    logic reset_n;

    // UART signals
    logic ena;

    // UART Interface
    logic rx_tx_signal;
    logic [DATA_WIDTH-1:0] tx_data;
    logic tx_valid;
    logic tx_ready;

    logic [DATA_WIDTH-1:0] rx_data;
    logic rx_valid;
    logic rx_ready;

    // Watchdog counter
    int watchdog_counter;

    // UART instance
    uart #(
        .DATA_WIDTH(DATA_WIDTH),
        .BAUD_RATE(BAUD_RATE),
        .CLK_FREQ(CLK_FREQ)
    ) uart_inst (
        .clk(clk),
        .reset_n(reset_n),
        .ena(ena),
        .tx_signal(rx_tx_signal),
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready),
        .rx_signal(rx_tx_signal),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_ready(rx_ready)
    );

    // Clock generation
    always #10 clk = ~clk;

    // Watchdog logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            watchdog_counter <= 0;
        end else if (tx_ready || rx_valid) begin
            watchdog_counter <= 0;  // Reset the counter when output changes
        end else begin
            watchdog_counter <= watchdog_counter + 1;
            if (watchdog_counter >= 10000) begin
                $display("ERROR: Watchdog triggered at %0t: No output change for 100 clock cycles", $time);
                $stop;
            end
        end
    end

    // Testbench logic
    initial begin
        // $dumpfile("output.vcd"); // Specify the VCD file name
        // $dumpvars(0, tb_uart); // Replace <testbench_module> with the top module of your testbench

        // Initialize
        clk = 0;
        reset_n = 0;
        ena = 1;
        tx_data = 0;
        rx_ready = 0;
        // Apply reset
        #100;
        reset_n = 1;

        // Transmit and receive all possible values
        for (int i = 0; i < (1 << DATA_WIDTH); i++) begin
            // Send data
            $display("Sending %0d",i);

            tx_data = i;
            tx_valid = 1;        
            rx_ready = 0;
            // Wait for transmission to complete
            wait(tx_ready == 0);

            $display("Transmitting %0h", tx_data);
            tx_valid = 0;
            
            wait(tx_ready == 1);
            rx_ready = 1;
            // Wait for reception to complete
            wait(rx_valid == 1);
            $display("Receiving %0h", rx_data);

            // Check received data
            if (rx_data !== tx_data) begin
                $display("ERROR: Data mismatch at %0t: sent %0h, received %0h", $time, tx_data, rx_data);
                $finish;
            end else begin
                $display("SUCCESS: Data matched at %0t: sent %0h, received %0h", $time, tx_data, rx_data);
            end

            // Wait for the next transmission
            #100;
        end

        $display("All data transmitted and received successfully.");
        $finish;
    end

endmodule