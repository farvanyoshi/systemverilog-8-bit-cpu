VERILATOR ?= verilator
PYTHON    ?= python3

BUILD := build

# The package must be compiled before the modules that import it.
RTL := rtl/cpu_pkg.sv $(filter-out rtl/cpu_pkg.sv,$(sort $(wildcard rtl/*.sv)))

# Top module for `make lint`.
TOP ?= cpu_top

# Unit testbenches are tb/tb_<name>.sv with top module tb_<name>.
UNIT_TESTS := $(patsubst tb/tb_%.sv,%,$(filter-out tb/tb_cpu.sv,$(wildcard tb/tb_*.sv)))

VFLAGS  := -Wall -Wno-DECLFILENAME --timing -Irtl
TBFLAGS := $(VFLAGS) -Wno-UNUSEDPARAM -Wno-UNUSEDSIGNAL -Wno-WIDTH

.PHONY: all lint test unit $(addprefix test-,$(UNIT_TESTS)) clean

all: test

lint:
	$(VERILATOR) --lint-only $(VFLAGS) --top-module $(TOP) $(RTL)

test: unit

unit: $(addprefix test-,$(UNIT_TESTS))

# Build a unit testbench: build/tb_<name>/sim
$(BUILD)/tb_%/sim: tb/tb_%.sv $(RTL)
	$(VERILATOR) --binary $(TBFLAGS) --top-module tb_$* -Mdir $(BUILD)/tb_$* \
		-o sim $(RTL) $< > $(BUILD)/tb_$*.log 2>&1 || { cat $(BUILD)/tb_$*.log; exit 1; }

$(addprefix test-,$(UNIT_TESTS)): test-%: | $(BUILD)
	@$(MAKE) --no-print-directory $(BUILD)/tb_$*/sim
	@$(BUILD)/tb_$*/sim +verilator+quiet

$(BUILD):
	mkdir -p $@

clean:
	rm -rf $(BUILD) obj_dir
