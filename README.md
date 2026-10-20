## Single-Cycle RISC-V CPU 

A fully functional single-cycle RISC-V CPU implementing the complete **RV32I base integer ISA (37 instructions)** and the **RV32M multiply extension (4 instructions)**, written in SystemVerilog. 

**Status:** Core ISA + multiply extension complete and functionally verified. FPGA implementation is in progress. 

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Instruction Set Coverage](#instruction-set-coverage)
- [Module Breakdown](#module-breakdown)
- [Verification](#verification)
- [Repository Structure](#repository-structure)
- [Running Simulation](#running-simulation)
- [Future Goals](#future-goals)
- [References](#references)

---

## Architecture Overview

The CPU is a classic **single-cycle** architecture. Every instruction fetches, decodes, executes, accesses memory, and writes back within one clock cycle. 

```text
                ┌────────────────────┐
     ┌─────────▶│  Instruction Mem   │
     │          └─────────┬──────────┘
     │                    │ instr
     │                    ▼
┌──────┴──────┐     ┌───────────────┐      ┌─────────────────┐
│   Program   │     │ Control Unit  │◄────►│    Datapath     │
│   Counter   │     │ ┌───────────┐ │      │  ┌────────────┐ │
└──────┬──────┘     │ │ main_     │ │      │  │ Reg File   │ │
       │            │ │ decoder   │ │      │  ├────────────┤ │
       │            │ ├───────────┤ │      │  │ Imm Gen    │ │
       │            │ │ alu_      │ │      │  ├────────────┤ │
       │            │ │ decoder   │ │      │  │ ALU + Mul  │ │
       │            │ └───────────┘ │      │  ├────────────┤ │
       │            └───────────────┘      │  │ Branch Cmp │ │
       │                                   │  └─────┬──────┘ │
       │                                   └────────┼────────┘
       │                                            │ addr/data
       │                                            ▼
       │                                   ┌──────────────────┐
       └───────────────────────────────────│   Data Memory    │
         PC+4 / PC+imm / jalr target       │  (byte-enabled)  │
                                           └──────────────────┘
```

### Control Flow Philosophy
The control unit produces *every* steering signal the datapath needs (`alu_src`, `res_src`, `imm_src`, `pc_src`, `reg_wr`, `mem_wr`, `alu_control`) purely combinationally from the instruction fields. The datapath itself contains no instruction-specific logic—it is a fixed set of multiplexers and functional units wired together. Every one of the supported instructions is simply a different combination of control signals through that same hardware. This design choice ensures that extending the ISA (adding branches, jumps, multiply, or sub-word memory operations) requires minimal datapath changes—primarily new decoder cases.

---

## Instruction Set Coverage

### RV32I Base Integer ISA — 37 Instructions

| Format | Opcode | Instructions | Writeback Source |
| :--- | :--- | :--- | :--- |
| **R-type** | `0110011` | `add`, `sub`, `sll`, `slt`, `sltu`, `xor`, `srl`, `sra`, `or`, `and` | ALU result |
| **I-type (ALU)** | `0010011` | `addi`, `slti`, `sltiu`, `xori`, `ori`, `andi`, `slli`, `srli`, `srai` | ALU result |
| **I-type (Load)** | `0000011` | `lb`, `lh`, `lw`, `lbu`, `lhu` | Memory (sign/zero-extended) |
| **S-type** | `0100011` | `sb`, `sh`, `sw` | — (Writes to memory) |
| **B-type** | `1100011` | `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu` | — (Updates PC) |
| **J-type** | `1101111` | `jal` | PC + 4 |
| **I-type (Jump)** | `1100111` | `jalr` | PC + 4 |
| **U-type** | `0110311` (0x37) | `lui` | Immediate |
| **U-type** | `0010311` (0x17) | `auipc` | PC + immediate |

### RV32M Multiply Extension

| Opcode | funct7 | Instructions Implemented |
| :--- | :--- | :--- |
| `0110011` | `0000001` | `mul`, `mulh`, `mulhsu`, `mulhu` |

*Note: Division and remainder instructions (`div`, `divu`, `rem`, `remu`) are planned for the future. The current multiplier is combinational (single-cycle `*` operator), which is functionally correct but adds timing pressure to the critical path.*

---

## Module Breakdown

- **`rtl/alu_ops_pkg.sv`**: SystemVerilog package defining shared ALU opcode constants (`ALU_ADD`, `ALU_SUB`, ..., `ALU_MUL`, `ALU_MULH`, etc.).
- **`rtl/control_unit.sv`**: Central control logic module containing:
  - `main_decoder`: Maps opcodes to control flags (`reg_wr`, `alu_src`, `mem_wr`, `res_src`, `branch`, `jump`, `jalr`, `imm_src`, `ALU_op`).
  - `alu_decoder`: Combines `ALU_op`, `funct3`, `funct7`, and instruction bits to generate `alu_control[3:0]`, including detection of the M-extension (`funct7 == 0000001`).
- **`rtl/datapath.sv`**: Module that wires everything together encompassing:
  - `PC.sv`: Program counter register with synchronous reset.
  - `reg_file.sv`: $32 \times 32$-bit register file with `x0` hardwired to zero, asynchronous read, and synchronous write ports.
  - `imm_gen.sv`: Immediate extraction and sign extension for all 5 RISC-V formats (I, S, B, J, U).
  - `alu.sv`: 32-bit arithmetic logic unit supporting 10 R-type operations and 4 multiply operations, utilizing 64-bit intermediate products for upper-half multiplication.
  - *Branch Comparator (Inline)*: `funct3`-driven comparator evaluating equality (`beq`/`bne`), signed comparison (`blt`/`bge`), and unsigned comparison (`bltu`/`bgeu`).
  - *Load-Extend Unit (Inline)*: Byte/half-word selection with sign or zero extension based on `funct3` and low address bits.
  - *Store-Align Unit (Inline)*: Byte replication and one-hot byte-enable mask generation for `sb`, `sh`, and `sw`.
- **`rtl/instr_memory.sv`**: Synchronous instruction ROM, word-addressed via `addr[31:2]`, initialized via `$readmemh`.
- **`rtl/data_mem.sv`**: Data RAM featuring byte-enabled write ports 
- **`rtl/cpu_top.sv`**: Top-level integration module instantiating and wiring the control unit, datapath, instruction memory, and data memory.


## Verification

Verification relies on **directed, self-checking testbenches** incorporating **SystemVerilog Assertions (SVA)**. Expected reference values are derived directly from the RISC-V specification or independent calculations rather than duplicated DUT logic.


### Integration Test
- Executes the Harris & Harris RV32I self-test program, verifying end-to-end execution. Successful completion writes the validation value **`0x19` (25)** to data memory address `100`.

---

## Repository Structure

```text
.
├── rtl/
│   ├── alu_ops_pkg.sv
│   ├── control_unit.sv       (main_decoder + alu_decoder)
│   ├── alu.sv
│   ├── imm_gen.sv
│   ├── PC.sv
│   ├── reg_file.sv
│   ├── datapath.sv
│   ├── instr_memory.sv
│   ├── data_mem.sv
│   └── cpu_top.sv
├── tb/
│   ├── tb_alu.sv
│   ├── tb_imm_gen.sv
│   ├── tb_reg_file.sv
│   ├── tb_branch.sv
│   ├── tb_load_store.sv
│   └── tb_cpu_top.sv
├── programs/
│   └── program.txt           (H&H RV32I self-test, hex machine code)
├── docs/
│   └── datapath_diagram.png
└── README.md
```

---

## Running Simulation

Compile order is critical; package files must be compiled prior to any modules that import them:

```bash
vlog rtl/alu_ops_pkg.sv \
     rtl/control_unit.sv \
     rtl/alu.sv \
     rtl/imm_gen.sv \
     rtl/PC.sv \
     rtl/reg_file.sv \
     rtl/datapath.sv \
     rtl/instr_memory.sv \
     rtl/data_mem.sv \
     rtl/cpu_top.sv \
     tb/tb_cpu_top.sv

vsim -c tb_cpu_top -do "run -all; quit"
```

The instruction memory (`instr_memory.sv`) loads machine code from `programs/program.txt` via `$readmemh`. Memory is word-addressed (`addr[31:2]`) to match the byte-addressed RISC-V program counter incrementing by 4 per instruction.

---


## Future Goals (Graphing Calculator SoC)
- [ ] Multi-cycle divider unit (`div`, `divu`, `rem`, `remu`)
- [ ] Memory-Mapped I/O (MMIO) peripheral integration via a Wishbone bus protocol
- [ ] SPI peripheral driving an external LCD display and keypad
- [ ] MMIO address map integrating CPU, keypad, and display over Wishbone
- [ ] 1200+ line RISC-V assembly application running from on-chip RAM
- [ ] FPGA synthesis & timing analysis (LUT/cell utilization, flip-flops, $F_{\max}$)
- [ ] ASIC tape-out via the Caravel SoC harness (efabless shuttle) — target $\approx 13,000$ standard cells

---

## References

- Harris & Harris, *Digital Design and Computer Architecture: RISC-V Edition* 
- Patterson & Hennessy, *Computer Organization and Design: RISC-V Edition*
- [RISC-V Unprivileged ISA Specification](https://riscv.org/specifications/)
- [RARS — RISC-V Assembler & Simulator](https://github.com/TheThirdOne/rars)
- [Ripes — Visual RISC-V Pipeline Simulator](https://github.com/mortbopet/Ripes)
- [Caravel — efabless open-source SoC harness](https://github.com/efabless/caravel)