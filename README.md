# 8-bit CPU

An 8-bit CPU with 16-bit instructions, originally built in Logisim and
reimplemented here in SystemVerilog.

The original Logisim design, notes and test programs are kept in `logisim/` as
the reference design. The SystemVerilog version fixes several bugs in it; see
the end of [docs/ISA.md](docs/ISA.md).

## Layout

| Path        | Contents                                              |
|-------------|-------------------------------------------------------|
| `logisim/`  | Original Logisim design, notes and test programs      |
| `docs/`     | ISA reference                                         |
| `rtl/`      | SystemVerilog design (`cpu_top` is the top level)     |
| `tb/`       | Unit testbenches and the program testbench `tb_cpu`   |
| `tools/`    | `asm.py`, the assembler                               |
| `programs/` | Assembly test programs with their expected results    |

## Requirements

Verilator 5, GNU Make, Python 3. GTKWave or Surfer to view waveforms.
For `make synth`: Yosys and [sv2v](https://github.com/zachjs/sv2v).

```
sudo dnf install verilator gtkwave yosys
```

## Usage

```
make test                      # all unit tests and programs
make lint                      # Verilator -Wall on the full design
make sim PROG=suite            # run programs/suite.asm and check its expectations
make sim PROG=suite TRACE=1    # ... printing each executed instruction
make wave PROG=suite           # ... and writing build/suite.fst
make sim HEX=path/to/image.hex # run a raw $readmemh image
make synth                     # sv2v + Yosys synthesis check of cpu_core
```

`make synth` synthesizes `cpu_core` to generic gates, prints the cell counts
and fails on combinational loops, multiple drivers or undriven nets. Generic
synthesis has no RAM cells, so the 256-entry return stack is built from
flip-flops and accounts for most of the count.

Programs declare their expected results with `.expect` lines, which the
testbench checks after `HALT`:

```
        LDI   r1, 0x5A
        SDA   r1, 0x11
        HALT
.expect mem 0x11 0x5A
```

To assemble by hand: `python3 tools/asm.py prog.asm -o prog.hex -e prog.exp`.
