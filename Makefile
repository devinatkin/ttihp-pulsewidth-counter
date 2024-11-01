# Makefile for testing with iverilog and vvp

# Define the compiler and simulator
IVL = iverilog -g2012
VVP = vvp

# Output directory for simulation files
OUT_DIR = sim_out

# Create the output directory if it doesn't exist
$(shell mkdir -p $(OUT_DIR))

# All source files (excluding testbenches)
SOURCES = src/tt_um_devinatkin_fastreadout.v src/shift_register.v src/output_parallel_to_serial.v src/repeated_add_multiplier.v src/frequency_module.v src/frequency_counter.v

# Phony targets
.PHONY: all clean

all: tb_frequency_counter

tb_frequency_counter:
	$(IVL) -o $(OUT_DIR)/$@.vvp src/frequency_counter.v tb/tb_frequency_counter.v
	$(VVP) $(OUT_DIR)/$@.vvp
