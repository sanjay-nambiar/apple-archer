

; offsets to individual fields in sprite details structure
SPRITE_DETAILS_FILENAME_OFFSET          EQU         0
SPRITE_DETAILS_POINTER_OFFSET           EQU         4
SPRITE_DETAILS_DIMENSION_OFFSET         EQU         8
SPRITE_DETAILS_OBJECT_SIZE              EQU         12

AUDIO_DETAILS_FILENAME_OFFSET           EQU         0
AUDIO_DETAILS_ID_OFFSET                 EQU         4
AUDIO_DETAILS_OBJECT_SIZE               EQU         8


; Loads game assets
LoadAssets:
    movem.l d0-d1/a0, -(sp)

    jsr     CloseAllFiles
    ; initialize loop
    lea     AllSpriteDetails, a0
.loadSpriteLoop:
    ; get sprite frame width in d0 and height in d1
    move.l  SPRITE_DETAILS_DIMENSION_OFFSET(a0), d0
    move.w  d0, d1
    ext.l   d1
    swap.w  d0
    ext.l   d0

    ; load and parse image
    move.l  d1, -(sp)
    move.l  d0, -(sp)
    move.l  SPRITE_DETAILS_POINTER_OFFSET(a0), -(sp)
    move.l  SPRITE_DETAILS_FILENAME_OFFSET(a0), -(sp)
    jsr     LoadBmpAsRaw
    add.l   #16, sp

    ; move array pointer to sprite details to next element in the array
    add.l   #SPRITE_DETAILS_OBJECT_SIZE, a0

    ; loop back if there more sprites to load
    cmp.l   #AllSpriteDetailsEnd, a0
    blt     .loadSpriteLoop


    ; initialize loop
    lea     AllAudio, a0
.loadAudioLoop:
    move.l  AUDIO_DETAILS_ID_OFFSET(a0), a1

    ; load menu music
    move.l  AUDIO_DETAILS_FILENAME_OFFSET(a0), -(sp)
    jsr     LoadWavFile
    move.b  d0, (a1)
    add.l   #4, sp

    ; move array pointer to audio details to next element in the array
    add.l   #AUDIO_DETAILS_OBJECT_SIZE, a0

    ; loop back if there more audio to load
    cmp.l   #AllAudioEnd, a0
    blt     .loadAudioLoop

    jsr     CloseAllFiles

    movem.l (sp)+, d0-d1/a0
    rts



; Loads a BMP image from file to memory and stores the starting memory address to a pointer
; Updates next free memory slot's address to FreeMemStartPtr
; arg1 = file name
; arg2 = address of variable to point to image data in memory
; arg3 = frame width
; arg4 = frame height
LoadBmpAsRaw:
    movem.l d0-d2/a0-a2, -(sp)

    move.l  28(sp), a0
    move.l  32(sp), a1
    move.l  36(sp), d1
    move.l  40(sp), d2

    ; call ReadFile to read the BMP data to TempMemory
    move.l  #TempMemoryBlock1, -(sp)
    move.l  a0, -(sp)
    jsr     ReadFile
    ; TODO: d0 has file size here. Error check to see if it is zero
    add.l   #8, sp

    ; load and parse background BMP
    move.l  #TempMemoryBlock2, -(sp)
    move.l  #TempMemoryBlock1, -(sp)
    jsr     ParseBMP
    add.l   #8, sp

    move.l  (FreeMemStartPtr), a2                           ; get address of free memory start
    move.l  a2, (a1)                                        ; move address of ProgramHeap variable to sprite ptr variable

    ; extract sprite frames from the raw image
    move.l  a2, -(sp)
    move.l  d2, -(sp)
    move.l  d1, -(sp)
    move.l  #TempMemoryBlock2, -(sp)
    jsr     ImageToSpriteFrames
    add.l   #16, sp

    add.l   d0, (FreeMemStartPtr)                           ; update new free memory start address

    movem.l (sp)+, d0-d2/a0-a2
    rts





