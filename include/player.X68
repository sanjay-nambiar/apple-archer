
; some initial position constants
WORLD_WIDTH 			EQU 	(SCREEN_WIDTH<<FRAC_BITS)
WORLD_HEIGHT 			EQU 	(SCREEN_HEIGHT<<FRAC_BITS)

PLAYER_X				EQU		10
PLAYER_Y				EQU		350
ARROW_START_X_OFFSET 	EQU 	128
ARROW_START_Y_OFFSET 	EQU 	40
ARROW_VELOCITY_X 		EQU 	(20<<FRAC_BITS)

ARROW_COLLISION_X 		EQU 	(50<<FRAC_BITS)
ARROW_COLLISION_Y 		EQU 	(2<<FRAC_BITS)

LOOPS_PER_FRAME 		EQU 	5


; player states
PLAYER_IDLE 	EQU		0
PLAYER_SHOOT 	EQU		1

; no of frames in the shoot animation 
SHOOT_FRAMES 	EQU		3



; Player State and animation info
PlayerState 		ds.w 	1
PlayerSpriteFrame	ds.w 	1

; Arrow physics properties
IsArrowAlive 		ds.w 	1
ArrowPositionX 		ds.l 	1
ArrowPositionY 		ds.l 	1

; variable to alter speed of animations
FrameDrawCount 		ds.w 	1




; Initialize player variables
PlayerInit:
	move.w #PLAYER_IDLE, (PlayerState)
	move.w #PLAYER_IDLE, (PlayerSpriteFrame)
	move.w #FALSE, (IsArrowAlive)
	move.l #0, (ArrowPositionX)
	move.l #0, (ArrowPositionY)
	move.w #0, (FrameDrawCount)
	rts



; Sets player state to shoot, effectively firing an arrow
PlayerFireArrow:
	movem.l d0, -(sp)

	; Fire an arrow only if there is no arrow in the screen
	move.l 	#0, d0
	move.w 	(IsArrowAlive), d0	
	bne 	.return

	; fire only if player was idle
	move.w 	#PLAYER_SHOOT, (PlayerState)
	move.w 	#TRUE, (IsArrowAlive)
	move.l 	#((PLAYER_X+ARROW_START_X_OFFSET)<<FRAC_BITS), (ArrowPositionX)
	move.l 	#((PLAYER_Y+ARROW_START_Y_OFFSET)<<FRAC_BITS), (ArrowPositionY)	
.return:
	movem.l (sp)+, d0
	rts


; Draws the players current animation frame
DrawPlayer:
	movem.l d0, -(sp)

	move.l 	#0, d0
	move.w 	(PlayerSpriteFrame), d0

	move.l  #PLAYER_Y, -(sp)
    move.l  #PLAYER_X, -(sp)
    move.l  d0, -(sp)
    move.l  (ArcherSpritePtr), -(sp)
    jsr     DrawSpriteSheetFrame
    add.l   #16, sp

    movem.l (sp)+, d0
	rts



; Draws the arrow if its alive
DrawArrow:
	movem.l d0-d1, -(sp)

	move.l 	#0, d0
	move.w 	(IsArrowAlive), d0
	beq 	.return

	; convert position from fixed point to normal
	move.l  (ArrowPositionY), d0
    move.l  (ArrowPositionX), d1
    asr.l 	#FRAC_BITS, d0
    asr.l 	#FRAC_BITS, d1

  	move.l 	d0, -(sp)
    move.l  d1, -(sp)
    move.l 	#0, -(sp)
    move.l  (ArrowSpritePtr), -(sp)
    jsr     DrawSpriteSheetFrame
    add.l   #16, sp
.return:
	movem.l (sp)+, d0-d1
	rts



; Updates the animation and phsycis for player
UpdatePlayer:
	movem.l d0-d1, -(sp)

	; get current animation frame id
	move.l 	#0, d1
	move.w 	(PlayerSpriteFrame), d1

	; If idle state, don't update animation frame
	move.l 	#0, d0
	move.w 	(PlayerState), d0
	beq 	.return

	; if shoot state, advance animation frame
	move.l 	#0, d0
	move.w 	(FrameDrawCount), d0
	cmp.w 	#LOOPS_PER_FRAME, d0
	blt 	.return

	add.w 	#1, d1
	move.w 	d1, (PlayerSpriteFrame)
	move.w 	#0, (FrameDrawCount)

	; check if frame is reached the last frame. If yes, set state and frame to IDLE
	cmp.w 	#(PLAYER_SHOOT+SHOOT_FRAMES), d1
	blt 	.return
	move.w 	#PLAYER_IDLE, d1
	move.w 	d1, (PlayerSpriteFrame)
	move.w 	#PLAYER_IDLE, (PlayerState)

.return:
	; increment the frame draw counter
    add.w 	#1, (FrameDrawCount)
    movem.l (sp)+, d0-d1
	rts



; Simulate arrow physics
UpdateArrow:
	movem.l d0-d1, -(sp)

	; skip if arrow is not alive
	move.l 	#0, d0
	move.w 	(IsArrowAlive), d0
	beq 	.return

	;update position
	add.l 	#ARROW_VELOCITY_X, (ArrowPositionX)
	
	; check out of bounds
	move.l 	(ArrowPositionX), d0
	cmp.l 	#WORLD_WIDTH, d0
	blt 	.return

	; arrow is out of bounds
	move.l 	#FALSE, (IsArrowAlive)
.return:
	movem.l (sp)+, d0-d1
	rts
