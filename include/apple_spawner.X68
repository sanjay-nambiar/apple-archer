

; apple details
APPLE_WIDTH         EQU     (40<<FRAC_BITS)
APPLE_HEIGHT        EQU     (50<<FRAC_BITS)

APPLE_START_Y       EQU     (TREE_TRUNK_TOP<<FRAC_BITS)
APPLE_START_MIN_X   EQU     (500<<FRAC_BITS)
APPLE_START_MAX_X   EQU     (600<<FRAC_BITS)

APPLE_SPAWN_X_RANGE     EQU     100
APPLE_OUT_OF_BOUNDS_X   EQU     (SCREEN_WIDTH<<FRAC_BITS)
APPLE_OUT_OF_BOUNDS_Y   EQU     ((GROUND_Y-25)<<FRAC_BITS)

APPLE_COLLISION_X               EQU     (5<<FRAC_BITS)
APPLE_COLLISION_Y               EQU     (8<<FRAC_BITS)
APPLE_COLLISION_WIDTH           EQU     (40<<FRAC_BITS)
APPLE_COLLISION_HEIGHT          EQU     (30<<FRAC_BITS)


; vector component offsets
VECTOR_X_OFFSET     EQU     0
VECTOR_Y_OFFSET     EQU     4


; offset of x and y positions within an element in apple array
APPLE_ALIVE_OFFSET          EQU     0                           ; word
APPLE_POSITION_OFFSET       EQU     (APPLE_ALIVE_OFFSET+2)      ; 2 long words
APPLE_VELOCITY_OFFSET       EQU     (APPLE_POSITION_OFFSET+8)   ; 2 long words
SIZE_OF_APPLE_OBJECT        EQU     (APPLE_VELOCITY_OFFSET+8)

MAX_APPLES                  EQU     1
SPAWN_INTERVAL              EQU     15



; Apple array variables
AppleCount      ds.w        1
Apples          ds.b        (SIZE_OF_APPLE_OBJECT*MAX_APPLES)   ; array to store upto 10 apple object details

; interval between 2 spawns
SpawnInterval   ds.l    1
SpawnHeatUp     ds.l    1

; number of apples fallen on ground
RottenApples    ds.w    1

; random seed and value generator place holder
RandomVal       ds.l    1



; initializes the apple spawner variables
SpawnerInit:
    move.l  #0, (AppleCount)
    move.l  #SPAWN_INTERVAL, (SpawnInterval)
    move.l  #0, (SpawnHeatUp)
    move.l  #0, (RottenApples)
    rts




; updates physics for existing apples
; arg1 = delta time
UpdateApples:
    movem.l d1-d5/a0, -(sp)

    move.l  #0, d5
    move.w  (AppleCount), d5
    beq     .return

    lea     Apples, a0
    sub.w   #1, d5
.loop:
    ; d1 and d2 are velocities
    move.l  APPLE_VELOCITY_OFFSET+VECTOR_X_OFFSET(a0), d1
    move.l  APPLE_VELOCITY_OFFSET+VECTOR_Y_OFFSET(a0), d2
    ; apply gravity
    add.l   GRAVITY, d2
    move.l  d2, APPLE_VELOCITY_OFFSET+VECTOR_Y_OFFSET(a0)

    ;d3 and d4 are positions
    move.l  APPLE_POSITION_OFFSET+VECTOR_X_OFFSET(a0), d3
    move.l  APPLE_POSITION_OFFSET+VECTOR_Y_OFFSET(a0), d4
    ; update positions
    add.l   d1, d3
    add.l   d2, d4
    move.l  d3, APPLE_POSITION_OFFSET+VECTOR_X_OFFSET(a0)
    move.l  d4, APPLE_POSITION_OFFSET+VECTOR_Y_OFFSET(a0)

    ; check out of bounds
.checkRightBound:
    cmp.l   #APPLE_OUT_OF_BOUNDS_X, d3
    blt     .checkBottomBound
    bra     .checkArrowHit
.checkBottomBound:
    cmp.l   #APPLE_OUT_OF_BOUNDS_Y, d4
    blt     .checkArrowHit

    ; apple is out of bounds
    move.w  #FALSE, APPLE_ALIVE_OFFSET(a0)
    sub.w   #1, (AppleCount)
    add.w   #1, (RottenApples)

    ; play sound effect
    move.l  #0, -(sp)
    move.l  #0, d4
    move.b  (MissSoundId), d4
    move.l  d4, -(sp)
    jsr     PlaySound
    add.l   #8, sp

    bra     .endIteration

.checkArrowHit:
    move.l  a0, -(sp)
    move.l  d4, -(sp)
    move.l  d3, -(sp)
    jsr     HandleAppleCollision
    add.l   #12, sp
.endIteration:
    ; move a0 to next apple's address
    add.l   #SIZE_OF_APPLE_OBJECT, a0
    dbf     d5, .loop
.return:
    ; call spawn apple passing the delta time
    move.l  24+4(sp), -(sp)
    jsr     SpawnApple
    add.l   #4, sp

    movem.l (sp)+, d1-d5/a0
    rts