; All the sprites to be imported in load assets should be declared here
; The first long word is the address of file name variable
; Second long word is address of sprite pointer variable
; Third long word has width of the sprite frame in upper word and height of sprite frame in lower word
AllSpriteDetails:
MessageSprite               dc.l    MessageSpriteBMP, MessageSpritePtr, ((640<<16+480))
BgSprite                    dc.l    BgSpriteBMP, BgSpritePtr, ((640<<16)+480)
RepaintSprite               dc.l    RepaintSpriteBMP, RepaintSpritePtr, ((640<<16)+252)
ArcherSprite                dc.l    ArcherSpriteBMP, ArcherSpritePtr, ((128<<16)+106)
AppleSprite                 dc.l    AppleSpriteBMP, AppleSpritePtr, ((30<<16)+30)
ArrowSprite                 dc.l    ArrowSpriteBMP, ArrowSpritePtr, ((50<<16)+5)
EndSprite                   dc.l    EndSpriteBMP, EndSpritePtr, ((480<<16)+400)
AllSpriteDetailsEnd:

; All the audio clips to be imported
AllAudio:
MenuMusic                   dc.l    MenuMusicFile, MenuMusicId
BgMusic                     dc.l    BgMusicFile, BgMusicId
FallSound                   dc.l    FallSoundFile, FallSoundId
FireSound                   dc.l    FireSoundFile, FireSoundId
HitSound                    dc.l    HitSoundFile, HitSoundId
MissSound                   dc.l    MissSoundFile, MissSoundId
AllAudioEnd:


; Individual image details
; Loading
LoadingSpriteBMP            dc.b    'images/loading.bmp', 0
LoadingSpritePtr            ds.l    1

; Menu
MessageSpriteBMP            dc.b    'images/message.bmp', 0
MessageSpritePtr            ds.l    1

; Background
BgSpriteBMP                 dc.b    'images/background.bmp', 0
BgSpritePtr                 ds.l    1
RepaintSpriteBMP            dc.b    'images/repaint.bmp', 0
RepaintSpritePtr            ds.l    1


; Archer
ArcherSpriteBMP             dc.b    'images/archer.bmp', 0
ArcherSpritePtr             ds.l    1

; Apple
AppleSpriteBMP              dc.b    'images/apple.bmp', 0
AppleSpritePtr              ds.l    1

; Arrow
ArrowSpriteBMP              dc.b    'images/arrow.bmp', 0
ArrowSpritePtr              ds.l    1

; end scene
EndSpriteBMP                dc.b    'images/end.bmp', 0
EndSpritePtr                ds.l    1


; Individual audio details
MenuMusicFile               dc.b    'audio/title-theme.wav', 0
MenuMusicId                 ds.b    1
BgMusicFile                 dc.b    'audio/game-loop.wav', 0
BgMusicId                   ds.b    1

FallSoundFile               dc.b    'audio/fall.wav', 0
FallSoundId                 ds.b    1
FireSoundFile               dc.b    'audio/fire.wav', 0
FireSoundId                 ds.b    1
HitSoundFile                dc.b    'audio/hit.wav', 0
HitSoundId                  ds.b    1
MissSoundFile               dc.b    'audio/miss.wav', 0
MissSoundId                 ds.b    1


; The heap memory and tracking variables

; initialize free variable with starting address of ProgramHeap
FreeMemStartPtr             dc.l    ProgramHeap

; 11 MB of memory
ProgramHeap                 ds.b    (1024*1024*11)


; four 1 MB blocks each of temp memory (4 MB in total
TempMemoryBlock1            ds.b    (1024*1024)
TempMemoryBlock2            ds.b    (1024*1024)
TempMemoryBlock3            ds.b    (1024*1024)
TempMemoryBlock4            ds.b    (1024*1024)

