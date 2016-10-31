
; Essential graphics utility routines


; trap codes and options
TRAP_CODE_CLEAR_SCREEN                      EQU     11
TRAP_CODE_CLEAR_SCREEN_OPTION               EQU     $FF00
TRAP_CODE_RESOLUTION_CHANGE                 EQU     33
TRAP_CODE_FULLSCREEN_OPTION                 EQU     2
TRAP_CODE_SET_VIDEO_MODE                    EQU     92
TRAP_CODE_OPTION_DOUBLE_BUFFER              EQU     17
TRAP_CODE_SWAP_BUFFER                       EQU     94
TRAP_CODE_DRAW_PIXEL                        EQU     82
TRAP_CODE_DRAW_LINE                         EQU     84
TRAP_CODE_DRAW_LINE_TO                      EQU     85
TRAP_CODE_MOVE_TO                           EQU     86
TRAP_CODE_DRAW_RECTANGLE                    EQU     87
TRAP_CODE_FLOOD_FILL                        EQU     89
TRAP_CODE_SET_PEN_COLOR                     EQU     80
TRAP_CODE_SET_FILL_COLOR                    EQU     81







; Sets the resolution and enables disables double buffering
; arguments are read from stack
; arg1 = screen width in pixels
; arg2 = screen height in pixels
; arg3 = set to non zero for full screen display
SetScreenResoultion:
    ; push all register values to stack and set stack to first argument (past return address)
    movem.l d0-d2, -(sp)
    add.l   #16, sp

    ; read arguments from stack to registers
    move.l  (sp), d1
    move.l  4(sp), d2

    ; change window resolution
    ; set resolution width and height in upper and lower bits of d1 respectively
    move.l  #TRAP_CODE_RESOLUTION_CHANGE, d0
    lsl.l   #8, d1
    lsl.l   #8, d1
    move.w  d2, d1
    trap    #15

    move.l  8(sp), d1
    tst.l   d1
    beq     .return

    ; enable full screen
    move.l  #TRAP_CODE_RESOLUTION_CHANGE, d0
    move.l  #2, d1
    trap    #15

.return:
    sub.l   #16, sp
    movem.l (sp)+, d0-d2
    rts




; Clears the screen
ClearScreen:
    movem.l d0-d1, -(sp)
    move.b  #TRAP_CODE_CLEAR_SCREEN, d0
    move.l  #TRAP_CODE_CLEAR_SCREEN_OPTION, d1
    TRAP    #15
    movem.l (sp)+, d0-d1




; Enable double buffering
EnableDoubleBuffer:
    movem.l d0-d1, -(sp)
    move.l  #TRAP_CODE_SET_VIDEO_MODE, d0
    move.l  #TRAP_CODE_OPTION_DOUBLE_BUFFER, d1
    trap    #15
    movem.l (sp)+, d0-d1
    rts




; Enable fullscreen
EnableFullScreen:
    movem.l d0-d1, -(sp)
    move.l  #TRAP_CODE_RESOLUTION_CHANGE, d0
    move.l  #TRAP_CODE_FULLSCREEN_OPTION, d1
    trap    #15
    movem.l (sp)+, d0-d1
    rts





; Copies background buffer to visible screen
BlitBuffer:
    movem.l d0, -(sp)
    move.l  #TRAP_CODE_SWAP_BUFFER, d0
    trap    #15
    movem.l (sp)+, d0
    rts


; Flood fills the area at x, y with a color
; arguments are read from stack
; arg1 = x position on screen
; arg2 = y position on screen
; arg3 = fill color



FloodFill:
    ; push all register values to stack and set stack to first argument (past return address)
    movem.l d0-d2, -(sp)
    add.l   #16, sp

    ; read color value to d1
    move.l  8(sp), d1
    move.l  #TRAP_CODE_SET_FILL_COLOR, d0
    trap    #15
 
    ; read x and y value to d1 and d2
    move.l  (sp), d1
    move.l  4(sp), d2
    move.l  #TRAP_CODE_FLOOD_FILL, d0
    trap    #15
    
    sub.l   #16, sp
    movem.l (sp)+, d0-d2
    rts



; arg1 = top left x position
; arg2 = top left y position y
; arg3 = bottom right x position
; arg4 = bottom right y position
; arg5 = color
DrawRectangle:
    movem.l d0-d4, -(sp)
    add.l   #24, sp

    move.l  16(sp), d1
    move.l  #TRAP_CODE_SET_PEN_COLOR, d0
    trap    #15

    move.l  #TRAP_CODE_SET_FILL_COLOR, d0
    trap    #15

    move.l  #TRAP_CODE_DRAW_RECTANGLE, d0
    move.l  (sp), d1
    move.l  4(sp), d2
    move.l  8(sp), d3
    move.l  12(sp), d4
    trap    #15

    sub.l   #24, sp
    movem.l (sp)+, d0-d4
    rts




; Draws an image on to screen.
; arg1 = address of image in memory
; arg2 = x position on screen
; arg3 = y position on screen
; first two words of the image are width and height of the image respectively
DrawImage:
    movem.l d0-d7/a0-a6, -(sp)
    add.l   #64, sp

    ; get arguments from stack into registers
    move.l  (sp), a0                                        ; a0 = memory address of image
    move.l  4(sp), d3                                       ; d3 = x pos on the screen
    move.l  8(sp), d2                                       ; d2 = y pos on the screen

    ; read image width and height
    move.w  (a0)+, d4
    move.w  (a0)+, d5
    ext.l   d4
    ext.l   d5


    ; loop counters. setting loop counters to 1 less than the max value because dbf jumps an extra time
    sub.w   #1, d4
    move.l  d4, d6
    sub.w   #1, d5
    move.l  d5, d7

