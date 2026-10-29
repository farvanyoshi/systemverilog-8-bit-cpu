; Logic operations.
        LDI   r1, 0x3C          ; 00111100
        LDI   r2, 0x0F          ; 00001111
        AND   r3, r1, r2        ; 00001100
        OR    r3, r3, r2        ; 00001111
        XOR   r3, r3, r1        ; 00110011
        NOT   r3, r3            ; 11001100
        SDA   r3, 0x13
        HALT

.expect mem 0x13 0xCC
