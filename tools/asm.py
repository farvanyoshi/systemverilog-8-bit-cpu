#!/usr/bin/env python3
"""Assembler for the 8-bit CPU (see docs/ISA.md).

Syntax, one statement per line, comments start with ';':

    label:                    define a label (may share a line with an instruction)
    ADD   r3, r1, r2          mnemonics and registers are case-insensitive
    LDI   r1, 0x14            numbers: decimal, 0x hex, 0b binary, optional '-'
    BRZ   done                branch targets: a label, or a numeric offset
    .org  0x40                continue assembling at this address
    .word 0xF800              emit a raw 16-bit word
    .expect mem 0x10 0x33     expectation checked by tb_cpu after HALT
    .expect reg r1 0x5A

Writes a $readmemh image (-o) and, if requested, the expectations (-e).
"""

import argparse
import re
import sys

OPCODES = {
    "ADD": 0b00000, "ADC": 0b00001, "SUB": 0b00010, "SBC": 0b00011,
    "AND": 0b00100, "OR": 0b00101, "XOR": 0b00110, "NOT": 0b00111,
    "SHL": 0b01000, "SHR": 0b01001, "ASR": 0b01010, "ROL": 0b01011,
    "ROR": 0b01100, "ADDI": 0b01101, "SUBI": 0b01110, "LDI": 0b01111,
    "LDA": 0b10000, "SDA": 0b10001, "LIA": 0b10010, "SIA": 0b10011,
    "BRZ": 0b10100, "BRN": 0b10101, "BRV": 0b10110, "ACALL": 0b10111,
    "JMP": 0b11000, "RCALL": 0b11001, "PUSH": 0b11010, "POP": 0b11011,
    "RET": 0b11100, "NOP": 0b11101, "RESET": 0b11110, "HALT": 0b11111,
}

# Operand formats.
FORMATS = {
    **{m: "rrr" for m in ("ADD", "ADC", "SUB", "SBC", "AND", "OR", "XOR",
                          "SHL", "SHR", "ASR", "ROL", "ROR")},
    "NOT": "rr",
    **{m: "ri8" for m in ("ADDI", "SUBI", "LDI", "LDA", "SDA")},
    "LIA": "rri5", "SIA": "rri5",
    **{m: "rel" for m in ("BRZ", "BRN", "BRV", "RCALL")},
    "ACALL": "abs", "JMP": "abs",
    "PUSH": "r", "POP": "r",
    **{m: "" for m in ("RET", "NOP", "RESET", "HALT")},
}

ROM_WORDS = 2048
LABEL_RE = re.compile(r"^[A-Za-z_.][A-Za-z0-9_.]*$")


class AsmError(Exception):
    pass


def parse_int(text):
    try:
        return int(text, 0)
    except ValueError:
        raise AsmError(f"bad number '{text}'") from None


def parse_reg(text):
    m = re.fullmatch(r"[rRxX]([0-7])", text)
    if not m:
        raise AsmError(f"bad register '{text}'")
    return int(m.group(1))


def check_range(value, lo, hi, what):
    if not lo <= value <= hi:
        raise AsmError(f"{what} {value} out of range [{lo}, {hi}]")
    return value


def split_statement(line):
    """Return (labels, mnemonic, operands) for one source line."""
    code = line.split(";", 1)[0].strip()
    labels = []
    while ":" in code:
        name, code = code.split(":", 1)
        name, code = name.strip(), code.strip()
        if not LABEL_RE.match(name):
            raise AsmError(f"bad label '{name}'")
        labels.append(name)
    if not code:
        return labels, None, []
    parts = code.split(None, 1)
    operands = [o.strip() for o in parts[1].split(",")] if len(parts) > 1 else []
    if parts[0] == ".expect" and len(operands) == 1:
        operands = operands[0].split()
    return labels, parts[0], operands


