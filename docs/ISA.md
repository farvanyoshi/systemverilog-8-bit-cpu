# ISA

8-bit data, 16-bit instructions, 11-bit word-addressed program counter.

## State

| State          | Width | Notes                                              |
|----------------|-------|----------------------------------------------------|
| `r0`–`r7`      | 8     | `r0` always reads 0; writes to it are ignored      |
| `pc`           | 11    | word address into instruction ROM (2048 × 16)      |
| `sp`           | 8     | data stack pointer, resets to `0x00`               |
| flags          | 4     | `{V, N, Z, C}`, `C` is bit 0                       |
| return stack   | 256 × 11 | hardware stack used by calls and `RET`          |
| data memory    | 256 × 8  | shared by loads, stores and the data stack      |

## Instruction formats

```
        15   11 10  8 7   5 4   2 1 0
R       opcode   rd   rs1   rs2   00     register ALU ops
I       opcode   rd   imm8 ...........   ADDI SUBI LDI LDA SDA
M       opcode   rd   rs1   imm5 ......  LIA SIA
S       opcode   rd   00000000           PUSH POP
J       opcode   imm11 / rel11 .......   BRZ BRN BRV ACALL JMP RCALL
N       opcode   00000000000             RET NOP RESET HALT
```

`rel11` is a signed (two's complement) offset relative to the address of the
branch instruction itself. `imm11` is an absolute address. `imm5` is
zero-extended.

## Instructions

| Opcode  | Mnemonic | Operands         | Operation                                   | Flags   |
|---------|----------|------------------|---------------------------------------------|---------|
| `00000` | ADD      | rd, rs1, rs2     | rd = rs1 + rs2                              | V N Z C |
| `00001` | ADC      | rd, rs1, rs2     | rd = rs1 + rs2 + C                          | V N Z C |
| `00010` | SUB      | rd, rs1, rs2     | rd = rs1 - rs2                              | V N Z C |
| `00011` | SBC      | rd, rs1, rs2     | rd = rs1 - rs2 - C                          | V N Z C |
| `00100` | AND      | rd, rs1, rs2     | rd = rs1 & rs2                              | N Z, V=0 |
| `00101` | OR       | rd, rs1, rs2     | rd = rs1 \| rs2                             | N Z, V=0 |
| `00110` | XOR      | rd, rs1, rs2     | rd = rs1 ^ rs2                              | N Z, V=0 |
| `00111` | NOT      | rd, rs1          | rd = ~rs1                                   | N Z, V=0 |
| `01000` | SHL      | rd, rs1, rs2     | rd = rs1 << rs2[2:0]                        | N Z, V=0 |
| `01001` | SHR      | rd, rs1, rs2     | rd = rs1 >> rs2[2:0] (logical)              | N Z, V=0 |
| `01010` | ASR      | rd, rs1, rs2     | rd = rs1 >>> rs2[2:0] (arithmetic)          | N Z, V=0 |
| `01011` | ROL      | rd, rs1, rs2     | rd = rotate left rs1 by rs2[2:0]            | N Z, V=0 |
| `01100` | ROR      | rd, rs1, rs2     | rd = rotate right rs1 by rs2[2:0]           | N Z, V=0 |
| `01101` | ADDI     | rd, imm8         | rd = rd + imm8                              | V N Z C |
| `01110` | SUBI     | rd, imm8         | rd = rd - imm8                              | V N Z C |
| `01111` | LDI      | rd, imm8         | rd = imm8                                   | –       |
| `10000` | LDA      | rd, addr8        | rd = MEM[addr8]                             | –       |
| `10001` | SDA      | rs, addr8        | MEM[addr8] = rs (rs in the rd field)        | –       |
| `10010` | LIA      | rd, rbase, off5  | rd = MEM[rbase + off5]                      | –       |
| `10011` | SIA      | rs, rbase, off5  | MEM[rbase + off5] = rs (rs in the rd field) | –       |
| `10100` | BRZ      | rel11            | if Z: pc = here + rel11                     | –       |
| `10101` | BRN      | rel11            | if N: pc = here + rel11                     | –       |
| `10110` | BRV      | rel11            | if V: pc = here + rel11                     | –       |
| `10111` | ACALL    | imm11            | push here + 1; pc = imm11                   | –       |
| `11000` | JMP      | imm11            | pc = imm11                                  | –       |
| `11001` | RCALL    | rel11            | push here + 1; pc = here + rel11            | –       |
| `11010` | PUSH     | rs               | sp = sp - 1; MEM[sp] = rs                   | –       |
| `11011` | POP      | rd               | rd = MEM[sp]; sp = sp + 1                   | –       |
| `11100` | RET      |                  | pc = pop return stack                       | –       |
| `11101` | NOP      |                  | –                                           | –       |
| `11110` | RESET    |                  | clear pc, registers, sp, flags, return stack | –      |
| `11111` | HALT     |                  | stop the processor                          | –       |

`here` is the address of the instruction being executed. Arithmetic on
addresses wraps (11 bits for `pc`, 8 bits for data addresses and `sp`).

### Flags

* Flags are written only by the ALU instructions (`00000`–`01110`). Loads,
  stores, branches and the rest leave them unchanged, so a branch tests the
  most recent ALU result.
* `Z` = result is zero, `N` = bit 7 of the result.
* `C` is the carry out for additions and the **borrow** for subtractions
  (set when the unsigned subtraction wraps). Logic, shift and rotate
  instructions leave `C` unchanged.
* `V` is signed overflow for additions and subtractions, and is cleared by
  logic, shift and rotate instructions.

### Data stack

The stack is full-descending: `sp` points at the last pushed byte. With the
reset value of `0x00`, the first `PUSH` writes `MEM[0xFF]`.

## Timing

The core has two stages. Each clock edge loads `ROM[pc]` into the
instruction register while the previous instruction executes. Every
instruction takes one cycle. A taken branch, jump, call or return replaces
the instruction already fetched behind it with a `NOP`, costing one extra
cycle. Not-taken branches cost nothing.

## Changes from the Logisim design

* Stores (`SDA`, `SIA`, `PUSH`) take their data from the register in the `rd`
  field. Logisim stored `rs1`, which overlapped the address immediate.
* `ADDI`/`SUBI` read `rd`. Logisim read `rs1`, which was part of `imm8`.
* Branch offsets are relative to the branch instruction and sign-extended.
* `RCALL` jumps. In Logisim it only pushed a return address.
* Calls save `here + 1`. Logisim saved `here + 2`, skipping an instruction.
* The data stack pointer moves on every `PUSH`/`POP`. Logisim gated it with
  an AND of `imm8`, so it never moved. `PUSH` pre-decrements so that `POP`
  reads the same location.
* The pipeline bubble is a real `NOP` (`0xE800`), not `0x0000` (`ADD r0`).
* Flags only change on ALU instructions.
* `HALT` is `0xF800`. The old test ROM used `0xF100`, which decodes as `RESET`.
