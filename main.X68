*---------------------------------------------------------------
* Title      : Apple Archer
* Written by : Sanjay Nambiar
* Date       : 14 Oct 2016
* Description: A apple shooting archer game written for Easy68K 
*---------------------------------------------------------------


; World constants
SCREEN_WIDTH            EQU         640
SCREEN_HEIGHT           EQU         480
FRAC_BITS			    EQU 		8
GRAVITY                 EQU         (5<<FRAC_BITS)


; boolean values
TRUE                    EQU         $FF
FALSE                   EQU         $00




START   ORG    $1000

Main:
    move.l  #0, d0
    jsr     Loading
.menu:
    ; Display menu and wait for an option from user
    jsr     ShowMenu
    ; run game loop
    jsr     GameLoop
    ; show score screen
    jsr     ShowEndScreen
    bra     .menu
.gameEnd:
    STOP    #$2000




; The game loop
GameLoop:
    jsr     InitGame
.loop:
    ; get delta time in d2
    jsr     GetDeltaTime
    move.l  d0, d2

    jsr     HandleInput
    tst.l   d0
    bne     .return

.update:
    move.l  d2, -(sp)
    jsr     UpdateAll
    add.l   #4, sp
    tst.l   d0
    beq     .return

    jsr     DrawAll

    move.l  d2, -(sp)
    jsr     Delay
    add.l   #4, sp

    bra     .loop

.return:
    jsr     ExitGameLoop
    rts



; Performs tasks which are required prior to exiting game the loop
ExitGameLoop:
    ; stop background music
    move.l  #0, d0
    move.b  (BgMusicId), d0
    move.l  d0, -(sp)
    jsr     StopSound
    add.l   #4, sp
    rts


; Last update time
PreviousTime        ds.l        1


    INCLUDE "include/game_manager.X68"
    INCLUDE "include/apple_spawner.X68"
    INCLUDE "include/player.X68"
    INCLUDE "include/input_manager.X68"
    INCLUDE "include/game_input.X68"
    INCLUDE "include/ui.X68"
    INCLUDE "include/seven_segment.X68"
    INCLUDE "include/animation.X68"
    INCLUDE "include/sound.X68"
    INCLUDE "include/io.X68"
    INCLUDE "include/parse_bmp.X68"
    INCLUDE "include/asset_loader.X68"


    END    START


