module output_selector #(
    parameter COUNTER_BITS = 32, // Width of the time_high, time_low, and period inputs
    parameter DATA_WIDTH = 8     // Width of each UART data chunk
) (
    input wire clk,
    input wire rst_n,
    input wire [7:0] rx_data,           // Selection signal to choose output
    input wire [COUNTER_BITS-1:0] time_high, // COUNTER_BITS-wide input
    input wire [COUNTER_BITS-1:0] time_low,  // COUNTER_BITS-wide input
    input wire [COUNTER_BITS-1:0] period,    // COUNTER_BITS-wide input
    output reg [DATA_WIDTH-1:0] tx_data,     // UART data output
    output reg tx_valid,                // UART data valid signal
    input wire tx_ready                 // UART ready signal
);

    // Internal signals
    reg [COUNTER_BITS-1:0] selected_data; // Stores the selected data (time_high, time_low, or period)
    reg [COUNTER_BITS/DATA_WIDTH-1:0] byte_index; // Index to select which byte to send

    // State machine to control data transmission
    always @(posedge clk) begin
        if (!rst_n) begin
            tx_data <= 8'd0;
            tx_valid <= 1'b0;
            selected_data <= 0;
            byte_index <= 0;
        end else begin
            // Load selected data based on rx_data when starting new transmission
            if (tx_ready && !tx_valid) begin
                case (rx_data)
                    8'd0: selected_data <= time_high; // Select time_high
                    8'd1: selected_data <= time_low;  // Select time_low
                    8'd2: selected_data <= period;    // Select period
                    default: selected_data <= 0;      // Default case, output 0
                endcase
                byte_index <= 0;
                tx_valid <= 1'b1; // Start transmission of first byte
            end else if (tx_ready && tx_valid) begin
                // Transmit each byte sequentially
                tx_data <= selected_data[(byte_index * DATA_WIDTH) +: DATA_WIDTH];
                byte_index <= byte_index + 1;

                // Complete transmission after all bytes are sent
                if ({28'b0, byte_index} == (COUNTER_BITS / DATA_WIDTH) - 1) begin
                    tx_valid <= 1'b0;
                end
            end
        end
    end

endmodule
