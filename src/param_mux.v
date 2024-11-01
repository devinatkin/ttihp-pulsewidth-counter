module param_mux #(
    parameter N = 4,        // Number of inputs
    parameter WIDTH = 8     // Width of each input
)(
    input  wire [N*WIDTH-1:0] data_in,  // Concatenated input bus
    input  wire [$clog2(N)-1:0] sel,    // Selector
    output wire [WIDTH-1:0] data_out    // Output
);

    // Internal logic to select the right input based on sel
    assign data_out = data_in[sel*WIDTH +: WIDTH];

endmodule
