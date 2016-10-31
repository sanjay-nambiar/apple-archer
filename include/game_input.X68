

; Keycodes
ESC_KEYCODE             EQU		$1B
SPACE_KEYCODE           EQU		$20
ENTER_KEYCODE           EQU		$0D
UP_KEYCODE              EQU		$26

MAX_KEY_STATE_LONGS     EQU     $1

; Offsets into keystates / prev keystates array
ESC_OFFSET              EQU     0
SPACE_OFFSET            EQU		1
ENTER_OFFSET            EQU		2
UP_OFFSET               EQU		3



; Keys and KeyStates arrays
Keys            dc.l    ((ESC_KEYCODE<<24)+(SPACE_KEYCODE<<16)+(ENTER_KEYCODE<<8)+UP_KEYCODE)
KeyStates       dc.b    $00, $00, $00, $00
PrevKeyStates   dc.b    $00, $00, $00, $00




; Reads the input key states for the game
ReadInput:
	move.l  #PrevKeyStates, -(sp)
    move.l  #KeyStates, -(sp)
    move.l  #MAX_KEY_STATE_LONGS, -(sp)
    move.l  #Keys, -(sp)
    jsr     ReadKeyStates
    add.l   #16, sp
    rts



; Clears input state arrays
ClearInput:
    move.l  #0, (KeyStates)
    move.l  #0, (PrevKeyStates)
    rts

