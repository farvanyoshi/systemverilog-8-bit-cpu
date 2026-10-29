; A taken BRZ must skip the failure path.
        LDI   r1, 0x33
        SUB   r6, r1, r1        ; r6 = 0, Z set
        BRZ   pass
        LDI   r7, 0xEE          ; fail code
        SDA   r7, 0x11
        HALT
pass:   LDI   r1, 0x5A
        SDA   r1, 0x11
        HALT

.expect mem 0x11 0x5A
.expect reg r6 0x00
.expect reg r7 0x00
