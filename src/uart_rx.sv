module uart_rx #(
    parameter DATA_WIDTH = 8,
    parameter BAUD_RATE = 115_200,
    parameter CLK_FREQ = 50_000_000
)
(
    input logic rx_signal,
    output logic [DATA_WIDTH-1:0] rx_data,
    output logic rx_valid,
    input logic rx_ready,
    input logic clk,
    input logic reset_n,
    input logic ena
);

    // Derived parameters with minimized widths
    localparam PULSE_WIDTH      = CLK_FREQ / BAUD_RATE;
    localparam HALF_PULSE_WIDTH = PULSE_WIDTH / 2;
    localparam LB_PULSE_WIDTH   = $clog2(PULSE_WIDTH);
    localparam LB_DATA_WIDTH    = $clog2(DATA_WIDTH);

    // Simplified noise filter using only 3 samples
    logic [2:0] SIGNAL_Q;
    logic SIGNAL_R;

    // Sample input signal with a 3-bit shift register
    always_ff @(posedge clk) begin
        if (!reset_n) begin
            SIGNAL_Q <= 3'b111;
            SIGNAL_R <= 1;
        end else if (ena) begin
            SIGNAL_Q <= {rx_signal, SIGNAL_Q[2:1]};
            // Majority filter with 3 samples
            SIGNAL_R <= (SIGNAL_Q[0] & SIGNAL_Q[1]) | (SIGNAL_Q[1] & SIGNAL_Q[2]) | (SIGNAL_Q[2] & SIGNAL_Q[0]);
        end
    end

    // UART state machine definitions
    typedef enum logic [1:0] {
        STT_WAIT,
        STT_DATA,
        STT_STOP
    } uart_state;

    uart_state state;

    logic [DATA_WIDTH-1:0] DATA_TEMP_REG;
    logic [LB_DATA_WIDTH:0] DATA_CNT;
    logic [LB_PULSE_WIDTH:0] CLK_CNT;
    logic RX_DONE;

    // Main state machine for UART reception
    always_ff @(posedge clk) begin
        if (!reset_n) begin
            state <= STT_WAIT;
            DATA_TEMP_REG <= 0;
            DATA_CNT <= 0;
            CLK_CNT <= 0;
        end else if (ena) begin
            case (state)
                // STT_WAIT: Wait for start bit (falling edge) to begin reception
                STT_WAIT: begin
                    if (SIGNAL_R == 0) begin // Detect start bit
                        CLK_CNT <= HALF_PULSE_WIDTH[LB_PULSE_WIDTH:0];
                        DATA_CNT <= 0;
                        state <= STT_DATA;
                    end
                end

                // STT_DATA: Deserialize data bits
                STT_DATA: begin
                    if (CLK_CNT > 0) begin
                        CLK_CNT <= CLK_CNT - 1;
                    end else begin
                        DATA_TEMP_REG <= {SIGNAL_R, DATA_TEMP_REG[DATA_WIDTH-1:1]};
                        CLK_CNT <= PULSE_WIDTH[LB_PULSE_WIDTH:0];
                        if (DATA_CNT == DATA_WIDTH - 1) begin
                            state <= STT_STOP;
                        end else begin
                            DATA_CNT <= DATA_CNT + 1;
                        end
                    end
                end

                // STT_STOP: Wait for stop bit to complete, then return to wait
                STT_STOP: begin
                    if (CLK_CNT > 0) begin
                        CLK_CNT <= CLK_CNT - 1;
                    end else if (SIGNAL_R) begin
                        state <= STT_WAIT;
                    end
                end
            endcase
        end
    end

    // Detect end of reception (when in STOP state with CLK_CNT complete)
    assign RX_DONE = (state == STT_STOP) && (CLK_CNT == 0);

    // Output registers for received data and valid signal
    logic [DATA_WIDTH-1:0] DATA_REG;
    logic VALID_REG;

    always_ff @(posedge clk) begin
        if (!reset_n) begin
            DATA_REG <= 0;
            VALID_REG <= 0;
        end else if (ena) begin
            if (RX_DONE && !VALID_REG) begin
                DATA_REG <= DATA_TEMP_REG;
                VALID_REG <= 1;
            end else if (VALID_REG && rx_ready) begin
                VALID_REG <= 0;
            end
        end
    end

    assign rx_data = DATA_REG;
    assign rx_valid = VALID_REG;

endmodule
