

; Sub routines for managing animations


    INCLUDE "include/graphics.X68"



; Sprites structure field offsets
SPRITES_FRAME_WIDTH_OFFSET          EQU     0               ; word
SPRITES_FRAME_HEIGHT_OFFSET         EQU     2               ; word
SPRITES_FRAME_COUNT_OFFSET          EQU     4               ; word
SPRITES_FRAMES_ARRAY_OFFSET         EQU     6               ; word






; Draws a given frame from an RLE sprite sheet on the screen.
; arg1 = address of the animation block in memory
; arg2 = frame index
; arg3 = x position on screen
; arg4 = y position on screen
DrawSpriteSheetFrame:
    movem.l d0-d7/a0, -(sp)

    ; get arguments from stack into registers
    move.l  40(sp), a0                                      ; a0 = memory address of image
    move.l  44(sp), d0                                      ; d0 = frame index
    move.l  48(sp), d1                                      ; d1 = x pos on the screen
    move.l  52(sp), d2                                      ; d2 = y pos on the screen

    ; read width and height of frame
    move.l  #0, d4
    move.w  SPRITES_FRAME_WIDTH_OFFSET(a0), d4
    move.l  #0, d5
    move.w  SPRITES_FRAME_HEIGHT_OFFSET(a0), d5

    ; find offset into frame address array
    add.l   #SPRITES_FRAMES_ARRAY_OFFSET, a0
    lsl.l   #2, d0

    ; draw sprite
    move.l  d5, -(sp)
    move.l  d4, -(sp)
    move.l  d2, -(sp)
    move.l  d1, -(sp)
    move.l  (a0, d0), -(sp)
    jsr     DrawSprite
    add.l   #20, sp

    movem.l (sp)+, d0-d7/a0
    rts




; Extracts all specified chunks from a raw image, and encodes it with RLE
; The encoded frames are written to a memory location as spearate images (not as a single contiguous image)
; arg1 = address of image in memory
; arg2 = frame width
; arg3 = frame height
; arg4 = destination address
; returns size of all the encoded frames combined in bytes in d0
ImageToSpriteFrames:
    movem.l d1-d7/a0-a2, -(sp)

    move.l  44(sp), a0
    move.l  48(sp), d1
    move.l  52(sp), d2
    move.l  56(sp), a1

    ; get width and height of image into d2 and d3
    move.w  (a0), d3
    ext.l   d3
    move.w  2(a0), d4
    ext.l   d4

    ; find number of frames
    ; d5 = width / frame width
    move.l  d3, d5
    divu    d1, d5
    ; d6 = height / frame height
    move.l  d4, d6
    divu    d2, d6
    ; d5 = (width / frame width) + (height / frame height)
    mulu    d6, d5

    ; write sprite sheet structure fields to destination
    move.w  d1, SPRITES_FRAME_WIDTH_OFFSET(a1)
    move.w  d2, SPRITES_FRAME_HEIGHT_OFFSET(a1)
    move.w  d5, SPRITES_FRAME_COUNT_OFFSET(a1)
    add.l   #SPRITES_FRAMES_ARRAY_OFFSET, a1
    move.l  a1, a2
    lsl.l   #2, d5                                      ; bytes required to store addresses for all frame data locations
    add.l   d5, a2                                      ; a2 is now at the start of the frame data location

    ; set total size to 0
    move.l  #6, d7
    add.l   d5, d7

    ; x and y counters
    move.l  #0, d5
    move.l  #0, d6

.loop:
    ; store address of new encoded image to current index in frame address array
    move.l  a2, (a1)+

    ; call chunk routine
    move.l  a2, -(sp)
    move.l  d2, -(sp)
    move.l  d1, -(sp)
    move.l  d6, -(sp)
    move.l  d5, -(sp)
    move.l  a0, -(sp)
    jsr     EncodeChunk
    add.l   #24, sp

    ; add size of the last encoded frame to total size
    add.l   d0, d7
    add.l   d0, a2

    ; update chunk x and check if we reached end of the row
    add.w   d1, d5
    cmp.w   d5, d3
    bne     .loop

    ; reset chunk x to zero for the beginning of next row
    move.l  #0, d5

    ; terminate loop if we reached last row last frame
    add.l   d2, d6
    cmp.w   d6, d4
    bne     .loop

    move.l  d7, d0
    movem.l (sp)+, d1-d7/a0-a2
    rts



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
