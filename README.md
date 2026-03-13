# OpenSoC

A RISC-V System-on-Chip built on the lowRISC [Ibex](https://github.com/lowRISC/ibex) CPU core, using an AXI4 crossbar from [PULP Platform](https://github.com/pulp-platform/axi) to connect the CPU to memory and peripherals.

## Architecture

```
opensoc_top (hw/rtl/opensoc_top.sv)
├── ibex_top_tracing    — Ibex RISC-V core with trace output
├── axi_from_mem ×2     — OBI-to-AXI bridges (instr port + data port)
├── axi_xbar            — AXI4 crossbar (2 masters × 6 slaves)
├── axi_to_mem ×6       — AXI-to-memory bridges
├── ram_1p              — 1 MB single-port SRAM
├── simulator_ctrl      — ASCII output and simulation halt
├── timer               — Timer with interrupt
├── uart                — UART with TX/RX FIFOs
├── gpio                — 32-bit GPIO with IRQ support
└── i2c_controller      — I2C master controller
```

### Memory Map

| Peripheral     | Base Address | Size  |
|----------------|--------------|-------|
| Simulator Ctrl | `0x20000`    | 1 kB  |
| Timer          | `0x30000`    | 1 kB  |
| UART           | `0x40000`    | 1 kB  |
| GPIO           | `0x50000`    | 1 kB  |
| I2C            | `0x60000`    | 1 kB  |
| RAM            | `0x100000`   | 1 MB  |

Boot address: `0x100080` (RAM base + 0x80).

## Getting Started

### Installing Ubuntu via WSL (Windows only)

All builds require a Linux environment. On Windows, use **WSL (Windows Subsystem for Linux)** to run Ubuntu:

1. Open **PowerShell as Administrator** and run:
   ```powershell
   wsl --install
   ```
   This installs WSL 2 and Ubuntu by default. Restart your PC when prompted.

2. After reboot, Ubuntu will launch automatically to finish setup. Create a Unix username and password when asked.

3. To verify the installation, open PowerShell and run:
   ```powershell
   wsl -l -v
   ```
   You should see Ubuntu listed with VERSION 2.

4. Launch Ubuntu from the Start menu, or type `wsl` in PowerShell/Terminal.

5. Update packages inside Ubuntu:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

> **Tip:** To install a specific Ubuntu version, run `wsl --install -d Ubuntu-24.04`.
> Run `wsl --list --online` to see all available distributions.

All build commands below should be run inside the WSL/Ubuntu terminal.

### Prerequisites

- **WSL / Linux** — builds do not run under native Windows.
- **[Verilator](https://www.veripool.org/verilator/)** (≥ 4.210) — for linting and simulation.
  Linux package managers often ship an old version; building from source is
  recommended (see [full install guide](https://verilator.org/guide/latest/install.html)):
  ```bash
  sudo apt-get install git help2man perl python3 make autoconf g++ flex bison ccache
  sudo apt-get install libgoogle-perftools-dev numactl perl-doc
  sudo apt-get install libfl2 libfl-dev        # Ubuntu only (ignore errors)
  sudo apt-get install zlib1g zlib1g-dev       # Ubuntu only (ignore errors)
  git clone https://github.com/verilator/verilator.git
  cd verilator
  git checkout v5.020   # or latest stable tag
  autoconf
  ./configure
  make -j $(nproc)
  sudo make install
  ```
- **FuseSoC and Python dependencies** — install with:
  ```bash
  pip3 install fusesoc
  pip3 install -U -r hw/ip/ibex/python-requirements.txt
  ```
- **RISC-V GCC toolchain** — lowRISC provides pre-built toolchains at
  <https://github.com/lowRISC/lowrisc-toolchains/releases>.
  The compiler prefix should be `riscv32-unknown-elf-`.
- **libelf** — on Debian/Ubuntu: `sudo apt-get install libelf-dev`.
- **GTKWave** (optional, for waveform viewing) — on Debian/Ubuntu: `sudo apt-get install gtkwave`.
  Requires WSLg (WSL2 on Windows 10 21H2+) or an X server (e.g. VcXsrv) for GUI display.
- **srecord** (optional, for vmem files) — on Debian/Ubuntu: `sudo apt-get install srecord`.

### Clone and initialize

```bash
git clone https://github.com/vladdum/opensoc.git
cd opensoc
git submodule update --init --recursive
```

## Build Commands

Run `make help` to list all targets:

```
make lint            - Run Verilator lint
make sim             - Build Verilator simulator
make sw-hello        - Build hello_test SW binary
make run-hello       - Build and run hello_test on simulator
make sw-uart         - Build uart_test SW binary
make run-uart        - Build and run uart_test on simulator
make sw-gpio         - Build gpio_test SW binary
make run-gpio        - Build and run gpio_test on simulator
make sw-i2c          - Build i2c_test SW binary
make run-i2c         - Build and run i2c_test on simulator
make sim-dual-uart   - Build dual-UART Verilator simulator
make sw-uart-send    - Build uart_send SW binary
make sw-uart-recv    - Build uart_recv SW binary
make run-dual-uart   - Build and run dual-UART test
make clean           - Remove build directory

Options:
  TRACE=1              - Enable FST waveform dump (e.g. make run-hello TRACE=1)
  WAVES=1              - Enable trace + open GTKWave after sim (e.g. make run-dual-uart WAVES=1)
```

### Waveform Viewing

Install [GTKWave](http://gtkwave.sourceforge.net/) (`sudo apt install gtkwave` on Ubuntu/WSL).

Use `WAVES=1` to automatically open GTKWave with a saved signal view after simulation:

```bash
make run-dual-uart WAVES=1
```

Or use `TRACE=1` to generate the trace file and open it manually:

```bash
make run-hello TRACE=1
gtkwave build/opensoc_soc_opensoc_top_0/sim-verilator/sim.fst
```

Saved waveform views (`.gtkw` files) are stored in `dv/verilator/`.

## Repository Structure

```
hw/rtl/              — OpenSoC RTL (project source)
hw/opensoc_top.core  — FuseSoC core file (dependencies & build targets)
hw/lint/             — Verilator waiver files
hw/ip/ibex/          — Ibex submodule (CPU core + shared sim RTL)
hw/ip/pulp_axi/      — PULP AXI submodule (crossbar, bridges)
hw/ip/common_cells/  — PULP common_cells submodule (required by pulp_axi)
hw/ip/pulp_obi/      — PULP OBI submodule (for future use)
dv/verilator/        — Verilator simulation testbench
sw/tests/            — Test software (hello, UART, GPIO, I2C, dual-UART)
```

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.
