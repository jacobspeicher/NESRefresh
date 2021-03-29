    ;
    ;   iNES HEADER
    ;
    .segment "HEADER"
    .byte "NES", $1A
    .byte $01       ; 1x 16KB PRG bank
    .byte $01       ; 1x 8KB CHR bank
    .byte %00000001 ; nibble 1: NROM mapper, nibble 2: vertical mirroring

    ; ================================================================== ;
    ;                          READY DATA                                ;
    ; ================================================================== ;

    ;
    ;   SET UP PALETTES
    ;
    .segment "PALETTES"
    PALETTE_DATA:
        .byte $0F,$05,$26,$30, $0F,$13,$15,$19, $0F,$39,$3A,$3B, $0F,$3D,$3E,$0F  ; background palette
        .byte $0F,$16,$27,$18, $0F,$20,$27,$1A, $0F,$39,$15,$14, $0F,$3D,$38,$3C  ; sprite palette
    
    ;
    ;   SET UP SPRITES
    ;
    .segment "SPRITES"
    SPRITE_DATA:    ; Y Position, Tile Number, Attributes, X Position
        .byte $80, $05, $00, $40 ; sprite 0
        .byte $80, $13, $00, $48 ; sprite 1
        .byte $88, $39, $00, $40 ; sprite 2
        .byte $88, $3D, $00, $48 ; sprite 3

        .byte $80, $16, $01, $C0 ; sprite 0
        .byte $80, $20, $01, $C8 ; sprite 1
        .byte $88, $39, $01, $C0 ; sprite 2
        .byte $88, $3D, $01, $C8 ; sprite 3

    ;
    ;   SET UP BACKGROUND
    ;   each byte is a tile on the background. the values are the tile addresses in the PPU pattern table.
    ;   the NES screen resolution is 32x30 tiles, or 256x240 pixels. so one row of background graphics is 
    ;   32 bytes of data (here each row is split into two 16 byte lines)
    ;   the following 32x4 tiles will be stored in the PPU nametable. palettes are defined later, and are stored in the PPU attribute table
    ;
    .segment "NAMETABLE"
    BACKGROUND_DATA:
        .byte $24, $25, $26, $27, $24, $25, $26, $27, $24, $25, $26, $27, $24, $25, $26, $27
        .byte $24, $25, $26, $27, $24, $25, $26, $27, $24, $25, $26, $27, $24, $25, $26, $27

        .byte $24, $25, $26, $27, $24, $25, $26, $27, $24, $25, $26, $27, $24, $25, $26, $27
        .byte $24, $25, $26, $27, $24, $25, $26, $27, $24, $25, $26, $27, $24, $25, $26, $27

        .byte $24, $25, $26, $27, $24, $25, $26, $27, $24, $25, $26, $27, $24, $25, $26, $27
        .byte $24, $25, $26, $27, $24, $25, $26, $27, $24, $25, $26, $27, $24, $25, $26, $27

        .byte $24, $25, $26, $27, $24, $25, $26, $27, $24, $25, $26, $27, $24, $25, $26, $27
        .byte $24, $25, $26, $27, $24, $25, $26, $27, $24, $25, $26, $27, $24, $25, $26, $27

    ;
    ;   SET UP BACKGROUND ATTRIBUTES
    ;   each byte of attribute information sets the palette for a 4x4 tile area on the screen
    ;   this 4x4 area is again separated into 4 2x2 tile grids. 2 bits in the attribute byte are assigned to
    ;   each of these 2x2 areas. because of this, no 2x2 tile area can use more than 4 colors (one palette)
    ;   7 6 5 4 3 2 1 0
    ;   | | | | | | | |
    ;   | | | | | | + + - top left 2x2 area
    ;   | | | | + + - - - top right 2x2 area
    ;   | | + + - - - - - bottom right 2x2 area
    ;   + + - - - - - - - bottom left 2x2 area
    ;
    ;   since the background consists of 32x4 tiles, 8 bytes of attribute data is needed (32 / 4 = 8 4x4 tile areas)
    ;
    .segment "ATTRIBUTE"
    BACKGROUND_ATTRIBUTES:
        .byte %0000000, %0000000, %0000000, %0000000, %01010101, %01010101, %01010101, %01010101  

    ;
    ;   SET UP TILE GRAPHIC DATA
    ;
    .segment "TILES"
    .incbin "palette_bros.chr"

    ;
    ;   VECTORS
    ;
    .segment "VECTORS"
    .word NMI
    .word RESET
    .word 0

    ;
    ;   CODE
    ;
    .segment "CODE"
    NMI:
        ; transfer sprite data from $0200 to the PPU Sprite Memory
        ; $0200 is basically a CPU RAM representation of the PPU OAM
        LDA #$00
        STA $2003   ; load 0x0 into $2003 so that read/write to/from OAM starts at $xx00 and increments

        LDA #$02
        STA $4014   ; load 0x2 into $4014 so that 0x100 * 0x2 is the RAM address to transfer sprite data from

        JSR READY_CONTROLLERS   ; get controller state and load into memory
        JSR READ_PLAYER_1       ; check controller 1 for input
        JSR READ_PLAYER_2       ; check controller 2 for input

        LDA #$00
        STA $2005
        STA $2005   ; load 0x00 into the PPU Screen Scroll Offset, because there's no scrolling

        RTI

    ; ================================================================== ;
    ;                          READY CONSOLE                             ;
    ; ================================================================== ;

    RESET:
        SEI
        CLD

        ; begin clear out memory
        LDX #$40
        STX $4017   ; disable APU frame IRQ

        LDX #$FF
        TXS         ; set up stack pointer at 0xFF
        INX         ; X = 0
        STX $2000   ; disable NMI
        STX $2001   ; disable rendering
        STX $4010   ; disable DMC IRQs

    VBLANKWAIT1:
        BIT $2002       ; set Negative Flag to bit 7 of $2002
        BPL VBLANKWAIT1 ; if Negative Flag is clear then repeat this code block

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
        STA $0200, X    ; set everything about sprites to 0xFE
        INX             
        BNE CLRMEM      ; if the Zero Flag is clear then repeat this code block

    VBLANKWAIT2:
        BIT $2002
        BPL VBLANKWAIT2

        ; end clearing out memory
        ; now the NES is initialized and ready

        LDX #$00
    LOAD_SPRITES_LOOP:
        LDA SPRITE_DATA, X 
        STA $0200, X 
        INX
        CPX #$20                ; stop after loading 32 bytes of sprite data
        BNE LOAD_SPRITES_LOOP

    READY_PPU_PALETTE:
        ; pass $3F00 through PPU port $2006 to let the PPU know that's where we
        ; want to store data passed through PPU port $2007
        ; $3F00 is the start of palette information
        LDA $2002   ; read the PPU status, this resets the high/low latch to high
        LDA #$3F
        STA $2006   ; high byte
        LDA #$00
        STA $2006   ; low byte
        LDX #$0F
        STA $E010   ; rewrite 0F to be the universal background color for all palettes

        LDX #$00
    LOAD_PALETTES_LOOP:
        LDA PALETTE_DATA, X 
        STA $2007
        INX
        CPX #$20                ; stop after going through all 32 bytes of palette data
        BNE LOAD_PALETTES_LOOP  ; if the Zero Flag is clear, repeat code block


    READY_PPU_BACKGROUND:
        LDA $2002   ; read the PPU status, reset the high/low latch
        LDA #$20    ; high byte
        STA $2006
        LDA #$00    ; low byte
        STA $2006

        LDX #$00
    LOAD_BACKGROUND_LOOP:
        LDA BACKGROUND_DATA, X 
        STA $2007
        INX
        CPX #$80    ; load all 128 bytes of background data
        BNE LOAD_BACKGROUND_LOOP

    READY_PPU_ATTRIBUTE:
        LDA $2002
        LDA #$23
        STA $2006
        LDA #$C0
        STA $2006

        LDX #$00
    LOAD_ATTRIBUTE_LOOP:
        LDA BACKGROUND_ATTRIBUTES, X 
        STA $2007
        INX
        CPX #$08    ; load all 8 bytes of attributes
        BNE LOAD_ATTRIBUTE_LOOP

        LDA #%10010000
        STA $2000       ; enable NMI, sprites from pattern table 0, background from pattern table 1

        LDA #%00011110
        STA $2001       ; enable sprites, background

    FOREVER:
        JMP FOREVER

    ; ================================================================== ;
    ;                          READ CONTROLLERS                          ;
    ; ================================================================== ;

    ; CONTROLLER PORTS
    ; Player 1: $4016
    ; Player 2: $4017
    ; button state is sent in one bit at a time in bit 0.
    ; 0: not pressed, 1: pressed
    READY_CONTROLLERS:
        LDA #$01
        STA $4016
        LDA #$00
        STA $4016   ; load 0x100 into $4016 to tell both controllers to latch buttons

        LDX #$00
        STX $07FE   ; player 1 controller state = 0
        STX $07FF   ; player 2 controller state = 0

        JSR READ_CONTROLLER_PLAYER_1
        LDX #$00
        JSR READ_CONTROLLER_PLAYER_2

        RTS

    ; READING CONTROLLERS
    ; - shift byte in $07FE/$07FF to the left once to keep constructing the state byte
    ; - load the player controller from $4016/$4017 into the accumulator
    ; - shift bit 0 from accumulator into the Carry Flag
    ; - load 0 back into the accumulator
    ; - add the valye in $07FE/$07FF to the accumulator (+ 0) + the Carry Flag
    ; - store this new value back into $07FE/$07FF for the next iteration
    ; this will store the controller state "backwards"
    ; CONTROLLER MAP (backwards)
    ; 7 6 5 4 3 2 1 0
    ; | | | | | | | |
    ; | | | | | | | + - RIGHT
    ; | | | | | | + - - LEFT
    ; | | | | | + - - - DOWN
    ; | | | | + - - - - UP
    ; | | | + - - - - - START
    ; | | + - - - - - - SELECT
    ; | + - - - - - - - B
    ; + - - - - - - - - A
    READ_CONTROLLER_PLAYER_1:
        CLC         ; clear the carry from previous addition
        ASL $07FE  ; shift the value in $07FE left by one bit
        CLC
        LDA $4016   ; read player 1 controller
        LSR         ; shift bit 0 of accumulator into the Carry Flag
        LDA #$00
        ADC $07FE   ; $07FE + A + Carry Flag
        STA $07FE
        INX
        CPX #$08    ; stop after reading all 8 buttons
        BNE READ_CONTROLLER_PLAYER_1
        RTS

    READ_CONTROLLER_PLAYER_2:
        ; this is all the same as READ_CONTROLLER_PLAYER_2
        CLC
        ASL $07FF
        CLC
        LDA $4017
        LSR
        LDA #$00
        ADC $07FF
        STA $07FF
        INX
        CPX #$08
        BNE READ_CONTROLLER_PLAYER_2
        RTS

    READ_PLAYER_1:

    READ_PLAYER_1_UP:
        LDA $07FE
        AND #%00001000              ; bit mask the value in $07FE to check if the UP button is pressed
                                    ; this will clear the Zero Flag if the byte produced is 0x00
        BEQ READ_PLAYER_1_UP_DONE   ; if the Zero Flag is clear then skip over the instruction to move
                                    ; the sprite up

        JSR MOVE_1_UP
    READ_PLAYER_1_UP_DONE:

    READ_PLAYER_1_DOWN:
        LDA $07FE
        AND #%00000100
        BEQ READ_PLAYER_1_DOWN_DONE

        JSR MOVE_1_DOWN
    READ_PLAYER_1_DOWN_DONE:

    READ_PLAYER_1_LEFT:
        LDA $07FE
        AND #%00000010
        BEQ READ_PLAYER_1_LEFT_DONE

        JSR MOVE_1_LEFT
    READ_PLAYER_1_LEFT_DONE:

    READ_PLAYER_1_RIGHT:
        LDA $07FE
        AND #%00000001
        BEQ READ_PLAYER_1_RIGHT_DONE

        JSR MOVE_1_RIGHT
    READ_PLAYER_1_RIGHT_DONE:

        RTS ; return from READ_PLAYER_1

    READ_PLAYER_2:

    READ_PLAYER_2_UP:
        LDA $07FF
        AND #%00001000
        BEQ READ_PLAYER_2_UP_DONE

        JSR MOVE_2_UP
    READ_PLAYER_2_UP_DONE:

    READ_PLAYER_2_DOWN:
        LDA $07FF
        AND #%00000100
        BEQ READ_PLAYER_2_DOWN_DONE

        JSR MOVE_2_DOWN
    READ_PLAYER_2_DOWN_DONE:

    READ_PLAYER_2_LEFT:
        LDA $07FF
        AND #%00000010
        BEQ READ_PLAYER_2_LEFT_DONE

        JSR MOVE_2_LEFT
    READ_PLAYER_2_LEFT_DONE:

    READ_PLAYER_2_RIGHT:
        LDA $07FF
        AND #%00000001
        BEQ READ_PLAYER_2_RIGHT_DONE

        JSR MOVE_2_RIGHT
    READ_PLAYER_2_RIGHT_DONE:

        RTS ; return from READ_PLAYER_2

    ; ================================================================== ;
    ;                              MOVEMENT                              ;
    ; ================================================================== ;

    MOVE_1_UP:
        LDX #$00    ; reset loop counter
        LDY #$00    ; starting from 0x00 (player 1 Y coordinate)
        JSR MOVE_SPRITE_UP
        RTS

    MOVE_1_DOWN:
        LDX #$00
        LDY #$00
        JSR MOVE_SPRITE_DOWN
        RTS
    
    MOVE_1_LEFT:
        LDX #$00
        LDY #$03    ; starting from 0x03 (X coordinate)
        JSR MOVE_SPRITE_LEFT
        RTS

    MOVE_1_RIGHT:
        LDX #$00
        LDY #$03
        JSR MOVE_SPRITE_RIGHT
        RTS

    MOVE_2_UP:
        LDX #$00    ; reset loop counter
        LDY #$10    ; start from 0x10 (player 2 Y coordinate)
        JSR MOVE_SPRITE_UP
        RTS
    
    MOVE_2_DOWN:
        LDX #$00
        LDY #$10
        JSR MOVE_SPRITE_DOWN
        RTS

    MOVE_2_LEFT:
        LDX #$00
        LDY #$13    ; start from 0x13 (player 2 X coordinate)
        JSR MOVE_SPRITE_LEFT
        RTS

    MOVE_2_RIGHT:
        LDX #$00
        LDY #$13
        JSR MOVE_SPRITE_RIGHT
        RTS

    MOVE_SPRITE_UP:
        LDA $0200, Y    ; load each sprite's Y coordinate
        SEC             ; set Carry Flag for subtraction
        SBC #$02        ; move 2 pixels up
        STA $0200, Y 
        JSR LOAD_NEXT_SPRITE_COORD
        INX
        CPX #$04        ; stop after the 4 sprites that make up player
        BNE MOVE_SPRITE_UP
        RTS

    MOVE_SPRITE_DOWN:
        LDA $0200, Y 
        CLC             ; clear Carry Flag for addition
        ADC #$02        ; move 2 pixels down
        STA $0200, Y 
        JSR LOAD_NEXT_SPRITE_COORD
        INX
        CPX #$04
        BNE MOVE_SPRITE_DOWN
        RTS

    MOVE_SPRITE_LEFT:
        LDA $0200, Y    ; load each sprites X coordinate
        SEC             
        SBC #$02        ; move 2 pixels left
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
        TYA         ; move Y into A
        CLC
        ADC #$04    ; add 4 to A
        TAY         ; move A back into Y
        RTS
