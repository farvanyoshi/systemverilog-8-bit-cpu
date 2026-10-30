VERILATOR ?= verilator
PYTHON    ?= python3
SV2V      ?= sv2v
YOSYS     ?= yosys

BUILD := build

# The package must be compiled before the modules that import it.
RTL := rtl/cpu_pkg.sv $(filter-out rtl/cpu_pkg.sv,$(sort $(wildcard rtl/*.sv)))

# Top module for `make lint`.
TOP ?= cpu_top

# Top module for `make synth`. The core is synthesized without its memories:
# an empty ROM would hold only HALT and optimize the whole CPU away.
SYNTH_TOP ?= cpu_core

# Programs are programs/<name>.asm, assembled into build/prog/.
PROGRAMS := $(patsubst programs/%.asm,%,$(wildcard programs/*.asm))

# Unit testbenches are tb/tb_<name>.sv with top module tb_<name>.
UNIT_TESTS := $(patsubst tb/tb_%.sv,%,$(filter-out tb/tb_cpu.sv,$(wildcard tb/tb_*.sv)))

VFLAGS  := -Wall -Wno-DECLFILENAME --timing -Irtl
TBFLAGS := $(VFLAGS) -Wno-UNUSEDPARAM -Wno-UNUSEDSIGNAL -Wno-WIDTH

.PHONY: all lint test unit programs $(addprefix test-,$(UNIT_TESTS)) $(addprefix prog-,$(PROGRAMS)) sim wave synth clean

all: test

lint:
	$(VERILATOR) --lint-only $(VFLAGS) --top-module $(TOP) $(RTL)

test: unit programs

unit: $(addprefix test-,$(UNIT_TESTS))

# Build a unit testbench: build/tb_<name>/sim
$(BUILD)/tb_%/sim: tb/tb_%.sv $(RTL)
	$(VERILATOR) --binary $(TBFLAGS) --top-module tb_$* -Mdir $(BUILD)/tb_$* \
		-o sim $(RTL) $< > $(BUILD)/tb_$*.log 2>&1 || { cat $(BUILD)/tb_$*.log; exit 1; }

$(addprefix test-,$(UNIT_TESTS)): test-%: | $(BUILD)
	@$(MAKE) --no-print-directory $(BUILD)/tb_$*/sim
	@$(BUILD)/tb_$*/sim +verilator+quiet

# Program-level testbench. Run a program with
#   make sim PROG=<name>       (programs/<name>.asm, checked against its expectations)
#   make sim HEX=<file.hex>    (raw image, no checks)
# Add TRACE=1 for a per-instruction trace; `make wave` also writes an FST.
CPU_SIM := $(BUILD)/tb_cpu/sim
$(CPU_SIM): TBFLAGS += --trace-fst

HEX ?= $(BUILD)/prog/$(PROG).hex
EXP ?= $(BUILD)/prog/$(PROG).exp
SIM_ARGS = +PROG=$(HEX) $(if $(PROG),+EXPECT=$(EXP)) $(if $(TRACE),+TRACE)

sim: $(CPU_SIM) $(if $(PROG),$(HEX) $(EXP))
	@$(CPU_SIM) +verilator+quiet $(SIM_ARGS)

wave: SIM_ARGS += +WAVE=$(BUILD)/$(or $(PROG),wave).fst
wave: sim

$(CPU_SIM): | $(BUILD)

programs: $(addprefix prog-,$(PROGRAMS))

$(addprefix prog-,$(PROGRAMS)): prog-%: $(CPU_SIM) $(BUILD)/prog/%.hex $(BUILD)/prog/%.exp
	@$(CPU_SIM) +verilator+quiet +PROG=$(BUILD)/prog/$*.hex +EXPECT=$(BUILD)/prog/$*.exp

$(BUILD)/prog/%.hex $(BUILD)/prog/%.exp: programs/%.asm tools/asm.py
	@mkdir -p $(BUILD)/prog
	$(PYTHON) tools/asm.py $< -o $(BUILD)/prog/$*.hex -e $(BUILD)/prog/$*.exp

# Synthesis check: sv2v lowers the SystemVerilog to Verilog-2005 for Yosys's
# built-in frontend, then a generic synth reports cell usage and fails on
# structural problems (combinational loops, multiple drivers, undriven nets).
$(BUILD)/cpu.v: $(RTL) | $(BUILD)
	$(SV2V) $(RTL) -w $@

synth: $(BUILD)/cpu.v
	$(YOSYS) -q -l $(BUILD)/synth.log \
		-p "read_verilog $<; synth -top $(SYNTH_TOP); check -assert; tee -o $(BUILD)/synth_$(SYNTH_TOP).txt stat"
	@cat $(BUILD)/synth_$(SYNTH_TOP).txt

$(BUILD):
	mkdir -p $@

clean:
	rm -rf $(BUILD) obj_dir
