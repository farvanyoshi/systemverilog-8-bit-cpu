; Count from 0 to 15, storing each value to MEM[0x30 + i]. Backward BRN loop.
        LDI   r1, 0             ; i
        LDI   r2, 16            ; limit
        LDI   r4, 0x30          ; store pointer
loop:   SIA   r1, r4, 0
        ADDI  r4, 1
        ADDI  r1, 1
        SUB   r3, r1, r2        ; negative while i < 16
        BRN   loop
        HALT

.expect reg r1 0x10
.expect mem 0x30 0x00
.expect mem 0x31 0x01
.expect mem 0x32 0x02
.expect mem 0x33 0x03
.expect mem 0x34 0x04
.expect mem 0x35 0x05
.expect mem 0x36 0x06
.expect mem 0x37 0x07
.expect mem 0x38 0x08
.expect mem 0x39 0x09
.expect mem 0x3A 0x0A
.expect mem 0x3B 0x0B
.expect mem 0x3C 0x0C
.expect mem 0x3D 0x0D
.expect mem 0x3E 0x0E
.expect mem 0x3F 0x0F
.expect mem 0x40 0x00