.drawLoop:
    ; copy 1 pixel (AABBGGRR) data and set it as pen color
    move.l  (a0)+, d1
    move.l  #TRAP_CODE_SET_PEN_COLOR, d0
    trap    #15

    ; plot pixel at correct x, y on screen (d3, d2)
    move.l  d3, d1
    move.l  #TRAP_CODE_DRAW_PIXEL, d0
    trap    #15
    add.w   #1, d3

    ; loop x
    dbf     d6, .drawLoop

    ; we completed a row, so move to next row on screen
    add.w   #1, d2
    move.l  4(sp), d3
    move.l  d4, d6
    dbf     d7, .drawLoop

    sub.l   #64, sp
    movem.l (sp)+, d0-d7/a0-a6
    rts






; Draws an image chunk on to screen.
; args on stack
; arg1 = address of image in memory
; arg2 = chunk x
; arg3 = chunk y
; arg4 = chunk width
; arg5 = chunk height
; arg6 = x position
; arg7 = y position
; first two words of the image are width and height of the image respectively which we will ignore
DrawImageChunk:
    move.l  4(sp), a6                                   ; a6 = memory address of image
    move.l  8(sp), d1                                   ; d1 = chunk x
    move.l  12(sp), d5                                  ; d5 = chunk y
    move.l  16(sp), d6                                  ; d6 = chunk width
    move.l  20(sp), d7                                  ; d7 = chunk height
    move.l  24(sp), d3                                  ; d3 = x pos on the screen
    move.l  28(sp), d2                                  ; d2 = y pos on the screen

    ; read image width into d0 and move ahead skipping image height
    clr.l   d0
    move.w  (a6)+, d0
    add.l   #2, a6

    ; calculate correct offset to start within image and move a0 to that offset
    ; a6 = a6 + ((chunk y * image width) + chunk x) * 4
    move.l  d0, d4
    mulu    d5, d0
    add.l   d1, d0
    lsl.l   #2, d0
    add.l   d0, a6

    ; subtract chunk width from image width to get offset value to be added at end of each row
    sub.w   d6, d4
    mulu    #4, d4

    move.w  d6, d5                                      ; copy chunk width to d5
    add.w   d3, d6                                      ; adds x pos to width so that we have max value of x in d6
    add.w   d2, d7                                      ; adds y pos to height so that we have max value of y in d7

.drawLoop:
    ; copy 1 pixel (AABBGGRR) data and set it as pen color
    move.l  (a6)+, d1
    move.l  #TRAP_CODE_SET_PEN_COLOR, d0
    trap    #15

    ; plot pixel at correct x, y on screen (d3, d2)
    move.l  d3, d1
    move.l  #TRAP_CODE_DRAW_PIXEL, d0
    trap    #15

    ; if x pos is not equal to max x value, row is not complete
    add.w   #1, d3
    cmp.l   d3, d6
    bne     .drawLoop

    ; we completed a row, so subtract chunk width from x pos and add d4 to a2 to bring a2 to next row of the chunk
    sub.w   d5, d3
    add.l   d4, a6

    ; if y pos is not equal to max y value, picture is not complete
    add.w   #1, d2
    cmp.l   d2, d7
    bne     .drawLoop
    rts






; Draws an RLE sprite on the screen.
; arg1 = address of sprite in memory
; arg2 = x position on screen
; arg3 = y position on screen
; arg4 = width of the sprite
; arg5 = height of the sprite
DrawSprite:
    movem.l d0-d7/a0, -(sp)
    add.l   #40, sp

    ; get arguments from stack into registers
    move.l  (sp), a0                                        ; a0 = memory address of image
    move.l  4(sp), d3                                       ; d3 = x pos on the screen
    move.l  8(sp), d2                                       ; d2 = y pos on the screen
    move.l  12(sp), d6                                      ; d6 = width of sprite
    move.l  16(sp), d7                                      ; d7 = height of sprite

    ; add x pos and y pos to width and height respectively
    add.l   d3, d6
    sub.w   #1, d6
    add.l   d2, d7
    move.l  d2, d4

.drawLoop:
    ; load run length into d5
    move.w  (a0)+, d5

    ; copy 1 pixel (AABBGGRR) data and set it as pen color
    move.l  (a0)+, d1
    bne     .drawRun

    ; if color is zero, move x forward by run length without drawing it
    add.w   d5, d3
    bra     .loopCheck

.drawRun:
    move.l  #TRAP_CODE_SET_PEN_COLOR, d0
    trap    #15

    ; draw a line from (d1, d2) to (d1+run_length, d2)
    move.l  d3, d1
    add.w   d5, d3
    move.l  #TRAP_CODE_DRAW_LINE, d0
    trap    #15

.loopCheck:
    cmp.w   d6, d3
    blt     .drawLoop

    ; we completed a row, so move to next row on screen
    move.l  4(sp), d3
    add.w   #1, d2
    move.l  d2, d4

    cmp.w   d2, d7
    bne     .drawLoop

    sub.l   #40, sp
    movem.l (sp)+, d0-d7/a0
    rts

