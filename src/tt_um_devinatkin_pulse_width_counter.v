`default_nettype none

module tt_um_devinatkin_pulse_width_counter (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // ui[0]: "freq_in"
  // uo[0:7]: "time_hi_lo_per[0:7]"
  // ui[1]: "out_sel[0]"
  // ui[2]: "out_sel[1]"
  // ui[3]: "out_sel[2]"
  // ui[4]: "out_sel[3]"

  // uio[0]: "uart_tx"
  // uio[1]: "uart_rx"
  // uio[2]: "uart_tx_ready"
  // uio[3]: "uart_tx_valid"
  // uio[4]: "uart_rx_valid"
  // uio[5]: "uart_rx_ready"
  // uio[6]: ""
  // uio[7]: "pulse_out"

  parameter CLOCK_FREQ = 50_000_000; // 50 MHz
  parameter CLOCK_PERIOD = 1000 / (CLOCK_FREQ / 1_000_000); // Clock period in nanoseconds
  parameter COUNTER_BITS = 32; // Updated counter width to 32 bits

  parameter DATA_WIDTH = 8;
  parameter BAUD_RATE = 115200;
 
  parameter sel_width = $clog2(12); 

  wire freq_in;

  wire [COUNTER_BITS-1:0] time_high;
  wire [COUNTER_BITS-1:0] time_low;
  wire [COUNTER_BITS-1:0] period;
  wire pulse;

  wire [sel_width-1:0] sel;
  wire [7:0] data_out; // Now only 8 bits wide for each output segment

  wire tx_signal;
  wire [DATA_WIDTH-1:0] tx_data;
  wire tx_valid;
  wire tx_ready;

  wire rx_signal;
  wire [DATA_WIDTH-1:0] rx_data;
  wire rx_valid;
  wire rx_ready;

  assign uio_out[0] = tx_signal;
  assign uio_oe[0] = 1;

  assign uio_out[1] = 0;
  assign rx_signal = uio_in[1];
  assign uio_oe[1] = 0;

  assign uio_out[2] = tx_ready;
  assign uio_oe[2] = 1;

  assign uio_out[3] = tx_valid;
  assign uio_oe[3] = 1;

  assign uio_out[4] = rx_valid;
  assign uio_oe[4] = 1;

  assign rx_ready = uio_in[5];
  assign uio_oe[5] = 1;
  assign uio_out[5] = 0;

  // All output pins must be assigned. If not used, assign to 0.
  assign uio_out[6] = 0;
  assign uio_oe[6] = 0;

  assign uio_out[7] = pulse;
  assign uio_oe[7] = 1;

  frequency_counter #(
      .COUNTER_BITS(COUNTER_BITS)
  ) pulse_width_counter_module (
      .CLK(clk),
      .RST_N(rst_n),
      .FREQ_IN(freq_in),
      .TIME_HIGH(time_high),
      .TIME_LOW(time_low),
      .PERIOD(period),
      .PULSE(pulse)
  );


  param_mux #(
      .N(12),
      .WIDTH(8)
  ) mux (
      .data_in({time_high, time_low, period}),
      .sel(sel[sel_width-1:0]),
      .data_out(data_out)
  );

    uart #(
        .DATA_WIDTH(DATA_WIDTH),
        .BAUD_RATE(BAUD_RATE),
        .CLK_FREQ(CLOCK_FREQ)
    ) uart_inst (
        .clk(clk),
        .reset_n(rst_n),
        .ena(ena),
        .tx_signal(tx_signal),
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready),
        .rx_signal(rx_signal),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_ready(rx_ready)
    );

    output_selector #(
        .COUNTER_BITS(COUNTER_BITS),
        .DATA_WIDTH(DATA_WIDTH)
    ) out_sel (
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

  assign freq_in = ui_in[0];
  assign sel = ui_in[4:1]; // Updated to include the new high/low select bit
  assign uo_out[7:0] = data_out;

endmodule
