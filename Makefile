# Copyright OpenSoC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

FUSESOC = fusesoc
CORES_ROOT = --cores-root=. --cores-root=hw/ip/ibex --cores-root=hw/ip/ibex/vendor/lowrisc_ip \
             --cores-root=hw/ip/common_cells --cores-root=hw/ip/pulp_axi

.PHONY: help
help:
	@echo "OpenSoC build targets:"
	@echo "  make lint       - Run Verilator lint"
	@echo "  make sim        - Build Verilator simulator"
	@echo "  make sw-hello   - Build hello_test SW binary"
	@echo "  make run-hello  - Build and run hello_test on simulator"
	@echo "  make clean      - Remove build directory"

.PHONY: clean
clean:
	rm -rf build

.PHONY: lint
lint:
	$(FUSESOC) $(CORES_ROOT) run --target=lint opensoc:soc:opensoc_top

.PHONY: sim
sim:
	$(FUSESOC) $(CORES_ROOT) run --target=sim --setup --build opensoc:soc:opensoc_top

SW_DIR = hw/ip/ibex/examples/sw/simple_system
SW_ARCH = rv32imc_zicsr_zifencei
SIM_BIN = build/opensoc_soc_opensoc_top_0/sim-verilator/Vopensoc_top

.PHONY: sw-hello
sw-hello:
	$(MAKE) -C $(SW_DIR)/hello_test ARCH=$(SW_ARCH)

.PHONY: run-hello
run-hello: sw-hello
	cd build/opensoc_soc_opensoc_top_0/sim-verilator && \
	  ./Vopensoc_top --meminit=ram,$(CURDIR)/$(SW_DIR)/hello_test/hello_test.elf
	@echo "--- Program output ---"
	@cat build/opensoc_soc_opensoc_top_0/sim-verilator/opensoc_top.log
