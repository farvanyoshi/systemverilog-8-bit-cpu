; Sum of the series 10 + 9 + ... + 1. The store between SUBI and BRZ checks
; that non-ALU instructions leave the flags alone.
        LDI   r1, 10            ; n
        LDI   r2, 0             ; sum
loop:   ADD   r2, r2, r1
        SUBI  r1, 1
        SDA   r1, 0x41          ; does not touch Z
        BRZ   done
        JMP   loop
done:   SDA   r2, 0x40
        HALT

.expect mem 0x40 0x37
.expect mem 0x41 0x00
