; RESET restarts at address 0 with registers, flags and sp cleared. Memory
; survives, so the second pass sees the marker and halts.
        LDA   r1, 0x50
        ADDI  r1, 0             ; Z if this is the first pass
        BRZ   first
        PUSH  r1                ; sp was reset, so this writes MEM[0xFF] again
        HALT

first:  LDI   r1, 1
        SDA   r1, 0x50
        LDI   r7, 0x99
        PUSH  r7                ; MEM[0xFF] = 0x99, sp = 0xFF
        RESET

.expect mem 0x50 0x01
.expect mem 0xFF 0x01
.expect reg r7 0x00
