
TRAP_CODE_CHECK_INPUT   EQU     19


; Reads states of a given array of keys and stores the key state into an array
; arg1 = pointer to array of keys
; arg2 = number of long words in the array of keys
; arg3 = pointer to the location to store key states
; arg4 = pointer to the location of key press masks
ReadKeyStates:
    ; save registers in stack
    movem.l d0-d2/a0-a2, -(sp)
    add.l   #28, sp

    ; read arguments from stack
    move.l  (sp), a0
    move.l  4(sp), d2
    move.l  8(sp), a1
    move.l  12(sp), a2

    ; set loop counter
    sub.w   #1, d2
.keyRead:
    ; read key states
    move.l  #TRAP_CODE_CHECK_INPUT, d0
    move.l  (a0)+, d1
    trap    #15

    ; update mask and key state variable
    move.l  (a1), (a2)+
    move.l  d1, (a1)+
    dbf     d2, .keyRead

.return:
    sub.l   #28, sp
    movem.l (sp)+, d0-d2/a0-a2
    rts

