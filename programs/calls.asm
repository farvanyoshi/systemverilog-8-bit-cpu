; Nested calls with both call forms, and a backward RCALL.
        JMP   main
back:   ADDI  r2, 1             ; reached by a backward RCALL
        RET

main:   LDI   r1, 1
        RCALL outer
        SDA   r1, 0x50          ; 1 + 2 + 4 + 0x10 = 0x17
        RCALL back
        RCALL back
        SDA   r2, 0x51          ; 2
        HALT

outer:  ADDI  r1, 2
        ACALL inner
        ADDI  r1, 0x10          ; runs after inner returns
        RET

inner:  ADDI  r1, 4
        RET

.expect mem 0x50 0x17
.expect mem 0x51 0x02
