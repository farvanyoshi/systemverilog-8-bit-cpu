; Call a subroutine and store its result after returning.
        LDI   r1, 0x11
        ACALL sub
        SDA   r1, 0x10          ; runs after RET
        HALT

sub:    ADDI  r1, 0x22          ; r1 = 0x33
        RET

.expect mem 0x10 0x33
.expect reg r1 0x33
