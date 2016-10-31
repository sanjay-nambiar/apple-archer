
; general utilities

TRAP_CODE_SET_PEN_COLOR             EQU         80
TRAP_CODE_SET_FILL_COLOR            EQU         81
TRAP_CODE_DRAW_FILLED_RECTANGLE     EQU         87




SegmentBitMasks     dc.b    $3F, $06, $5B, $4F, $66, $6D, $7D, $07, $7F, $6F
; each long word has width, height and x, y positions for the segment
SegmentCoords       dc.b    $4,$1, $1,$0,   $1,$4, $5,$1,   $1,$4, $5,$6,   $4,$1, $1,$A,   $1,$4, $0,$6,    $1,$4, $0,$1,   $4,$1, $1,$5




; Draws a 7 segment display number at a location and with a given scale
; arg1 = digit  (max supported number is 327679)
; arg2 = x position
; arg3 = y position
; arg4 = scale (for performance, scale is a power of two, hence this value is the bits to shift left)
; arg5 = color in 00BBGGRR format
; arg6 = width in number of digits
; arg7 = flag indicating if leading zeroes are needed
Draw7Segment:
    movem.l d0-d7/a0-a1, -(sp)
    add.l   #44, sp    

    ; set pen and fill colors
    move.l  16(sp), d1
    move.l  #TRAP_CODE_SET_PEN_COLOR, d0
    trap    #15
    move.l  #TRAP_CODE_SET_FILL_COLOR, d0
    trap    #15

    ; calculate right end position
    move.l  #8, d0
    move.l  20(sp), d1
    mulu    d1, d0
    sub.l   #8, d0
    move.l  12(sp), d1
    lsl.l   d1, d0
    add.l   d0, 4(sp)

.digitLoop:
    move.l  (sp), d7
    cmp.l   #10, d7
    blt     .noDivide

    divu    #10, d7
    move.w  d7, d0
    swap.w  d7
    ext.l   d7
    ext.l   d0

    ; update the argument in stack with the new value
    move.l  d0, (sp)
    bra .startSegment

.noDivide:
    move.l  #0, (sp)

.startSegment:
    ; load addresses of bit masks and coordinates to a0 and a1
    lea     SegmentBitMasks, a0
    lea     SegmentCoords, a1

    ; load the correct bitmask into d7 and offset to coords in d5
    move.b  (a0, d7), d7
    move.l  #0, d5
.segmentLoop:
    ; right shift and check carry to determine if a segment is lit
    lsr.b   #1, d7
    bcc     .endSegmentLoop

    ; clear registers
    move.l  #0, d1
    move.l  #0, d2
    move.l  #0, d3
    move.l  #0, d4
    move.l  12(sp), d0

    ; get the coords if segment is lit and draw rectangle
    move.l  (a1, d5), d6
    move.b  d6, d2                                                      ; y position
    lsl.l   d0, d2                                                      ; scale
    add.l   8(sp), d2                                                   ; add y offset
    
    lsr.l   #8, d6
    move.b  d6, d1                                                      ; x position
    lsl.l   d0, d1                                                      ; scale
    add.l   4(sp), d1                                                   ; add x offset
    
    lsr.l   #8, d6
    move.b  d6, d4                                                      ; height
    lsl.l   d0, d4                                                      ; scale
    add.w   d2, d4                                                      ; add top y position to make it a lower y coordinate
    sub.w   #1, d4
    
    lsr.l   #8, d6
    move.b  d6, d3                                                      ; width
    lsl.l   d0, d3                                                      ; scale
    add.w   d1, d3                                                      ; add left x position to make it a right x coordinate
    sub.w   #1, d3
    
    move.l  #TRAP_CODE_DRAW_FILLED_RECTANGLE, d0
    trap    #15

.endSegmentLoop:
    add.b   #4, d5
    cmp.b   #28, d5
    blt     .segmentLoop

    sub.l   #1, 20(sp)

    ; subtract 8*scale from x pos and update x pos in stack with this new value
    move.l  #8, d1
    move.l  12(sp), d0
    lsl.l   d0, d1
    sub.l   d1, 4(sp)

    move.l  (sp), d0
    bne     .digitLoop

    move.l  20(sp), d1
    and.l   24(sp), d1
    bne     .startSegment

    sub.l   #44, sp
    movem.l (sp)+, d0-d7/a0-a1
    rts
