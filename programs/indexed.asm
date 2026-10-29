; Base + offset addressing.
        LDI   r4, 0x20          ; base address
        LDI   r1, 0x55
        SIA   r1, r4, 0x03      ; MEM[0x23] = 0x55
        LIA   r2, r4, 0x03      ; r2 = 0x55
        SDA   r2, 0x15
        HALT

.expect mem 0x23 0x55
.expect mem 0x15 0x55
