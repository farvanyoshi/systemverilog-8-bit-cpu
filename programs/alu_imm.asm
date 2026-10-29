; Register and immediate arithmetic.
        LDI   r1, 0x14          ; r1 = 20
        LDI   r2, 0x06          ; r2 = 6
        ADD   r3, r1, r2        ; r3 = 26
        SUB   r3, r3, r2        ; r3 = 20
        ADDI  r3, 0x05          ; r3 = 25
        SUBI  r3, 0x01          ; r3 = 24
        SDA   r3, 0x12
        HALT

.expect mem 0x12 0x18
