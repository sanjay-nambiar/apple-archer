
; Sound utilities

TRAP_CODE_PLAY_WAV_FILE                 EQU     73
TRAP_CODE_LOAD_SOUND                    EQU     74
TRAP_CODE_CONTROL_PLAYER                EQU     77



; tracks next available sound id
NextSoundId      dc.w        1


; Plays audio from a wav file using directX audio player
; arg1 = address of null terminated file name string
; returns non zero in d0.w if sound is played
PlayWavFile:
    movem.l a1, -(sp)
    move.l  8(sp), a1
    move.l  #TRAP_CODE_PLAY_WAV_FILE, d0
    trap    #15
    ext.l   d0
    movem.l (sp)+, a1
    rts


; Loads a wav file into sound memory and map it to an id
; arg1 = address of null terminated file name string
; returns sound Id in d0 if successful. 0 if unsuccessful
LoadWavFile:
    movem.l d1/a1, -(sp)
    ; Only 255 sounds can be loaded at a time
    move.w (NextSoundId), d1
    cmp.w   #256, d1
    beq     .errorReturn

    ; load sound and increment NextSoundId
    move.l  12(sp), a1
    move.l  #TRAP_CODE_LOAD_SOUND, d0
    trap    #15
    move.w  d1, d0
    ext.l   d0
    add.w   #1, (NextSoundId)

    movem.l (sp)+, d1/a1
    rts
.errorReturn:
    ; moving -1 to d0 to indicate error
    move.l  #0, d0
    movem.l (sp)+, d1/a1
    rts


; Play a sound with an id already loaded into the directX sound memory
; arg1 = sound id
; arg2 = boolean indicating whether to loop or not (pass 0 or 1)
; returns non zero if successful or zero if sound is not played in d0.w
PlaySound:
    movem.l d1-d2, -(sp)
    move.l  12(sp), d1
    move.l  16(sp), d2
    move.l  #TRAP_CODE_CONTROL_PLAYER, d0
    trap    #15
    ext.l   d0
    movem.l (sp)+, d1-d2
    rts


; Stops all sounds that are playing through the directX audio player
StopAllSounds:
    movem.l d0-d2, -(sp)
    move.l  #3, d2
    move.l  #TRAP_CODE_CONTROL_PLAYER, d0
    trap    #15
    movem.l (sp)+, d0-d2
    rts


; Stops a sound with a given id that is playing through the directX audio player
; arg1 = id of the sound to stop
; returns 0 on bad sound id, non zero on success in d0.w
StopSound:
    movem.l d1-d2, -(sp)
    move.l  12(sp), d1
    move.l  #2, d2
    move.l  #TRAP_CODE_CONTROL_PLAYER, d0
    trap    #15
    ext.l   d0
*~Font name~Courier New~
    movem.l (sp)+, d1-d2
    rts


; Resets the next soundId slot to 1 and stops playback of all sounds
ClearAllSounds:
    move.w  #1, (NextSoundId)
    jsr     StopAllSounds
    rts

