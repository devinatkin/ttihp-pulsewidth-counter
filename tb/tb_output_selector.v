`timescale 1ns / 1ps
`default_nettype none

module output_selector_tb;

    // Parameters
    parameter COUNTER_BITS = 32;
    parameter DATA_WIDTH = 8;

    // Testbench signals
    reg clk;
    reg rst_n;
    reg [7:0] rx_data;
    reg [COUNTER_BITS-1:0] time_high;
    reg [COUNTER_BITS-1:0] time_low;
    reg [COUNTER_BITS-1:0] period;
    wire [DATA_WIDTH-1:0] tx_data;
    wire tx_valid;
    reg tx_ready;

    // Instantiate the output_selector module
    output_selector #(
        .COUNTER_BITS(COUNTER_BITS),
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .rx_data(rx_data),
        .time_high(time_high),
        .time_low(time_low),
        .period(period),
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 ns period clock
    end

    // Reset signal
    initial begin
        rst_n = 0;
        #20 rst_n = 1;
    end

    // Stimulus
    initial begin
        // Initialize signals
        tx_ready = 1;
        rx_data = 8'd0;
        time_high = 32'h12345678;
        time_low = 32'h87654321;
        period = 32'hABCDEF01;

        // Wait for reset release
        @(posedge rst_n);

        // Test time_high selection
        rx_data = 8'd0;
        #10 tx_ready = 1;
        #10 tx_ready = 0; // Begin transmitting

        // Wait until tx_valid de-asserts after transmission
        wait(~tx_valid);
        #20;

        // Test time_low selection
        rx_data = 8'd1;
        #10 tx_ready = 1;
        #10 tx_ready = 0; // Begin transmitting

        // Wait until tx_valid de-asserts after transmission
        wait(~tx_valid);
        #20;

        // Test period selection
        rx_data = 8'd2;
        #10 tx_ready = 1;
        #10 tx_ready = 0; // Begin transmitting

        // Wait until tx_valid de-asserts after transmission
        wait(~tx_valid);
        #20;

        // Finish simulation
        $finish;
    end

    // Monitor to observe output
    initial begin
        $monitor("Time: %0dns, rx_data: %0d, tx_data: %0h, tx_valid: %b, byte_index: %0d", $time, rx_data, tx_data, tx_valid, uut.byte_index);
    end

endmodule
