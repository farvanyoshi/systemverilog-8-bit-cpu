; Shifts and rotates. Shift amounts come from the low 3 bits of rs2.
        LDI   r1, 0x81          ; 10000001
        LDI   r4, 0x02
        SHL   r2, r1, r4        ; 00000100
        ASR   r3, r1, r4        ; 11100000
        SHR   r4, r4, r1        ; 0x02 >> 1 = 00000001
        ROL   r3, r1, r4        ; 00000011
        ROR   r3, r3, r4        ; back to 10000001
        SDA   r3, 0x14
        HALT

.expect mem 0x14 0x81
.expect reg r2 0x04
.expect reg r4 0x01
