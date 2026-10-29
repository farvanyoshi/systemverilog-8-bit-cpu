; The full test program from "my isa test program.txt", in its original order,
; with the encodings corrected for the fixed ISA.

; Subroutine test
        LDI   r1, 0x11
        ACALL sub
        SDA   r1, 0x10
        JMP   branch_test
sub:    ADDI  r1, 0x22          ; r1 = 0x33
        RET

; Flag/branch test
branch_test:
        SUB   r6, r1, r1        ; r6 = 0, Z set
        BRZ   alu_test
        LDI   r7, 0xEE          ; fail code
        SDA   r7, 0x11
        HALT

; Immediate + register ALU test
alu_test:
        LDI   r1, 0x14
        LDI   r2, 0x06
        ADD   r3, r1, r2
        SUB   r3, r3, r2
        ADDI  r3, 0x05
        SUBI  r3, 0x01
        SDA   r3, 0x12          ; 24

; Logic test
        LDI   r1, 0x3C
        LDI   r2, 0x0F
        AND   r3, r1, r2
        OR    r3, r3, r2
        XOR   r3, r3, r1
        NOT   r3, r3
        SDA   r3, 0x13          ; 0xCC

; Shift/rotate test
        LDI   r1, 0x81
        LDI   r4, 0x02
        SHL   r2, r1, r4
        ASR   r3, r1, r4
        SHR   r4, r4, r1
        ROL   r3, r1, r4
        ROR   r3, r3, r4
        SDA   r3, 0x14          ; 0x81

; Indexed addressing test
        LDI   r4, 0x20
        LDI   r1, 0x55
        SIA   r1, r4, 0x03
        LIA   r2, r4, 0x03
        SDA   r2, 0x15          ; 0x55

; Stack test
        LDI   r5, 0xAA
        PUSH  r5
        LDI   r5, 0x00
        POP   r5
        SDA   r5, 0x16          ; 0xAA

; Final signature
        LDI   r1, 0x5A
        SDA   r1, 0x11
        HALT

.expect mem 0x10 0x33
.expect mem 0x11 0x5A
.expect mem 0x12 0x18
.expect mem 0x13 0xCC
.expect mem 0x14 0x81
.expect mem 0x15 0x55
.expect mem 0x16 0xAA
