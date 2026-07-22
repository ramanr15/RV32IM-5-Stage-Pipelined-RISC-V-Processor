# 32-bit RV32IM 5-Stage Pipelined RISC-V Processor

A synthesizable 32-bit RV32IM five-stage pipelined RISC-V processor implemented in Verilog HDL, featuring data forwarding, hazard detection, branch/jump control, instruction and data memories, RV32M multiplication/division support, CSR operations, and machine-mode exception/trap handling. Designed, simulated, synthesized, and implemented in AMD/Xilinx Vivado, achieving timing closure at 90 MHz on a Xilinx 7-series FPGA target.

> **Note:** This is a full custom pipelined core, not a soft-core wrapper — every stage, hazard path, and CSR/exception mechanism is hand-designed RTL.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Pipeline Stages](#pipeline-stages)
- [Hazard Handling](#hazard-handling)
- [RV32M Extension](#rv32m-extension)
- [CSR and Exception Handling](#csr-and-exception-handling)
- [Verification](#verification)
- [Results](#results)
- [FPGA Synthesis Results](#fpga-synthesis-results)
- [Timing Results](#timing-results)
- [Project Files](#project-files)
- [How to Run](#how-to-run)
- [Technologies Used](#technologies-used)
- [Key Features](#key-features)
- [Limitations](#limitations)
- [Future Work](#future-work)
- [Author](#author)
- [License](#license)

---

## Project Overview

The processor executes 32-bit RISC-V machine instructions drawn from the RV32I base integer ISA plus the RV32M multiply/divide extension, using a classical register file of 32 general-purpose 32-bit registers:

```text
x0 (hardwired 0)  x1  x2  ...  x31
```

Instructions flow through a five-stage pipeline:

```text
IF -> ID -> EX -> MEM -> WB
```

with dedicated hazard detection, forwarding, and control-flow redirection to keep the pipeline correct under data and control hazards.

---

## Architecture

```text
                 32-bit RV32IM Processor
                          |
        +-----------------+------------------+
        |                 |                  |
      RV32I             RV32M          System / CSR
        |                 |                  |
 Arithmetic           Multiply            CSRs
 Logical              Divide              ECALL
 Branches             Remainder           Exceptions
 Loads/Stores                             MRET
        |
        +-----------------+
                          |
                   5-Stage Pipeline
                          |
          IF -> ID -> EX -> MEM -> WB
                          |
              Hazard + Forwarding
```

---

## Pipeline Stages

### 1. IF — Instruction Fetch

```text
PC -> Instruction Memory -> 32-bit instruction
```

Next PC is `PC + 4` unless overridden by a branch, jump, exception, or `MRET`.

### 2. ID — Instruction Decode

Decodes instruction type, source/destination registers, immediates, ALU operation, memory operation, branch/jump requirement, and CSR/system operation. Reads operands from the register file.

### 3. EX — Execute

Performs arithmetic, logical, shift, and comparison operations; computes memory addresses; resolves branch conditions and targets; executes RV32M operations.

### 4. MEM — Memory

`LW`-class instructions read data memory; `SW`-class instructions write data memory. Non-memory instructions pass results through unmodified.

### 5. WB — Write Back

Writes ALU results, memory-load data, CSR results, or jump return addresses back to the destination register.

### Pipeline Registers

```text
IF/ID -> ID/EX -> EX/MEM -> MEM/WB
```

```text
Cycle      IF      ID      EX      MEM      WB
------------------------------------------------
1          I1
2          I2      I1
3          I3      I2      I1
4          I4      I3      I2      I1
5          I5      I4      I3      I2      I1
```

---

## Hazard Handling

### Data Forwarding

```text
EX/MEM result -----+
                    v
                 ALU input
MEM/WB result ------+
```

Example resolved without a stall:

```text
ADD x5, x1, x2
SUB x6, x5, x3
```

### Load-Use Hazard Detection

```text
LW  x5, 0(x1)
ADD x6, x5, x2
```

```text
Load detected
      +
Next instruction depends on loaded register
      v
Hazard detected -> stall inserted -> data available -> execution continues
```

### Control-Hazard Handling

```text
Branch/jump resolved -> target determined -> PC redirected -> incorrect-path work flushed -> continue from correct target
```

---

## RV32M Extension

| Category | Instructions |
|---|---|
| Multiply | `MUL`, `MULH`, `MULHSU`, `MULHU` |
| Divide | `DIV`, `DIVU` |
| Remainder | `REM`, `REMU` |

`MULH` variants cover signed x signed, signed x unsigned, and unsigned x unsigned high-half products. Division/remainder verification includes signed and unsigned corner cases, including divide-by-zero behavior.

---

## CSR and Exception Handling

Implemented machine CSRs:

| CSR | Purpose |
|---|---|
| `mstatus` | Machine status |
| `mtvec` | Trap-handler base address |
| `mepc` | Exception program counter |
| `mcause` | Exception cause code |
| `mtval` | Trap-associated information |

### ECALL Flow

```text
Normal program -> ECALL -> exception detected
      -> mepc <- faulting PC
      -> mcause <- cause
      -> PC <- mtvec
      -> trap handler executes
```

Verified: `ECALL` at `PC = 0x0C` -> `mepc = 0x0C`, `mcause = 11`.

### Illegal-Instruction Exception

Deliberately executed instruction `FFFFFFFF` produced:

```text
mcause = 2
mepc   = address of illegal instruction
mtval  = FFFFFFFF
```

### MRET Return

```text
Exception -> trap handler -> update mepc as required -> MRET -> PC <- mepc -> resume original program
```

---

## Verification

Verified using directed RISC-V machine-code programs in Vivado simulation, covering:

- Base instruction execution — arithmetic, logical, shifts, comparisons, immediates, upper-immediates
- Load/store and data-memory access
- Pipeline register propagation and correct writeback
- Forwarding, dependency chains, load-use stalls
- Branches, jumps, PC redirection
- RV32M: multiplication, high-half multiplication, signed/unsigned division and remainder, arithmetic corner cases
- CSR reads/writes and set/clear behavior on machine CSRs
- ECALL, illegal-instruction detection, `mtvec` redirection, trap-handler execution, `MRET`, and continuation after exception

---

## Results

### Exception Flow Verification

| Event | mcause | mepc | mtval |
|---|---:|---|---|
| ECALL | 11 | 0x0C | — |
| Illegal instruction | 2 | address of `FFFFFFFF` | `FFFFFFFF` |

### Pipeline Hazard Verification

| Scenario | Handling | Result |
|---|---|---|
| Back-to-back ALU dependency | EX/MEM & MEM/WB forwarding | No stall |
| Load-use dependency | Hazard detection + stall | 1-cycle stall, correct data |
| Branch misprediction | Flush + PC redirect | Correct-path resumption |

---

## FPGA Synthesis Results

Synthesized and implemented for a Xilinx 7-series FPGA target.

| Metric | Final Result |
|---|---:|
| Target Frequency | 90 MHz |
| Slice LUTs | 1,491 |
| Slice Registers | 1,106 |
| F7 Muxes | 66 |
| Block RAM | 1 |
| Bonded I/O | 138 |
| BUFGCTRL | 1 |
| Estimated On-Chip Power | 0.236 W |

Data memory utilization specifically:

```text
DATA_MEMORY
    LUTs      = 89
    Block RAM = 1
```

---

## Timing Results

The design achieved timing closure at 90 MHz (T = 11.111 ns).

```text
Setup:  WNS = +0.974 ns, TNS = 0.000 ns, Failing endpoints = 0
Hold:   WHS = +0.122 ns, THS = 0.000 ns, Failing endpoints = 0
Pulse:  WPWS = +5.055 ns, TPWS = 0.000 ns, Failing endpoints = 0
```

All user-specified timing constraints were met.

---

## Project Files

```text
RV32IM-5-Stage-Pipelined-Processor/
|
|-- rtl/
|   |-- rv32im_core.v
|   |-- fetch_stage.v
|   |-- decode_stage.v
|   |-- execute_stage.v
|   |-- memory_stage.v
|   |-- writeback_stage.v
|   |-- hazard_unit.v
|   |-- forwarding_unit.v
|   |-- alu.v
|   |-- mul_div_unit.v
|   |-- csr_unit.v
|   |-- register_file.v
|   |-- instruction_memory.v
|   |-- data_memory.v
|
|-- simulation/
|   |-- rv32im_core_tb.v
|   |-- programs/
|       |-- ecall_test.hex
|       |-- illegal_instr_test.hex
|       |-- forwarding_test.hex
|       |-- load_use_test.hex
|
|-- constraints/
|   |-- rv32im_core.xdc
|
|-- results/
|   |-- waveform.png
|   |-- simulation_results.png
|   |-- timing_summary.png
|   |-- utilization.png
|   |-- power.png
|
|-- README.md
|-- LICENSE
|-- .gitignore
```

---

## How to Run

### Requirements

- AMD Vivado 2025.2
- XSim Simulator
- Xilinx 7-series FPGA target

### Simulation

1. Create a new RTL project in Vivado.
2. Add all files under `rtl/` as Design Sources.
3. Add `simulation/rv32im_core_tb.v` as a Simulation Source.
4. Add `constraints/rv32im_core.xdc` as a Constraint Source.
5. Set `rv32im_core_tb` as the simulation top.
6. Launch Behavioral Simulation.
7. Run:

```tcl
   run all
```

Expected result: all directed test programs (forwarding, load-use stall, branch/jump, RV32M, CSR, ECALL, illegal instruction, MRET) complete with no mismatches.

### Synthesis

1. Set `rv32im_core` as the Design Top.
2. Run Synthesis, then Implementation.
3. Check the Timing Summary, Utilization, and Power reports.

The design uses an 11.111 ns clock constraint corresponding to 90 MHz.

---

## Technologies Used

- Verilog HDL
- AMD Vivado 2025.2
- XSim
- Xilinx 7-series FPGA architecture
- 5-stage pipelined datapath design
- Data forwarding and hazard detection
- RV32M multiply/divide datapath
- CSR and machine-mode exception handling

---

## Key Features

- Full RV32I base instruction set
- RV32M multiply/divide/remainder extension
- 5-stage IF/ID/EX/MEM/WB pipeline
- Data forwarding (EX/MEM, MEM/WB)
- Load-use hazard detection and stalling
- Branch/jump resolution with pipeline flush
- Machine-mode CSR support (`mstatus`, `mtvec`, `mepc`, `mcause`, `mtval`)
- ECALL and illegal-instruction exception generation
- MRET-based trap return
- Data memory mapped to FPGA Block RAM
- Timing closure at 90 MHz

---

## Limitations

- Single-issue, in-order pipeline (no superscalar or out-of-order execution)
- No caches — direct instruction/data memory access
- No user/supervisor privilege modes (machine mode only)
- No floating-point (F/D) extension support
- Verification is directed-test based rather than randomized/formal

---

## Future Work

- Add branch prediction to reduce control-hazard penalties
- Introduce user-mode privilege and page-based memory protection
- Add instruction and data caches
- Extend to RV32IMAFD or a wider RV64 variant
- Randomized/coverage-driven verification and formal property checking
- Integration with an SoC bus (AXI-Lite/AHB-Lite) for peripheral support

---

## Author

**Raman R**

Electronics and Communication Engineering
Interests: VLSI, FPGA Design, Digital Hardware Architecture, RISC-V and Quantum-Inspired Computing

---

## License

This project is released under the MIT License.
