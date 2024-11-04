// Based on Module by : Yuya Kudo

module uart 
    #(parameter
        DATA_WIDTH = 8,
        BAUD_RATE = 115_200,
        CLK_FREQ = 50_000_000)
    (
    input logic clk,
    input logic reset_n,
    input logic ena,
    output logic tx_signal,
    input logic [DATA_WIDTH-1:0] tx_data,
    input logic tx_valid,
    output logic tx_ready,
    input logic rx_signal,
    output logic [DATA_WIDTH-1:0] rx_data,
    output logic rx_valid,
    input logic rx_ready
    );

    uart_tx #(DATA_WIDTH, BAUD_RATE, CLK_FREQ)
    uart_tx_inst(
        .tx_signal(tx_signal),
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready),
        .clk(clk),         // clock signal
        .reset_n(reset_n), // active-low reset
        .ena(ena)          // enable signal
    );

    uart_rx #(DATA_WIDTH, BAUD_RATE, CLK_FREQ)
    uart_rx_inst(
        .rx_signal(rx_signal),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_ready(rx_ready),
        .clk(clk),         // clock signal
        .reset_n(reset_n), // active-low reset
        .ena(ena)          // enable signal
    );

endmodule