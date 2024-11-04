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

  parameter CLOCK_FREQ = 50_000_000; // 50 MHz
  parameter CLOCK_PERIOD = 1000 / (CLOCK_FREQ / 1_000_000); // Clock period in nanoseconds
  parameter COUNTER_BITS = 16; // Updated counter width to 16 bits

  parameter sel_width = $clog2(6); 

  // All output pins must be assigned. If not used, assign to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  wire freq_in;

  wire [COUNTER_BITS-1:0] time_high;
  wire [COUNTER_BITS-1:0] time_low;
  wire [COUNTER_BITS-1:0] period;
  wire pulse;

  wire [sel_width-1:0] sel;
  wire [7:0] data_out; // Now only 8 bits wide for each output segment
  // List all unused inputs to prevent warnings
  wire _unused = &{ena, 1'b0};

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
      .N(6),
      .WIDTH(8) // Output width remains 8 bits for each high/low segment
  ) mux (
      .data_in({time_high, time_low, period}),
      .sel(sel[sel_width-1:0]),
      .data_out(data_out)
  );

  assign freq_in = ui_in[0];
  assign sel = ui_in[3:1]; // Updated to include the new high/low select bit
  assign uo_out[7:0] = data_out;

endmodule