def assemble(source):
    """Return (words, expectations); words maps address -> 16-bit value."""
    statements = []
    labels = {}
    addr = 0

    # Pass 1: addresses and labels.
    for lineno, line in enumerate(source.splitlines(), 1):
        try:
            names, mnemonic, operands = split_statement(line)
            for name in names:
                if name in labels:
                    raise AsmError(f"duplicate label '{name}'")
                labels[name] = addr
            if mnemonic is None:
                continue
            if mnemonic == ".org":
                addr = check_range(parse_int(operands[0]), 0, ROM_WORDS - 1, "address")
                continue
            statements.append((lineno, addr, mnemonic, operands))
            if mnemonic != ".expect":
                addr += 1
        except AsmError as e:
            raise AsmError(f"line {lineno}: {e}") from None

    def value(text):
        return labels[text] if text in labels else parse_int(text)

    # Pass 2: encode.
    words = {}
    expectations = []
    for lineno, addr, mnemonic, ops in statements:
        try:
            if mnemonic == ".expect":
                if len(ops) != 3 or ops[0] not in ("mem", "reg"):
                    raise AsmError(".expect takes 'mem <addr> <value>' or 'reg <rN> <value>'")
                where = parse_reg(ops[1]) if ops[0] == "reg" else check_range(value(ops[1]), 0, 255, "address")
                expectations.append((ops[0], where, check_range(value(ops[2]), 0, 255, "value")))
                continue
            if mnemonic == ".word":
                if len(ops) != 1:
                    raise AsmError(".word takes one value")
                word = check_range(value(ops[0]), 0, 0xFFFF, "word")
            else:
                word = encode(mnemonic.upper(), ops, addr, labels)
            if addr >= ROM_WORDS:
                raise AsmError("program does not fit in ROM")
            if addr in words:
                raise AsmError(f"address {addr:#x} assembled twice")
            words[addr] = word
        except AsmError as e:
            raise AsmError(f"line {lineno}: {e}") from None

    return words, expectations


def encode(mnemonic, ops, addr, labels):
    def value(text):
        return labels[text] if text in labels else parse_int(text)

    if mnemonic not in OPCODES:
        raise AsmError(f"unknown instruction '{mnemonic}'")
    fmt = FORMATS[mnemonic]
    nops = {"rrr": 3, "rr": 2, "ri8": 2, "rri5": 3, "rel": 1, "abs": 1, "r": 1, "": 0}[fmt]
    if len(ops) != nops:
        raise AsmError(f"{mnemonic} takes {nops} operand(s), got {len(ops)}")

    word = OPCODES[mnemonic] << 11
    if fmt == "rrr":
        word |= parse_reg(ops[0]) << 8 | parse_reg(ops[1]) << 5 | parse_reg(ops[2]) << 2
    elif fmt == "rr":
        word |= parse_reg(ops[0]) << 8 | parse_reg(ops[1]) << 5
    elif fmt == "ri8":
        imm = check_range(value(ops[1]), -128, 255, "imm8")
        word |= parse_reg(ops[0]) << 8 | (imm & 0xFF)
    elif fmt == "rri5":
        imm = check_range(value(ops[2]), 0, 31, "imm5")
        word |= parse_reg(ops[0]) << 8 | parse_reg(ops[1]) << 5 | imm
    elif fmt == "rel":
        # A label is converted to an offset from this instruction.
        offset = labels[ops[0]] - addr if ops[0] in labels else parse_int(ops[0])
        offset = check_range(offset, -1024, 1023, "branch offset")
        word |= offset & 0x7FF
    elif fmt == "abs":
        word |= check_range(value(ops[0]), 0, ROM_WORDS - 1, "address")
    elif fmt == "r":
        word |= parse_reg(ops[0]) << 8
    return word


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("source")
    ap.add_argument("-o", "--output", required=True, help="hex image for $readmemh")
    ap.add_argument("-e", "--expect", help="expectations file for tb_cpu")
    args = ap.parse_args(argv)

    with open(args.source) as f:
        source = f.read()
    try:
        words, expectations = assemble(source)
    except AsmError as e:
        sys.exit(f"{args.source}: {e}")

    with open(args.output, "w") as f:
        next_addr = 0
        for addr in sorted(words):
            if addr != next_addr:
                f.write(f"@{addr:03x}\n")
            f.write(f"{words[addr]:04x}\n")
            next_addr = addr + 1

    if args.expect:
        with open(args.expect, "w") as f:
            for kind, where, val in expectations:
                f.write(f"{kind} {where:02x} {val:02x}\n")


if __name__ == "__main__":
    main()
