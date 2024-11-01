`timescale 1ns / 1ps

module param_mux_tb;

    // Parameters
    parameter N = 4;           // Number of inputs
    parameter WIDTH = 8;       // Width of each input
    parameter SEL_WIDTH = $clog2(N);  // Width of selector

    // Testbench signals
    reg [N*WIDTH-1:0] data_in;
    reg [SEL_WIDTH-1:0] sel;
    wire [WIDTH-1:0] data_out;

    // Instantiate the MUX module
    param_mux #(
        .N(N),
        .WIDTH(WIDTH)
    ) uut (
        .data_in(data_in),
        .sel(sel),
        .data_out(data_out)
    );

    // Test procedure
    initial begin
        // Initialize inputs
        data_in = 0;
        sel = 0;

        // Apply test cases
        $display("Starting testbench for param_mux");

        // Set data_in with distinct values for each input
        data_in = {8'hA0, 8'hB1, 8'hC2, 8'hD3};  // Example values for 4 inputs of width 8

        // Test each selection
        for (int i = 0; i < N; i = i + 1) begin
            sel = i;
            #10;  // Wait 10 time units

            // Display the result
            $display("sel = %0d, data_out = %h (expected = %h)", sel, data_out, data_in[i*WIDTH +: WIDTH]);
            if (data_out !== data_in[i*WIDTH +: WIDTH]) begin
                $display("Test FAILED for sel = %0d", sel);
            end else begin
                $display("Test PASSED for sel = %0d", sel);
            end
        end

        $display("Testbench complete.");
        $finish;
    end

endmodule
