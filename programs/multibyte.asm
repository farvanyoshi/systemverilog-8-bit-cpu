; 16-bit add/subtract with ADC/SBC, and signed overflow with BRV.
        LDI   r1, 0xFF          ; r2:r1 = 0x12FF
        LDI   r2, 0x12
        LDI   r3, 0x01          ; r4:r3 = 0x0101
        LDI   r4, 0x01
        ADD   r5, r1, r3        ; low byte, carry out
        ADC   r6, r2, r4        ; r6:r5 = 0x1400
        SDA   r5, 0x60
        SDA   r6, 0x61

        LDI   r4, 0x00          ; r4:r3 = 0x0001
        SUB   r1, r5, r3        ; low byte, borrow out
        AND   r7, r7, r7        ; logic ops keep C
        SBC   r2, r6, r4        ; r2:r1 = 0x13FF
        SDA   r1, 0x62
        SDA   r2, 0x63

        LDI   r1, 0x7F
        ADDI  r1, 1             ; 127 + 1 overflows
        BRV   ovf
        HALT
ovf:    LDI   r7, 1
        SDA   r7, 0x64
        HALT

.expect mem 0x60 0x00
.expect mem 0x61 0x14
.expect mem 0x62 0xFF
.expect mem 0x63 0x13
.expect mem 0x64 0x01
