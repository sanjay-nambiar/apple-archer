
GROUND_Y                EQU     450
TREE_TRUNK_TOP          EQU     200

REPAINT_X               EQU     0
REPAINT_Y               EQU     TREE_TRUNK_TOP

LOADING_SPRITE_X        EQU     215
LOADING_SPRITE_Y        EQU     120
LOADING_SPRITE_WIDTH    EQU     200
LOADING_SPRITE_HEIGHT   EQU     220

DELAY_TIME_100TH        EQU     5
TRAP_CODE_TIME          EQU     8
TRAP_CODE_DELAY         EQU     23

MAX_MISSES              EQU     10


; Updates screen resolution, turns on double buffering and displays Loading screen
Loading:
    ; set screen resolution and full screen
    move.l  #0, -(sp)
    move.l  #SCREEN_HEIGHT, -(sp)
    move.l  #SCREEN_WIDTH, -(sp)
    jsr     SetScreenResoultion
    add.l   #12, sp

    jsr     EnableDoubleBuffer

    ; load and parse loading image
    move.l  #LOADING_SPRITE_HEIGHT, -(sp)
    move.l  #LOADING_SPRITE_WIDTH, -(sp)
    move.l  #LoadingSpritePtr, -(sp)
    move.l  #LoadingSpriteBMP, -(sp)
    jsr     LoadBmpAsRaw
    add.l   #16, sp

    ; draw loading screen
    move.l  #LOADING_SPRITE_Y, -(sp)
    move.l  #LOADING_SPRITE_X, -(sp)
    move.l  #0, -(sp)
    move.l  (LoadingSpritePtr), -(sp)
    jsr     DrawSpriteSheetFrame
    add.l   #16, sp
    jsr     BlitBuffer

    jsr     SeedRandomNumber
    jsr     LoadAssets
    rts




; Initializes the game loop with a small delay and plays the background music
InitGame:
    ; initializes sub systems
    jsr     ClearInput
    jsr     UiInit
    jsr     PlayerInit
    jsr     SpawnerInit
 
    ; draw background and resets input handlers
    jsr     DrawBackground    

    ; add a small delay before starting the game loop
    move.l  #DELAY_TIME_100TH, -(sp)
    jsr     Delay
    add.l   #4, sp
    
    ; play background music
    move.l  #0, -(sp)
    move.l  #0, d0
    move.b  (BgMusicId), d0
    move.l  d0, -(sp)
    jsr     PlaySound
    add.l   #8, sp

    ; initialize loop
    move.l  #TRAP_CODE_TIME, d0
    trap    #15
    move.l  d1, (PreviousTime)
    rts




; Handle inputs and take actions. Returns non zero if ESC is pressed zero otherwise
HandleInput:
    movem.l d1-d2/a0-a1, -(sp)

    ; if ESC is pressed, exit game loop. Current menu option is returned in d0    
    jsr     ReadInput
    move.l  #FALSE, d0

    ; initialize registers
    move.l  #0, d1
    move.l  #0, d2
    lea     KeyStates, a0
    lea     PrevKeyStates, a1

    ; check for each input
    move.b  ESC_OFFSET(a0), d1
    bne     .exitGame

    move.b  SPACE_OFFSET(a0), d1
    move.b  SPACE_OFFSET(a1), d2
    eor.b   d1, d2
    beq     .return

    ; shoot
    jsr     PlayerFireArrow

    bra     .return
.exitGame:
    move.l  #TRUE, d0
    bra     .return

.return:
    movem.l (sp)+, d1-d2/a0-a1
    rts




;  ############# Draw sub routines  ###########

; Draws everything on screen and copies the bugger to screen
DrawAll:
    jsr     RepaintSection
    jsr     DisplayScore
    jsr     DrawPlayer
    jsr     DrawArrow
    jsr     DrawApples
    jsr     BlitBuffer
    rts


; Clears screen and draws the stadium background
DrawBackground:
    jsr     ClearScreen
    move.l  #0, -(sp)
    move.l  #0, -(sp)
    move.l  #0, -(sp)
    move.l  (BgSpritePtr), -(sp)
    jsr     DrawSpriteSheetFrame
    add.l   #16, sp
    rts


; Repaints the relevant section of the screen to restore the background
RepaintSection:
    move.l  #REPAINT_Y, -(sp)
    move.l  #REPAINT_X, -(sp)
    move.l  #0, -(sp)
    move.l  (RepaintSpritePtr), -(sp)
    jsr     DrawSpriteSheetFrame
    add.l   #16, sp
    rts





;  ############# Update sub routines  ###########
; arg1 = delta time
UpdateAll:
    move.l  #0, d0
    move.w  (RottenApples), d0
    cmp.l   #MAX_MISSES, d0
    bge     .gameEnd

    jsr     UpdatePlayer
    jsr     UpdateArrow
    move.l  4(sp), -(sp)
    jsr     UpdateApples
    add.l   #4, sp
    move.l  #TRUE, d0
    bra     .return
.gameEnd:
    move.l  #FALSE, d0
.return:
    rts





;  ############# Other utility sub routines  ###########


; Returns delta time in n hundredths of a second in d0
GetDeltaTime:
    movem.l d1, -(sp)
    move.l  #TRAP_CODE_TIME, d0
    trap    #15
    move.l  d1, d0
    sub.l   (PreviousTime), d0
    move.l  d1, (PreviousTime)
    movem.l (sp)+, d1
    rts



; Adds delay to game loop based on DELAY_TIME_100TH value
; arg1 = delta time
Delay:
    movem.l d0-d3, -(sp)
    move.l  4(sp), d2

    ; check if delta time is less than 1/100 th of a second
    cmp.l   #DELAY_TIME_100TH, d2
    bge     .return

    move.l  #DELAY_TIME_100TH, d3
    sub.l   d2, d3
    move.l  #TRAP_CODE_DELAY, d0
    move.l  d3, d1
    trap    #15

.return:
    movem.l (sp)+, d0-d3
    rts

