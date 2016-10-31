

; BMP header field offsets and default values
BMP_SIGNATURE                       EQU     $424D
BMP_IMAGE_OFFSET_VALUE_OFFSET       EQU     $A
BMP_HEADER_OFFSET                   EQU     $E
BMP_WIDTH_OFFSET                    EQU     $12
BMP_HEIGHT_OFFSET                   EQU     $16
BMP_BITS_PER_PIXEL_OFFSET           EQU     $1C
BMP_COMPRESSION_OFFSET              EQU     $1E
BMP_IMAGE_SIZE_OFFSET               EQU     $22

; Other BMP processing helper constants
ROW_SIZE_MULTIPLE_OF                EQU     4
BPP_256_COLOR_IMAGE                 EQU     8




; Reads a bmp file with supported format (256 colors only for now) and
; extracts the image as raw image (32 bit per pixel - 00BBGGRR) to a destination memory
; images exceeding 374,300 bytes in size (width * height) may overflow the memory
; arg1 = address of BMP file data in memory
; arg2 = memory address of destination
; returns size of raw image in d0.l
ParseBMP:
    movem.l d1-d7/a0-a6, -(sp)
    add.l   #60, sp

    ; read arguments from stack to registers
    move.l  (sp), a6                                    ; source address to BMP data
    move.l  4(sp), a5                                   ; destination address in memory

    ; local variables
    ; a6 = source address to BMP
    ; a5 = destination address
    ; a0 = address of pixel data within the source image
    ; a1 = address of palette data within the source image
    ; d0 = size of pixel data in bytes
    ; d1 = width of bitmap
    ; d2 = height of bitmap
    ; d3 = BPP of bitmap

    ; check the file signature ('BM') and return if it doesn't match
    move.w  (a6), d7
    cmp.w   #BMP_SIGNATURE, d7
    bne     .errorReturn

    ; get the pixel data offset from file header and add it to address of BMP image to get the pixel array address in memory
    ; store the resulting memory address to a0
    move.l  BMP_IMAGE_OFFSET_VALUE_OFFSET(a6), d0
    rol.w   #8, d0                                      ; byte swap
    swap.w  d0
    rol.w   #8, d0
    add.l   a6, d0
    move.l  d0, a0

    ; get the bitmap header size and compute BMP header end position
    ; value in a1 will be offset of color palette (next location after bitmap header)
    move.l  BMP_HEADER_OFFSET(a6), d0                   ; get the first element in header (which is the size of header as long word) to d0
    rol.w   #8, d0                                      ; byte swap
    swap.w  d0
    rol.w   #8, d0
    add.l   #BMP_HEADER_OFFSET, d0                      ; add header offset to header size. The new offset value at a1 points to color palette
    add.l   a6, d0
    move.l  d0, a1

    ; get bitmap width and height. width and height won't need more than 2 bytes
    ; since file is little-endian just read first two bytes and do a byte swap
    ; d1 will be width and d2 will be height of the image
    move.w  BMP_WIDTH_OFFSET(a6), d1
    rol.w   #8, d1
    move.w  BMP_HEIGHT_OFFSET(a6), d2
    rol.w   #8, d2

    ; read compression value (4 bytes, we don't need to byte swap because we are checking if it is zero)
    ; return from function if bitmap is compressed since we can't handle compressed bitmaps yet!
    move.w  BMP_COMPRESSION_OFFSET(a6), d0      
    bne     .errorReturn

    ; read image size in bytes of pixel array (includes padding) to d0
    move.l  BMP_IMAGE_SIZE_OFFSET(a6), d0
    rol.w   #8, d0                                      ; byte swap
    swap.w  d0
    rol.w   #8, d0

    ; read BPP value (2 bytes, byte swapped). d3 will be the bits per pixel value
    ; return from function if BPP is not one of the supported values (currently only 8 bits per pixel)
    move.w  BMP_BITS_PER_PIXEL_OFFSET(a6), d3
    rol.w   #8, d3
    cmp.w   #BPP_256_COLOR_IMAGE, d3
    beq     .256Color
    bra     .errorReturn

.256Color:
    sub.l   #60, sp

    ; push arguments to Process256ColorBitmap to stack in reverse order
    move.l  a5, -(sp)                                   ; destination address
    move.l  d0, -(sp)                                   ; size of pixel data in bytes (includes padding)
    move.l  d2, -(sp)                                   ; height of bitmap
    move.l  d1, -(sp)                                   ; width of bitmap
    move.l  a0, -(sp)                                   ; address of pixel data within the source image
    move.l  a1, -(sp)                                   ; address of palette data within the source image

    jsr Process256ColorBMP
    add.l   #24, sp                                     ; fixup stack

    ; calculate total size of image and return it via d0
    move.l  d1, d0
    mulu    d2, d0
    lsl.l   #2, d0
    add.l   #4, d0
    bra     .return

.errorReturn:
    sub.l   #60, sp
    move.l  #0, d0                                      ; size of raw image being returned. 0 for error

.return:
    movem.l (sp)+, d1-d7/a0-a6
    rts







; Reads a 256 color bmp image data and puts it in memory as a raw 32 bit color image preceeded with width and height words
; arguments are read from stack
; arg1 = address of palette data within the source image
; arg2 = address of pixel data within the source image
; arg3 = width of bitmap
; arg4 = height of bitmap
; arg5 = pixel data size in bytes
; arg6 = memory address of destination
Process256ColorBMP:
    movem.l d0-d7/a0-a2, -(sp)
    add.l   #48, sp

    ; local variables
    ; a0 = address of palette data within the source image
    ; a1 = address of pixel data within the source image
    ; a2 = memory address of destination
    ; d0 = width of bitmap / 4
    ; d1 = height of bitmap
    ; d2 = padding bytes * 4
    ; d3 = number of long words per row

    ; read arguments from stack to registers
    move.l  (sp), a0                                    ; address of palette data within the source image
    move.l  4(sp), a1                                   ; address of pixel data within the source image
    move.l  8(sp), d0                                   ; width of bitmap
    move.l  12(sp), d1                                  ; height of bitmap
    move.l  16(sp), d7                                  ; pixel data size in bytes
    move.l  20(sp), a2                                  ; memory address of destination

    ; write width and height words to destination
    move.w  d0, (a2)+
    move.w  d1, (a2)+

    ; copy width to d4 for later usage in computing offsets
    move.l  d0, d4

    ; calculate the padding and store it in d2. also d0 becomes (width / 4)
    divu    #ROW_SIZE_MULTIPLE_OF, d0
    move.w  d0, d3                                      ; copy the quotient to d3
    swap.w  d0                                          ; d0 lower word has remainder now
    clr.l   d2
    move.w  #ROW_SIZE_MULTIPLE_OF, d2                   ; calculate padding as (ROW_SIZE_MULTIPLE_OF - remainder)
    sub.w   d0, d2
    and.w   #$003, d2                                   ; if width is a multiple of 4, the previous calculation returns padding as 4. Masking the padding to fix that
    swap.w  d0                                          ; d0 lower word is now (width/4) quotient again

    ; find offset to add to a1 to take it to the last row of the bitmap data
    ; this is done since bitmap data is stored upside down. last row in the data is first row in the screen
    add.l   d2, d4                                      ; d4 = width + padding
    lsl.l   #2, d2                                      ; this multiplication is done for easy offset subtraction in while moving data to raw image memory

    ; move a1 to starting of last row of source bitmap pixel data.
    ; a1 = address of pixel data + image size in bytes - (width + padding) 
    add.l   d7, a1
    sub.l   d4, a1

    ; d4 is doubled so that d4 is now 2*(width + padding)
    ; this is done so that subtracting d4 from a1 at end of a row brings a1 to start of previous row
    add     d4, d4

    ; skip padding calculation if padding is zero
    cmp.w   #0, d2
    beq     .noPadding

    add.w   #1, d0                                      ; d1 = no of long words per row in the bitmap data

.noPadding:
    clr.l   d3
    move.w  d0, d3                                      ; d3 is the loop counter

.pixelLoop:
    ; read data for 4 pixels (index to color table) into d5
    move.l  (a1)+, d5
    rol.w   #8, d5                                      ; byte swap to get pixel bytes in order
    swap.w  d5
    rol.w   #8, d5

    ; get first pixel data from lower byte of d5 to d6 and get the color value for it from color table
    clr.l   d6
    move.b  d5, d6
    lsl.l   #2, d6                                      ; calculate offset in color table. each entry in color table is a long hence multiply index by 4
    move.l  (a0,d6), d7                                 ; get long word at the index from color table
    ror.l   #8, d7                                      ; the entry in color table is of BBGGRRAA format. 68K needs it to be AABBGGRR format. hence rotate
    move.l  d7, (a2)+                                   ; move the 4 byte color data to destination memory

    ; shift left to bring next byte (pixel #2 data) to lower byte of d5.
    ; repeat the color move operation for the next pixel as well
    lsr.l   #8, d5
    clr.l   d6
    move.b  d5, d6
    lsl.l   #2, d6
    move.l  (a0,d6), d7
    ror.l   #8, d7
    move.l  d7, (a2)+

    ; process pixel #3
    lsr.l   #8, d5
    clr.l   d6
    move.b  d5, d6
    lsl.l   #2, d6
    move.l  (a0,d6), d7
    ror.l   #8, d7
    move.l  d7, (a2)+

    ; process pixel #4
    lsr.l   #8, d5
    clr.l   d6
    move.b  d5, d6
    lsl.l   #2, d6
    move.l  (a0,d6), d7
    ror.l   #8, d7
    move.l  d7, (a2)+

    ; check if row is complete
    sub     #1, d3
    bne     .pixelLoop

    ; account for padding by subtracting (padding * 4) bytes from a2
    sub.l   d2, a2

    ; check if all rows are complete
    move.w  d0, d3
    sub.l   d4, a1
    sub     #1, d1
    bne     .pixelLoop

    sub.l   #48, sp
    movem.l (sp)+, d0-d7/a0-a2
    rts





; Extracts an image chunk, encodes it with RLE and writes it to a memory location
; arg1 = address of image in memory
; arg2 = chunk x
; arg3 = chunk y
; arg4 = chunk width
; arg5 = chunk height
; arg6 = destination address
; returns size of encoded chunk in bytes in d0
EncodeChunk:
    movem.l d1-d7/a0-a2, -(sp)
    add.l   #44, sp

    ; set a0 as the memory address of image
    move.l  (sp), a0

    ; subtract chunk width from image width to get offset value to be added at end of each row
    move.l  #0, d0
    move.w  (a0), d0
    sub.l   12(sp), d0
    ; multiply this value by 4 since each pixel is 4 bytes
    add.w   d0, d0
    add.w   d0, d0
    ; the above offset is stored in d5
    move.l  d0, d5

    ; calculate correct offset to start within image and move a0 to that offset
    ; a0 = a0 + ((image width * chunk y) + chunk x) * 4
    move.l  #0, d0
    move.w  (a0), d0
    move.l  8(sp), d1
    mulu    d1, d0
    add.l   4(sp), d0
    lsl.l   #2, d0
    add.l   d0, a0

    ; adds chunk x pos to chunk width so that we have max value of x in d6
    move.l  12(sp), d6
    add.l   4(sp), d6
    ; adds chunk y pos to chunk height so that we have max value of y in d7
    move.l  16(sp), d7
    add.l   8(sp), d7

    ; skip initial width and height data
    add.l   #4, a0
    ; init a1 with destination memory address
    move.l  20(sp), a1
    move.l  a1, a2

    ; registers used
    ; d3 = x counter
    ; d4 = y counter
    ; d5 = offset to add at end of each row
    ; d6 = max x
    ; d7 = max y
    ; d0 = current color
    ; d1 = previous color
    ; d2 = run length
    ; a0 = source address
    ; a1 = destination address
    ; a2 = destination address base
    ; available for use = d0, d1, d2

    ; init y counter
    move.l  8(sp), d4
.yLoop:
    ; init y counter
    move.l  4(sp), d3

    ; read first pixel to previous color and init run length to 1
    move.l  (a0)+, d1
    move.l  #1, d2
    ; add 1 to x counter since we already read one pixel
    add.w   #1, d3

.xLoop:
    ; read current pixel data
    move.l  (a0)+, d0
    ; if previous color is not same finish the previous color run
    cmp.l   d0, d1
    bne     .finishRun
    bra     .xLoopEnd

.finishRun:
    ; write run length and previous color to destination
    move.w  d2, (a1)+
    move.l  d1, (a1)+

    ; set previous color to current color and run length to zero
    move.l  d0, d1
    move.l  #0, d2
.xLoopEnd:
    ; increment run length
    add.w   #1, d2

    ; if x pos is not equal to max x value, row is not complete
    add.w   #1, d3
    cmp.l   d3, d6
    bne     .xLoop

    ; we completed a row, so force finish the run and write the run info to destination
    ; next row of the chunk and bring x pos back to x offset
    move.w  d2, (a1)+
    add.l   d5, a0
    sub.l   12(sp), d3

    ; if y pos is not equal to max y val
    move.l  d1, (a1)+

    ; add pre-calculated offset to a1 toue, picture is not complete
    add.w   #1, d4
    cmp.l   d4, d7
    bne     .yLoop

    ; calculate size of encoded chunk in bytes
    move.l  a1, d0
    sub.l   a2, d0

    sub.l   #44, sp
    movem.l (sp)+, d1-d7/a0-a2
    rts

