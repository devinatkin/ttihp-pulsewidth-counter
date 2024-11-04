# Makefile for testing with iverilog and vvp

# Define the compiler and simulator
IVL = iverilog -g2012
VVP = vvp

# Output directory for simulation files
OUT_DIR = sim_out

# Create the output directory if it doesn't exist
$(shell mkdir -p $(OUT_DIR))

# Phony targets
.PHONY: all clean

all: tb_frequency_counter

tb_frequency_counter:
	$(IVL) -o $(OUT_DIR)/$@.vvp src/frequency_counter.v tb/tb_frequency_counter.v
	$(VVP) $(OUT_DIR)/$@.vvp

tb_param_mux:
	$(IVL) -o $(OUT_DIR)/$@.vvp src/param_mux.v tb/tb_param_mux.v
	$(VVP) $(OUT_DIR)/$@.vvp

tb_output_selector:
	$(IVL) -o $(OUT_DIR)/$@.vvp src/output_selector.v tb/tb_output_selector.v
	$(VVP) $(OUT_DIR)/$@.vvp
	
clean:
	@echo Cleaning up...
	rm -rf $(OUT_DIR)