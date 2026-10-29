; PUSH/POP round trip through the data stack.
        LDI   r5, 0xAA
        PUSH  r5                ; MEM[0xFF] = 0xAA
        LDI   r5, 0x00
        POP   r5                ; r5 = 0xAA again
        SDA   r5, 0x16
        HALT

.expect mem 0xFF 0xAA
.expect mem 0x16 0xAA
