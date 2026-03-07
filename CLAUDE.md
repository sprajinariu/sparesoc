# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OpenSoC is a RISC-V SoC built on the lowRISC **Ibex** CPU core. The top-level module (`opensoc_top`) uses an AXI4 crossbar (`axi_xbar` from PULP) to connect the Ibex CPU (instruction fetch + data port) to 1 MB SRAM, a simulation control module, and a timer.

## Build Commands

All builds use **FuseSoC** and must run under WSL/Linux (not native Windows):

```bash
# Verilator lint (the primary build target today)
make lint

# Equivalent manual command
fusesoc --cores-root=. --cores-root=hw/ip/ibex --cores-root=hw/ip/ibex/vendor/lowrisc_ip \
  --cores-root=hw/ip/common_cells --cores-root=hw/ip/pulp_axi \
  run --target=lint opensoc:soc:opensoc_top
```

After cloning, initialize submodules: `git submodule update --init --recursive`

## Architecture

```
opensoc_top (hw/rtl/opensoc_top.sv)
├── ibex_top_tracing    — Ibex RISC-V core with trace output
├── axi_from_mem ×2     — OBI-to-AXI bridges (instr port + data port)
├── axi_xbar            — AXI4 crossbar (2 masters × 3 slaves)
├── axi_to_mem ×3       — AXI-to-memory bridges (RAM, SimCtrl, Timer)
├── ram_1p              — 1 MB single-port SRAM
├── simulator_ctrl      — ASCII output and simulation halt (0x20000)
└── timer               — Timer with interrupt (0x30000)
```

Memory map: RAM at 0x100000 (1 MB), SimCtrl at 0x20000 (1 kB), Timer at 0x30000 (1 kB). Boot address is 0x100000+0x80.

## Repository Structure

- `hw/rtl/` — OpenSoC RTL (our code)
- `hw/opensoc_top.core` — FuseSoC core file defining dependencies and build targets
- `hw/lint/` — Verilator waiver files
- `hw/ip/ibex/` — Ibex submodule (CPU core + shared sim RTL like bus, ram, timer)
- `hw/ip/pulp_axi/` — PULP AXI submodule (crossbar, bridges)
- `hw/ip/common_cells/` — PULP common_cells submodule (required by pulp_axi)
- `hw/ip/pulp_obi/` — PULP OBI submodule (for future use)
- `dv/` — Design verification (empty, future)
- `sw/` — Software (empty, future)

## FuseSoC Core Dependencies

The core `opensoc:soc:opensoc_top` depends on:
- `lowrisc:ibex:ibex_top_tracing` — Ibex CPU with tracing
- `lowrisc:ibex:sim_shared` — Shared simulation RTL (bus, ram_1p, ram_2p, simulator_ctrl, timer)
- `pulp-platform.org::axi` — AXI4 crossbar and protocol bridges

Five `--cores-root` paths are needed: repo root, `hw/ip/ibex`, `hw/ip/ibex/vendor/lowrisc_ip`, `hw/ip/common_cells`, and `hw/ip/pulp_axi`.

## Key Ibex Parameters

Configurable via FuseSoC `vlogdefine` (command-line `+define+`): RV32M, RV32B, RV32ZC, RegFile. Other parameters (SecureIbex, PMPEnable, ICache, etc.) are set as module-level parameters in `opensoc_top.sv` and use their defaults during lint.

## AXI Configuration

- AXI data width: 32 bits, address width: 32 bits
- Slave-port ID width: 1 bit (from `axi_from_mem`)
- Master-port ID width: 2 bits (xbar prepends $clog2(2) = 1 bit)
- User width: 1 bit
- `MaxRequests = 2` on both bridges; `MaxMstTrans = 4`, `MaxSlvTrans = 4` on xbar
- ATOPs disabled; NO_LATENCY mode (no pipeline stages)