; handle collisions with arrow
; arg1 = apple x position
; arg2 = apple y position
; arg3 = apple address
HandleAppleCollision:
    movem.l d0-d5/a0, -(sp)

    move.l  #0, d0
    move.w  (IsArrowAlive), d0
    beq     .return

    ; move position x and y of apple into d3 and d4
    move.l  28+4(sp), d3
    move.l  28+8(sp), d4
    move.l  28+12(sp), a0

    ; arrow positions in d1 and d2
    move.l  (ArrowPositionX), d1
    add.l   #ARROW_COLLISION_X, d1
    move.l  (ArrowPositionY), d2
    add.l   #ARROW_COLLISION_Y, d2

    ; apple positions in d3 and d4
    add.l   #(APPLE_COLLISION_X+(APPLE_COLLISION_WIDTH/2)), d3
    add.l   #(APPLE_COLLISION_Y+(APPLE_COLLISION_HEIGHT/2)), d4

    ; find apple collison box centre - arrow tip
    ; absolute value of this distance should be less than or equal to half width / height
    sub.l   d1, d3
    ; abs(x) = (x XOR y) - y, where y = x >>> 31
    move.l  d3, d5                      ; d3 = x
    asr.l   #8, d5
    asr.l   #8, d5
    asr.l   #8, d5
    asr.l   #7, d5                      ; d2 = y = x >>> 31
    eor.l   d5, d3                      ; d3 = x XOR y
    sub.l   d5, d3                      ; d3 = (x XOR y) - y = abs(x)

    ; repeat for y
    sub.l   d2, d4
    move.l  d4, d5
    asr.l   #8, d5
    asr.l   #8, d5
    asr.l   #8, d5
    asr.l   #7, d5
    eor.l   d5, d4
    sub.l   d5, d4

.checkX:
    cmp.l   #(APPLE_COLLISION_WIDTH/2), d3
    bgt     .return
.checkY:
    cmp.l   #(APPLE_COLLISION_HEIGHT/2), d4
    bgt     .return
.hasCollided:
    move.w  #FALSE, APPLE_ALIVE_OFFSET(a0)
    sub.w   #1, (AppleCount)
    add.l   #1, (Score)

    ; play sound effect
    move.l  #0, -(sp)
    move.l  #0, d0
    move.b  (HitSoundId), d0
    move.l  d0, -(sp)
    jsr     PlaySound
    add.l   #8, sp

.return:
    movem.l (sp)+, d0-d5/a0
    rts





; Spawns a new apple if it is time to spawn one and if there is room for one more
; arg1 = delta time
SpawnApple:
    movem.l d0-d2/a0, -(sp)
    add.l   #16, sp

    ; check if array is full
    move.l  #0, d1
    move.w  (AppleCount), d1
    cmp.w   #MAX_APPLES, d1
    bge     .return

    ; check if it is time to spawn a new apple
    move.l  4(sp), d0
    add.l   (SpawnHeatUp), d0
    move.l  d0, (SpawnHeatUp)
    cmp.l   (SpawnInterval), d0
    blt     .return

    move.l  #0, (SpawnHeatUp)
.createApple:
    ; get a random x pos for new apple
    jsr     GetRandomByte
    ext.w   d0
    ext.l   d0

    cmp.w   #APPLE_SPAWN_X_RANGE, d0
    ble     .create
    sub.l   #APPLE_SPAWN_X_RANGE, d0
.create:
    ; seek the empty slot in the array
    lea     Apples, a0
    mulu    #SIZE_OF_APPLE_OBJECT, d1
    add.l   d1, a0

    ; create apple
    move.w  #TRUE, APPLE_ALIVE_OFFSET(a0)
    ; set position
    lsl.l   #FRAC_BITS, d0
    add.l   #APPLE_START_MIN_X, d0
    move.l  d0, APPLE_POSITION_OFFSET+VECTOR_X_OFFSET(a0)
    move.l  #APPLE_START_Y, APPLE_POSITION_OFFSET+VECTOR_Y_OFFSET(a0)
    ; set velocity
    move.l  #0, APPLE_VELOCITY_OFFSET+VECTOR_X_OFFSET(a0)
    move.l  #GRAVITY, APPLE_VELOCITY_OFFSET+VECTOR_Y_OFFSET(a0)

    add.w   #1, (AppleCount)

    ; play sound effect
    move.l  #0, -(sp)
    move.l  #0, d0
    move.b  (FallSoundId), d0
    move.l  d0, -(sp)
    jsr     PlaySound
    add.l   #8, sp

.return:
    sub.l   #16, sp
    movem.l (sp)+, d0-d2/a0
    rts





DrawApples:
    movem.l d0-d4/a0, -(sp)

    move.l  #0, d0
    move.w  (AppleCount), d0
    beq     .return

    lea     Apples, a0
    sub.w   #1, d0
.loop:
    ;d1 and d2 are positions
    move.l  APPLE_POSITION_OFFSET+VECTOR_X_OFFSET(a0), d1
    move.l  APPLE_POSITION_OFFSET+VECTOR_Y_OFFSET(a0), d2
    lsr.l   #FRAC_BITS, d1
    lsr.l   #FRAC_BITS, d2

    ; draw the apple
    move.l  d2, -(sp)
    move.l  d1, -(sp)
    move.l  #0, -(sp)
    move.l  (AppleSpritePtr), -(sp)
    jsr     DrawSpriteSheetFrame
    add.l   #16, sp
.endIteration:
    ; move a0 to next apple's address
    add.l   #SIZE_OF_APPLE_OBJECT, a0
    dbf     d0, .loop
.return:
    movem.l (sp)+, d0-d4/a0
    rts





; Inits random number generator with a seed
SeedRandomNumber:
    move.b  #TRAP_CODE_TIME, d0
    TRAP    #15
    move.l  d1, RandomVal
    rts



; returns random byte in d0
GetRandomByte:
    movem.l d1-d2, -(sp)
    move.l  RandomVal, d0
    moveq   #$AF-$100, d1
    moveq   #18, d2
.ninc0:
    add.l   d0, d0
    bcc     .ninc1
    eor.b   d1, d0
.ninc1:
    dbf d2, .ninc0
    move.l  d0, RandomVal

    movem.l (sp)+, d1-d2
    rts



