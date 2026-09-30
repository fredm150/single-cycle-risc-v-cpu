# Makefile for Single-Cycle RISC-V CPU Simulation (Verilator)

# Toolchain definitions
VERILATOR = verilator
GTKWAVE   = gtkwave

# Source files
RTL_SRCS  = alu.sv
TB_SRC    = alu_tb.sv
TOP_TB    = alu_tb
SIM_BIN   = sim_alu
TRACE_FILE = tb_alu.vcd

# Verilator flags
VERILATOR_FLAGS = --binary -j 0 -Wall -Wno-fatal --trace -o $(SIM_BIN)

.PHONY: all compile run wave clean

# Default target: compile and run
all: compile run

# Compile SystemVerilog sources using Verilator
compile:
	$(VERILATOR) $(VERILATOR_FLAGS) $(RTL_SRCS) $(TB_SRC)

# Execute the compiled simulation binary
run:
	./obj_dir/$(SIM_BIN)

# Launch GTKWave to view waveform traces
wave:
	$(GTKWAVE) $(TRACE_FILE) &

# Clean build artifacts
clean:
	rm -rf obj_dir $(TRACE_FILE)