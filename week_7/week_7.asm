    ;
    ;   iNES HEADER
    ;
    .segment "HEADER"
    .byte "NES", $1A
    .byte $01
    .byte $01
    .byte %00000001

    ;
    ;   VECTORS
    ;
    .segment "VECTORS"
    .word NMI
    .word RESET1
    .word 0

    ;
    ;   GRAPHICS TILES
    ;
    .segment "TILES"
    .incbin "../mario.chr"

    ;
    ;   PALETTE
    ;
    .segment "PALETTE"
    PALETTES:
        .byte $0F,$05,$26,$30, $0F,$13,$23,$33, $0F,$16,$27,$18, $0F,$20,$27,$19
        .byte $0F,$16,$27,$18, $0F,$20,$27,$19, $0F,$01,$02,$03, $0F,$04,$05,$06

    ;
    ;   SPRITE
    ;   Y, Tile, Attributes, X
    ;
    .segment "SPRITE"
    SPRITES:
        .byte $80, $3A, $00, $40
        .byte $80, $37, $00, $48
        .byte $88, $4F, $00, $40
        .byte $88, $4F, $40, $48

        .byte $80, $3A, $01, $C0
        .byte $80, $37, $01, $C8
        .byte $88, $4F, $01, $C0
        .byte $88, $4F, $41, $C8

    ;
    ;   BACKGROUND NAMETABLES AND ATTRIBUTES
    ;
    .segment "BACKGROUND"
    TITLE_SCREEN_BACKGROUND:
        .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
        .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24

        .byte $25, $26, $27, $25, $26, $27, $25, $26, $27, $25, $26, $16, $0A, $1B, $12, $18
        .byte $24, $15, $1E, $12, $10, $12, $25, $26, $27, $25, $26, $27, $25, $26, $27, $25

        .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
        .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24

        .byte $25, $26, $27, $25, $26, $27, $25, $26, $27, $25, $26, $19, $1B, $0E, $1C, $1C
        .byte $24, $1C, $1D, $0A, $1B, $1D, $25, $26, $27, $25, $26, $27, $25, $26, $27, $25

    TITLE_SCREEN_ATTRIBUTES:
        .byte %00000000, %00000000, %00000000, %00000000, %01010101, %01010101, %01010101, %01010101

    ;
    ;   SET UP VARIABLES IN RAM
    ;
    .segment "RAM"
    score1:     .res 1 ; player 1 score
    score2:     .res 1 ; player 2 score
    player1:    .res 1 ; player 1 controller state
    player2:    .res 1 ; player 2 controller state
    ; controller variables
    current_control:    .res 1 ; holds the players controller state
    player_offset_y:    .res 1 ; holds the OAM address for the players first sprite's Y position
    player_offset_x:    .res 1 ; holds the OAM address for the players first sprite's X position
    ; game engine variables
    gamestate:      .res 1 ; current state of the game
    mario_speed_x:  .res 1 ; horizontal speed for mario
    mario_speed_y:   .res 1 ; vertical speed for mario
    luigi_speed_x:  .res 1 ; horizontal speed for mario
    luigi_speed_y:   .res 1 ; vertical speed for mario
    ; character variables
    mario_pos_x:    .res 1 ; mario current X position (top left)
    mario_pos_y:    .res 1 ; mario current Y position (top left)
    luigi_pos_x:    .res 1 ; luigi X position (top left)
    luigi_pos_y:    .res 1 ; luigi Y position (top left)

    ;
    ;   CODE
    ;
    .segment "CODE"
    ;
    ;   SET UP VARIABLES IN ROM
    ;   these variables will define boundaries of the pong screen
    ;
    ; game engine constants
    GAME_START  = $00
    GAME_PLAY   = $01
    GAME_END    = $02
    CHAR_LEFT   = $00
    CHAR_RIGHT  = $01
    CHAR_UP     = $02
    CHAR_DOWN   = $03
    SPEED_X     = $02
    SPEED_Y     = $02
    ; control constants
    A_BUTTON    = $80
    B_BUTTON    = $40
    SELECT      = $20
    START       = $10
    UP          = $08
    DOWN        = $04
    LEFT        = $02
    RIGHT       = $01
    ; game area constants
    RIGHTWALL   = $02
    TOPWALL     = $20
    BOTTOMWALL  = $D8
    LEFTWALL    = $F6

    RESET1:
        SEI 
        CLD 

        LDX #$40
        STX $4017   ; disable APU frame IRQ

        LDX #$FF
        TXS
        INX
        STX $2000   ; disable NMI
        STX $2001   ; disable rendering
        STX $4010   ; disable DMC IRQs

        JSR VBLANKWAIT

    CLRMEM:
        LDA #$00
        STA $0000, X 
        STA $0100, X 
        STA $0300, X 
        STA $0400, X 
        STA $0500, X 
        STA $0600, X 
        STA $0700, X 
        LDA #$FE
        STA $0200, X 
        INX 
        BNE CLRMEM
        JSR VBLANKWAIT
    
    RESET2:
        JSR READY_PPU_PALETTE
        JSR READY_PPU_TITLE_SCREEN_BACKGROUND
        JSR READY_PPU_TITLE_SCREEN_ATTRIBUTE
        JSR LOAD_SPRITES

        LDA #%10010000  ; enable NMI, sprites from pattern table 0, background from pattern table 1
        STA $2000

        LDA #%00011110  ; enable sprites, background
        STA $2001

        LDA #GAME_START
        STA gamestate

        JMP FOREVER

    VBLANKWAIT:
        BIT $2002
        BPL VBLANKWAIT
        RTS

    READY_PPU_PALETTE:
        LDA $2002   ; reset high/low latch to high
        LDA #$3F 
        STA $2006
        LDA #$00
        STA $2006

        LDX #$00
    LOAD_PALETTE_LOOP:
        LDA PALETTES, X 
        STA $2007 
        INX 
        CPX #$20
        BNE LOAD_PALETTE_LOOP
        RTS

    READY_PPU_TITLE_SCREEN_BACKGROUND:
        LDA $2002
        LDA #$20
        STA $2006
        LDA #$00
        STA $2006

        LDX #$00
    LOAD_TITLE_SCREEN_BACKGROUND_LOOP:
        LDA TITLE_SCREEN_BACKGROUND, X 
        STA $2007
        INX 
        CPX #$80
        BNE LOAD_TITLE_SCREEN_BACKGROUND_LOOP
        RTS

    READY_PPU_TITLE_SCREEN_ATTRIBUTE:
        LDA $2002
        LDA #$23
        STA $2006
        LDA #$C0
        STA $2006

        LDX #$00
    LOAD_TITLE_SCREEN_ATTRIBUTE_LOOP:
        LDA TITLE_SCREEN_ATTRIBUTES, X 
        STA $2007
        INX
        CPX #$08
        BNE LOAD_TITLE_SCREEN_ATTRIBUTE_LOOP
        RTS

    LOAD_SPRITES:
        LDX #$00
    LOAD_SPRITES_LOOP:
        LDA SPRITES, X 
        STA $0200, X 
        INX 
        CPX #$20
        BNE LOAD_SPRITES_LOOP
        ; store character starting positions
        LDA $0200
        STA mario_pos_y
        LDA $0203
        STA mario_pos_x
        LDA $0210
        STA luigi_pos_y
        LDA $0213   
        STA luigi_pos_x
        RTS

    FOREVER:
        JMP FOREVER

    NMI:
        LDA #$00
        STA $2003

        LDA #$02
        STA $4014  ; DMA all of the sprites from $0200 - $02FF

        JSR READY_CONTROLLERS
        JSR READ_PLAYER_1_INPUT
        JSR READ_PLAYER_2_INPUT

        JSR GAME_ENGINE

        RTI

    ; ================================================================== ;
    ;                          GAME ENGINE CODE                          ;
    ; ================================================================== ;
    GAME_ENGINE:
        LDA gamestate
        CMP #GAME_START
        BEQ ENGINE_TITLE

        LDA gamestate
        CMP #GAME_PLAY
        BEQ ENGINE_PLAYING

        LDA gamestate
        CMP #GAME_END
        BEQ ENGINE_OVER

    GAME_ENGINE_DONE:
        JSR UPDATE_SPRITES

        RTS

    ENGINE_TITLE:
        JMP GAME_ENGINE_DONE
    ENGINE_PLAYING:
        JMP GAME_ENGINE_DONE
    ENGINE_OVER:
        JMP GAME_ENGINE_DONE
    
    UPDATE_SPRITES:
        RTS

    ; ================================================================== ;
    ;                          READ CONTROLLERS                          ;
    ; ================================================================== ;
    READY_CONTROLLERS:
        LDA #$01
        STA $4016
        LDA #$00
        STA $4016   ; latch controller buttons

        LDX #$00
        STX player1
        STX player2 

        JSR READ_PLAYER_1_CONTROLLER
        LDX #$00
        JSR READ_PLAYER_2_CONTROLLER

        RTS

    READ_PLAYER_1_CONTROLLER:
        CLC
        LDA $4016
        LSR             ; shift bit 0 of A into the carry flag
        ROL player1     ; shift player1 over one bit and put the carry flag there
        INX
        CPX #$08
        BNE READ_PLAYER_1_CONTROLLER
        RTS

    READ_PLAYER_2_CONTROLLER:
        CLC
        LDA $4017
        LSR             ; same as above
        ROL player2 
        INX
        CPX #$08
        BNE READ_PLAYER_2_CONTROLLER
        RTS

    READ_PLAYER_1_INPUT: 
        LDA player1
        STA current_control
        LDA #$00
        STA player_offset_y
        LDA #$03
        STA player_offset_x

        JSR READ_A
        JSR READ_B 
        JSR READ_SELECT
        JSR READ_START
        JSR READ_LEFT  
        JSR READ_RIGHT  
        JSR READ_UP  
        JSR READ_DOWN 
        RTS
    
    READ_PLAYER_2_INPUT:
        LDA player2
        STA current_control
        LDA #$10
        STA player_offset_y
        LDA #$13
        STA player_offset_x 

        JSR READ_A
        JSR READ_B 
        JSR READ_SELECT
        JSR READ_START
        JSR READ_LEFT  
        JSR READ_RIGHT  
        JSR READ_UP  
        JSR READ_DOWN  
        RTS

    ; ================================================================== ;
    ;                          CHECK INPUT                               ;
    ; ================================================================== ;
    READ_A:
        LDA current_control
        AND #A_BUTTON
        BEQ READ_A_DONE 
        JSR A_PRESSED
    READ_A_DONE:
        RTS

    READ_B:
        LDA current_control
        AND #B_BUTTON
        BEQ READ_B_DONE 
        JSR B_PRESSED
    READ_B_DONE:
        RTS

    READ_SELECT:
        LDA current_control
        AND #SELECT
        BEQ READ_SELECT_DONE 
        JSR SELECT_PRESSED
    READ_SELECT_DONE:
        RTS

    READ_START:
        LDA current_control
        AND #START
        BEQ READ_START_DONE 
        JSR START_PRESSED
    READ_START_DONE:
        RTS

    READ_UP:
        LDA current_control
        AND #UP
        BEQ READ_UP_DONE 
        JSR UP_PRESSED
    READ_UP_DONE:
        RTS

    READ_DOWN:
        LDA current_control
        AND #DOWN
        BEQ READ_DOWN_DONE 
        JSR DOWN_PRESSED
    READ_DOWN_DONE:
        RTS

    READ_LEFT:
        LDA current_control
        AND #LEFT
        BEQ READ_LEFT_DONE 
        JSR LEFT_PRESSED
    READ_LEFT_DONE:
        RTS

    READ_RIGHT:
        LDA current_control
        AND #RIGHT
        BEQ READ_RIGHT_DONE 
        JSR RIGHT_PRESSED
    READ_RIGHT_DONE:
        RTS

    ; ================================================================== ;
    ;                          HANDLE INPUT                              ;
    ; ================================================================== ;
    A_PRESSED:
        RTS
    B_PRESSED:
        RTS
    SELECT_PRESSED:
        RTS
    START_PRESSED:
        RTS
    UP_PRESSED:
        LDX #$00
        LDY player_offset_y
        JSR MOVE_SPRITE_UP
        RTS
    DOWN_PRESSED:
        LDX #$00
        LDY player_offset_y
        JSR MOVE_SPRITE_DOWN
        RTS
    LEFT_PRESSED:
        LDX #$00
        LDY player_offset_x
        JSR MOVE_SPRITE_LEFT
        RTS
    RIGHT_PRESSED:
        LDX #$00
        LDY player_offset_x
        JSR MOVE_SPRITE_RIGHT
        RTS

    ; ================================================================== ;
    ;                          MOVE SPRITES                              ;
    ; ================================================================== ;
    MOVE_SPRITE_UP:
        LDA $0200, Y 
        SEC 
        SBC #$02
        STA $0200, Y 
        JSR LOAD_NEXT_SPRITE_COORD 
        INX 
        CPX #$04
        BNE MOVE_SPRITE_UP
        RTS
    
    MOVE_SPRITE_DOWN:
        LDA $0200, Y 
        CLC 
        ADC #$02
        STA $0200, Y 
        JSR LOAD_NEXT_SPRITE_COORD 
        INX 
        CPX #$04
        BNE MOVE_SPRITE_DOWN
        RTS

    MOVE_SPRITE_LEFT:
        LDA $0200, Y 
        SEC 
        SBC #$02
        STA $0200, Y 
        JSR LOAD_NEXT_SPRITE_COORD 
        INX 
        CPX #$04
        BNE MOVE_SPRITE_LEFT
        RTS

    MOVE_SPRITE_RIGHT:
        LDA $0200, Y 
        CLC 
        ADC #$02
        STA $0200, Y 
        JSR LOAD_NEXT_SPRITE_COORD 
        INX 
        CPX #$04
        BNE MOVE_SPRITE_RIGHT
        RTS

    ; ================================================================== ;
    ;                              HELPERS                               ;
    ; ================================================================== ;

    ; get the next sprite coordinate by adding 4 to the Y register
    LOAD_NEXT_SPRITE_COORD:
        TYA                 ; move Y into A
        CLC                 ; clear the previous Carry Flag
        ADC #$04            ; add 4 to A
        TAY                 ; move A back into Y
        RTS


        


    

    



    

