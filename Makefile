VERILATOR ?= verilator
RTL := $(filter-out rtl/types.sv,$(wildcard rtl/*.sv))
SOURCES := $(RTL) sim/test_memory.sv
FLAGS := --binary --timing -Wno-fatal -Irtl

.PHONY: test fetch io system clean

test: fetch io

fetch: build/fetch/Vtb_cpu_fetch
	cd build/fetch && ./Vtb_cpu_fetch

io: build/io/Vtb_program6_io
	cd build/io && ./Vtb_program6_io

system: build/system/Vtestbench
	cd build/system && ./Vtestbench

build/fetch/Vtb_cpu_fetch: $(SOURCES) rtl/types.sv sim/tb_cpu_fetch.sv
	mkdir -p build/fetch
	$(VERILATOR) $(FLAGS) --Mdir build/fetch --top-module tb_cpu_fetch $(SOURCES) sim/tb_cpu_fetch.sv

build/io/Vtb_program6_io: $(SOURCES) rtl/types.sv sim/tb_program6_io.sv
	mkdir -p build/io
	$(VERILATOR) $(FLAGS) --Mdir build/io --top-module tb_program6_io $(SOURCES) sim/tb_program6_io.sv

build/system/Vtestbench: $(SOURCES) rtl/types.sv sim/tb_processor_system.sv
	mkdir -p build/system
	$(VERILATOR) $(FLAGS) --Mdir build/system --top-module testbench $(SOURCES) sim/tb_processor_system.sv

clean:
	rm -rf build
