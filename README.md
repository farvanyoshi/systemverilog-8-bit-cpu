# 8-bit CPU

An 8-bit CPU with 16-bit instructions, originally built in Logisim and
reimplemented here in SystemVerilog.

The Logisim design (`*.circ`) and the original notes and test programs (`*.txt`,
`x86_test*`, `my_isa_test`) are kept in the repository root as the reference
design. The SystemVerilog version fixes several bugs in it; see the end of
[docs/ISA.md](docs/ISA.md).

## Layout

| Path        | Contents                                              |
|-------------|-------------------------------------------------------|
| `docs/`     | ISA reference                                         |
| `rtl/`      | SystemVerilog design (`cpu_top` is the top level)     |
| `tb/`       | Unit testbenches and the program testbench `tb_cpu`   |
| `tools/`    | `asm.py`, the assembler                               |
| `programs/` | Assembly test programs with their expected results    |

## Requirements

Verilator 5, GNU Make, Python 3. GTKWave or Surfer to view waveforms.

```
sudo dnf install verilator gtkwave
```

## Usage

```
make test                      # all unit tests and programs
make lint                      # Verilator -Wall on the full design
make sim PROG=suite            # run programs/suite.asm and check its expectations
make sim PROG=suite TRACE=1    # ... printing each executed instruction
make wave PROG=suite           # ... and writing build/suite.fst
make sim HEX=path/to/image.hex # run a raw $readmemh image
```

Programs declare their expected results with `.expect` lines, which the
testbench checks after `HALT`:

```
        LDI   r1, 0x5A
        SDA   r1, 0x11
        HALT
.expect mem 0x11 0x5A
```

To assemble by hand: `python3 tools/asm.py prog.asm -o prog.hex -e prog.exp`.
