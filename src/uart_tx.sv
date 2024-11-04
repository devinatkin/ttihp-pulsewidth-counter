// Based on Module by : Yuya Kudo

module uart_tx #(parameter
    DATA_WIDTH = 8,
    BAUD_RATE = 115_200,
    CLK_FREQ = 50_000_000,

    localparam
    LB_DATA_WIDTH    = $clog2(DATA_WIDTH),
    PULSE_WIDTH      = CLK_FREQ / BAUD_RATE,
    LB_PULSE_WIDTH   = $clog2(PULSE_WIDTH),
    HALF_PULSE_WIDTH = PULSE_WIDTH / 2,
    PULSE_AND_HALF   = PULSE_WIDTH + HALF_PULSE_WIDTH)
    (
    output logic tx_signal,
    input logic [DATA_WIDTH-1:0] tx_data,
    input logic tx_valid,
    output logic tx_ready,
    input logic clk,
    input logic reset_n,
    input logic ena);

    typedef enum logic [1:0] {STT_DATA, 
                            STT_STOP,
                            STT_WAIT
                            } uart_state;

    uart_state state;

    logic [DATA_WIDTH-1:0] DATA_REG;
    logic SIGNAL_REG;
    logic READY_REG;
    logic [LB_DATA_WIDTH-1:0] DATA_CNT;
    logic [LB_PULSE_WIDTH:0] CLK_CNT;

    
    always_ff @(posedge clk) begin
        if(!reset_n) begin
            state <= STT_WAIT;
            SIGNAL_REG <= 1;
            DATA_REG <= 0;
            READY_REG <= 1;
            DATA_CNT <= 0;
            CLK_CNT <= 0;
        end else if(ena) begin
            case(state)
                // state: STT_WAIT
                // behavior: watch for a valid signal, and assert the start bit when valid signal is detected
                // next state: STT_DATA
                STT_WAIT: begin
                    if(CLK_CNT > 0) begin // If the clock counter is not zero, decrement it.
                        CLK_CNT <= CLK_CNT - 1;
                    end
                    else if (!READY_REG) begin  // If the ready signal is not asserted, assert it.
                        READY_REG <= 1;
                    end
                    else if (tx_valid) begin    // If the valid signal is asserted go to the STT_DATA state
                        state <= STT_DATA;      // Change state to STT_DATA
                        SIGNAL_REG <= 0;        // Set the signal to 0
                        DATA_REG <= tx_data;    // Load the data to be transmitted into the DATA_REG
                        READY_REG <= 0;         // Clear the ready signal to indicate that we are busy
                        DATA_CNT <= 0;          // Clear the data counter
                        CLK_CNT <= PULSE_WIDTH[LB_PULSE_WIDTH:0]; // Load the clock counter with the pulse width
                    end
                end

                // state: STT_DATA
                // behavior: Serialize and Transmit Data
                // next state: When all the data is transmitted, go to the STT_STOP state
                STT_DATA: begin
                    if(CLK_CNT > 0) begin       // If the clock counter is not zero, decrement it. 
                        CLK_CNT <= CLK_CNT - 1; // This is used to generate the pulse width for the output signal
                    end
                    else begin
                        SIGNAL_REG <= DATA_REG[DATA_CNT];   // Set the signal to the current bit of the data
                        CLK_CNT <= PULSE_WIDTH[LB_PULSE_WIDTH:0];             // Load the clock counter with the pulse width (so that the signal is held for the pulse width)

                        if(DATA_CNT == (DATA_WIDTH - 1)) begin
                            state <= STT_STOP;              // If all the data is transmitted, go to the STT_STOP state
                        end
                        else begin
                            DATA_CNT <= DATA_CNT + 1;       // Increment the data counter
                        end
                    end
                end

                // state: STT_STOP
                // behavior: Assert a Stop Bit
                // next state: STT_WAIT
                STT_STOP: begin
                    if(CLK_CNT > 0) begin
                        CLK_CNT <= CLK_CNT - 1;
                    end
                    else begin
                        SIGNAL_REG <= 1;                           // Assert the stop bit
                        CLK_CNT <= PULSE_AND_HALF[LB_PULSE_WIDTH:0]; // Load the clock counter with the pulse width
                        state <= STT_WAIT;                         // Go to the STT_WAIT state
                    end
                end

                // If we end up in an unknown state, go to the STT_WAIT state
                default: begin
                    state <= STT_WAIT;
                end
            endcase
        end
    end

    assign tx_signal = SIGNAL_REG;
    assign tx_ready = READY_REG;
endmodule