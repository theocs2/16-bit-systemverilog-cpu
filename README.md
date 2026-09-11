# 16-Bit LC-3 Processor in SystemVerilog

A multicycle 16-bit processor with an eight-register datapath, arithmetic and logic operations, finite-state instruction control, and memory-mapped FPGA I/O, designed for use on the Spartan-7 Urbana FPGA Board.

The design connects a shared internal bus, ALU, register file, program counter, instruction register, and memory interface. Its controller sequences instruction fetch, decode, and execution, including memory wait states, conditional branches, subroutine calls, and interactive pause checkpoints.

## Architecture

- **Datapath:** 16-bit data and addresses, eight general-purpose registers, sign extension for immediate operands and offsets, and negative/zero/positive condition flags.
- **ALU:** addition, bitwise AND, bitwise NOT, and register pass-through.
- **Control:** 27 states covering fetch, decode, execution, memory access, and pause/resume sequencing.
- **Memory:** separate address and data registers, with explicit enable and write controls.
- **FPGA interface:** synchronized switches, debounced buttons, LEDs, and multiplexed seven-segment displays. The right display shows the instruction register.

## Instruction support

| Instruction | Operation |
| --- | --- |
| `ADD` | Register or signed immediate addition |
| `AND` | Register or signed immediate bitwise AND |
| `NOT` | Bitwise complement |
| `LDR` | Load using a base register plus signed offset |
| `STR` | Store using a base register plus signed offset |
| `BR` | PC-relative branch selected by condition flags |
| `JMP` / `RET` | Jump through a register; return through R7 |
| `JSR` | PC-relative subroutine call with return address in R7 |
| `PSE` | Display a 12-bit checkpoint on LEDs and wait for continue |

## Memory and I/O

| Address | Behavior |
| --- | --- |
| `0xFFFF` read | Read the 16 switch inputs |
| `0xFFFF` write | Update the left hexadecimal display register |
| Other addresses | Access memory through the I/O bridge |


## Project layout

```text
rtl/            Processor, controller, I/O, memory wrapper, and program definitions
sim/            Fetch and I/O checks, system stimulus, and behavioral memory
constraints/    FPGA pin assignments and 100 MHz clock constraint
```



| Testbench | Coverage |
| --- | --- |
| `tb_cpu_fetch.sv` | Checks PC-to-MAR transfer, PC increment, and MDR-to-IR transfer |
| `tb_program6_io.sv` | Checks boot selection, pause/resume, two switch reads, register values, display writes, and loop execution |
| `tb_processor_system.sv` | Drives the board wrapper through the bubble-sort menu; stimulus only, without a sorting-result assertion |

## Example programs

Instruction-encoding helpers and the initial memory image live in [`rtl/types.sv`](rtl/types.sv). The boot sequence clears R0, reads the switches into R1, and jumps to the selected start address.

| Start address (decimal) | Program |
| --- | --- |
| 3 | Continuous switch-to-display loop |
| 6 | Switch-to-display loop with pause checkpoints |
| 11 | Self-modifying checkpoint demonstration |
| 20 | XOR composed from AND and NOT |
| 42 | Subroutine return / jump demonstration |
| 49 | Multiplication routine |
| 90 | Interactive bubble sort |
| 156 | Automatic counter |

For the pause-based I/O example, select `6` on the switches, pulse run, then change the switch value and press/release continue at each checkpoint.
