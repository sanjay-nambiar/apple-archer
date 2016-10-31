
; I/O utilities

TRAP_CODE_CLOSE_ALL_FILES           EQU     50
TRAP_CODE_EXISTING_FILE_OPEN        EQU     51
TRAP_CODE_READ_FILE                 EQU     53
TRAP_CODE_CREATE_FILE               EQU     52
TRAP_CODE_WRITE_FILE                EQU     54
TRAP_CODE_CLOSE_FILE                EQU     56
TRAP_CODE_FILE_EXISTS               EQU     59


FILE_DOES_NOT_EXIST_ERROR           EQU     2
FILE_READ_WRITE_BUFFER_SIZE         EQU     1024



; Closes all open files. Easy68K recommends calling this at the start of a program using files
CloseAllFiles:
    movem.l d0, -(sp)
    move.l  #TRAP_CODE_CLOSE_ALL_FILES, d0
    trap    #15
    movem.l (sp)+, d0
    rts



; Reads a file and loads the bytes into memory
; arg1 = null terminated file name
; arg2 = destination memory address
; returns file size in d0.l
ReadFile:
    movem.l d1-d2/a0-a1, -(sp)
    add.l   #20, sp

    ; Check if file exists
    move.l  (sp), a1
    clr.l   d1
    move.l  #TRAP_CODE_FILE_EXISTS, d0
    trap    #15

    ; if d0.w is FILE_DOES_NOT_EXIST_ERROR, file doesn't exist
    cmp.w   #FILE_DOES_NOT_EXIST_ERROR, d0
    beq     .errorReturn

    ; open file and get file-ID in d1.l
    move.l  (sp), a1
    move.l  #TRAP_CODE_EXISTING_FILE_OPEN, d0
    trap    #15

    ; clear total size variable and setup trap parameters
    move.l  4(sp), a1
    move.l  a1, a0
.read:
    ; read bytes
    move.l  #TRAP_CODE_READ_FILE, d0
    move.l  #FILE_READ_WRITE_BUFFER_SIZE, d2
    trap    #15
    add.l   d2, a1

    ; exit loop if less number of bytes are read
    cmp.l   #FILE_READ_WRITE_BUFFER_SIZE, d2
    bge     .read

    ; close file
    move.l  #TRAP_CODE_CLOSE_FILE, d0
    trap    #15

    ; return
    move.l  a1, d0                                      ; calculate file size in d0 (return value)
    sub.l   a0, d0
    sub.l   #20, sp
    movem.l (sp)+, d1-d2/a0-a1
    rts

; code for return is not re-used here as an optimization to cut additional jump for success case
.errorReturn:
    move.l  #0, d0                                      ; set d0 to 0, indicating error
    sub.l   #20, sp
    movem.l (sp)+, d1-d2/a0-a1
    rts





; Writes data to a file and writes the bytes into memory
; arg1 = null terminated file name
; arg2 = source data memory address
; arg3 = size of data in bytes
WriteToFile:
    movem.l d1-d3/a1, -(sp)
    add.l   #20, sp

    ; open file and get file-ID in d1.l
    move.l  (sp), a1
    move.l  #TRAP_CODE_CREATE_FILE, d0
    trap    #15

    ; clear total size variable and setup trap parameters
    move.l  4(sp), a1
    move.l  8(sp), d3
    cmp.l   #FILE_READ_WRITE_BUFFER_SIZE, d3
    blt     .flushBuffer
.read:
    ; write bytes
    move.l  #TRAP_CODE_WRITE_FILE, d0
    move.l  #FILE_READ_WRITE_BUFFER_SIZE, d2
    trap    #15
    add.l   d2, a1

    ; exit loop if there aren't enough bytes to write
    sub.l   #FILE_READ_WRITE_BUFFER_SIZE, d3
    cmp.l   #FILE_READ_WRITE_BUFFER_SIZE, d3
    bge     .read

.flushBuffer:
    ; write any extra bytes
    move.l  #TRAP_CODE_WRITE_FILE, d0
    move.l  d3, d2
    trap    #15

    ; close file
    move.l  #TRAP_CODE_CLOSE_FILE, d0
    trap    #15

    ; return
    sub.l   #20, sp
    movem.l (sp)+, d1-d3/a1
    rts


