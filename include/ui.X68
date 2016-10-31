

; UI related methods

SCORE_X                     EQU         500
SCORE_Y                     EQU         95
SCORE_WIDTH                 EQU         55
SCORE_HEIGHT                EQU         45
SCORE_SCALE_FACTOR          EQU         2

MESSAGE_X                   EQU         0
MESSAGE_Y                   EQU         0

END_X                       EQU         80
END_Y                       EQU         50
END_SCORE_X                 EQU         340
END_SCORE_Y                 EQU         55


; Player Score
Score            ds.l        1


UiInit:
    move.l  #0, (Score)
    rts


; Displays main menu
; Returns the selected menu option in d0
ShowMenu:
    jsr     ClearInput
    jsr     ClearScreen

    ; Draw menu screen
    move.l  #0, -(sp)
    move.l  #0, -(sp)
    move.l  #0, -(sp)
    move.l  (BgSpritePtr), -(sp)
    jsr     DrawSpriteSheetFrame
    add.l   #16, sp

     ; Draw menu screen
    move.l  #MESSAGE_Y, -(sp)
    move.l  #MESSAGE_X, -(sp)
    move.l  #0, -(sp)
    move.l  (MessageSpritePtr), -(sp)
    jsr     DrawSpriteSheetFrame
    add.l   #16, sp

    ; play menu music in loop
    move.l  #0, -(sp)
    move.l  #0, d0
    move.b  (MenuMusicId), d0
    move.l  d0, -(sp)
    jsr     PlaySound
    add.l   #8, sp

    lea     KeyStates, a5
    lea     PrevKeyStates, a6
    move.l  #0, d7
.read:
    jsr     ReadInput

    ; if ENTER key is pressed, exit menu.
    move.b  ENTER_OFFSET(a5), d7
    move.b  ENTER_OFFSET(a6), d0
    eor.b   d0, d7
    bne     .exitMenu

    jsr     BlitBuffer
    bra     .read

.exitMenu:
    ; stop music
    move.l  #0, d0
    move.b  (MenuMusicId), d0
    move.l  d0, -(sp)
    jsr     StopSound
    add.l   #4, sp

    move.l  d6, d0
    rts


ShowEndScreen:
    jsr     ClearScreen

    ; Draw end screen
    move.l  #END_Y, -(sp)
    move.l  #END_X, -(sp)
    move.l  #0, -(sp)
    move.l  (EndSpritePtr), -(sp)
    jsr     DrawSpriteSheetFrame
    add.l   #16, sp

    move.l  #TRUE, -(sp)
    move.l  #2, -(sp)
    move.l  #$000000FF, -(sp)
    move.l  #SCORE_SCALE_FACTOR, -(sp)
    move.l  #END_SCORE_Y, -(sp)
    move.l  #END_SCORE_X, -(sp)
    move.l  (Score), -(sp)
    jsr     Draw7Segment
    add.l   #28, sp

    jsr     BlitBuffer

    lea     KeyStates, a5
    lea     PrevKeyStates, a6
    move.l  #0, d7
.read:
    jsr     ReadInput

    ; if ENTER key is pressed, exit.
    move.b  ENTER_OFFSET(a5), d7
    move.b  ENTER_OFFSET(a6), d0
    eor.b   d0, d7
    bne     .exitEnd
    bra     .read

.exitEnd:
    move.l  d6, d0
    rts


; arg1 = current time
DisplayScore:
    move.l  #$0001E101, -(sp)
    move.l  #(SCORE_Y+SCORE_HEIGHT), -(sp)
    move.l  #(SCORE_X+SCORE_WIDTH), -(sp)
    move.l  #SCORE_Y, -(sp)
    move.l  #SCORE_X, -(sp)
    jsr     DrawRectangle
    add.l   #20, sp

    ; draw score digits
    move.l  #TRUE, -(sp)
    move.l  #2, -(sp)
    move.l  #$000000FF, -(sp)
    move.l  #SCORE_SCALE_FACTOR, -(sp)
    move.l  #SCORE_Y, -(sp)
    move.l  #SCORE_X, -(sp)
    move.l  (Score), -(sp)
    jsr     Draw7Segment
    add.l   #28, sp
.return:
    rts

