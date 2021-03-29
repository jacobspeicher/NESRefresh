    ; ================================================================== ;
    ;                          COOL THINGS                               ;
    ; ================================================================== ;

    ; FCEUX:    https://fceux.com/web/home.html
    ; NEStopia: http://nestopia.sourceforge.net/
    ; yy-chr:   https://www.smwcentral.net/?p=section&a=details&id=25244
    ; cc65:     https://cc65.github.io/ 
    
    ; ================================================================== ;
    ;                          CPU REGISTERS                             ;
    ; ================================================================== ;

    ;   ACCUMULATOR
    ;   an 8 bit register, used in all arithmetic and logical operations (not increments or decrements). The accumulator can be
    ;   retrieved either from memory or the stack.

    ;   X
    ;   8 bit index regiser mostly used to hold counters or offsets for accessing memory. The X register can be loaded and saved 
    ;   in memory, compared with values held in memory, and incremented or decremented.
    ;   can be used to get a copy of the stack pointer or change the stack pointer value

    ;   Y
    ;   pretty much just X again, but this time it's a Y
    ;   doesn't have the special stack pointer instructions

    ;   PROCESSOR STATUS
    ;   as instructions are executed a set of processor flags are set or cleared to record the results of the operation.
    ;   these are held in a special register, each flag being a single bit in the register. there are instructions to test,
    ;   set, and clear some of them, or push and pull the entire set to/from the stack.
    ;   
    ;   7 6 5 4 3 2 1 0
    ;   | | | | | | | |
    ;   | | | | | | | + - Carry Flag: set if the last operation caused an overflow from bit 7 of the result or an underflow from bit 0
    ;   | | | | | | |       - set during arithmetic, comparison, and logical shifts
    ;   | | | | | | |       - set with SEC (SEt Carry)
    ;   | | | | | | |       - clear with CLC (CLear Carry)
    ;   | | | | | | |
    ;   | | | | | | + - - Zero Flag: set if the result of the last operation was 0
    ;   | | | | | |
    ;   | | | | | + - - - Interrupt Disable: while this flag is set the processor will not respond to interrupts from devices until is is cleared
    ;   | | | | |           - set with SEI (SEt Interrupt)
    ;   | | | | |           - clear with CLI (CLear Interrupt)
    ;   | | | | |
    ;   | | | | + - - - - Decimal Mode: while this flag is set the processor will obey the rules of Binary Coded Decimal (BCD) math during add/sub
    ;   | | | |             - set with SED (SEt Decimal)
    ;   | | | |             - clear with CLD (CLear Decimal)
    ;   | | | |
    ;   | | + + - - - - - B Flag: This doesn't really exist in the Processor Status within the CPU, but when this byte is pushed to the stack there
    ;   | |                         are two additional bits representing whether specific interrupts or instructions pushed this register to the stack
    ;   | |                 - interrupts IRQ or NMI:    1 0
    ;   | |                 - instructions PHP or BRK:  1 1
    ;   | | 
    ;   | + - - - - - - - Overflow Flag: set during arithmetic operations if the result has yielded an invalid 2's complement result (adding
    ;   |                          positive numbers and ending up with a negative result)
    ;   |                   - determined from the carry between bits 6 and 7 and between bit 7 and the carry flag
    ;   |  
    ;   + - - - - - - - - Negative Flag: set if the result of the last operation had bit 7 set to a 1

    ;   helpful sources: https://wiki.nesdev.com/
    ;                    http://www.obelisk.me.uk/6502/registers.html#C
    ;                    http://www.obelisk.me.uk/6502/reference.html#ADC
    ;                    https://nerdy-nights.nes.science/#main_tutorial
    ;                    https://raw.githubusercontent.com/camsaul/nesasm/master/beagle_bros_6502_reference.png
    ;                    https://gamefaqs.gamespot.com/nes/916386-nes/faqs/2947
    ;

    ;
    ;   iNES HEADER
    ;
    .segment "HEADER"
    .byte "NES", $1A    ; the first four bytes of every NES file
                        ; 3 2 1 0
                        ; | | | + - 0x4E: N
                        ; | | + - - 0x45: E
                        ; | + - - - 0x53: S
                        ; + - - - - 0x1A: character break
    .byte $01           ; 1x 16KB PRG code bank
    .byte $01           ; 1x 8KB CHR bank
    .byte %00000001     ; 0000 - NROM mapper, 0001 - vertical mirroring

    ; ================================================================== ;
    ;                          READY DATA                                ;
    ; ================================================================== ;

    ;
    ;   SET UP PALETTE DATA
    ;   these are the bytes that will be loaded from the PRG ROM into the PPU VRAM to be used as color palettes
    ;   for the graphics
    ;
    .segment "PALETTE"
    PALETTE_DATA:   ; 32B of palette data (16B background, 16B sprites) making 4 palettes for each
        .byte $0F,$31,$32,$33, $2D,$35,$36,$37, $0F,$39,$3A,$3B, $0F,$3D,$3E,$0F  ; background palette
        .byte $0F,$16,$27,$18, $2A,$20,$27,$1A, $0F,$1C,$15,$14, $0F,$02,$38,$3C  ; sprite palette

    ;
    ;   SET UP SPRITE DATA
    ;   these are the bytes that will be loaded from the PRG ROM into the PPU VRAM to be used as the sprite graphics.
    ;   each sprite is made up of 4 bytes containing information about that sprite
    ;   3 2 1 0
    ;   | | | + - Y Position
    ;   | | + - - Tile Number (index of the desired sprite from the PPU Pattern Tables)
    ;   | + - - - Attributes
    ;   + - - - - X Position
    ;
    ;   SPRITE ATTRIBUTES
    ;   7 6 5 4 3 2 1 0 
    ;   | | |       | |
    ;   | | |       + + - Color palette (which set of 4 from the 16 colors to use)
    ;   | | + - - - - - - Priority (0: in front of background, 1: behind background)
    ;   | + - - - - - - - Flip sprite horizontally
    ;   + - - - - - - - - Flip sprite vertically
    ;
    .segment "SPRITES"
    SPRITE_DATA:    ; Y Position, Tile Number, Attributes, X Position
        .byte $80, $3A, $00, $40 ; sprite 0
        .byte $80, $37, $00, $48 ; sprite 1
        .byte $88, $4F, $00, $40 ; sprite 2
        .byte $88, $4F, $40, $48 ; sprite 3

        .byte $80, $3A, $01, $C0 ; sprite 0
        .byte $80, $37, $01, $C8 ; sprite 1 
        .byte $88, $4F, $01, $C0 ; sprite 2
        .byte $88, $4F, $41, $C8 ; sprite 3

    ; 
    ;   TILE GRAPHIC DATA
    ;   include the mario.chr file, which contains the tilesheet of sprites that will be loaded from the CHR ROM
    ;   into the PPU Pattern Tables
    ;
    .segment "TILES"
    .incbin "mario.chr"

    ;
    ;   VECTORS
    ;   the NES processor will interrupt the code and jump to a new location three times:
    ;       NMI   - once per video frame, when enabled, the PPU tells the processor that the
    ;               VBLANK is starting so it's available for graphics updates
    ;       RESET - every time the NES starts up, or the RESET button is pressed
    ;       IRQ   - triggered from some mapper chips or audio interrupts
    ;   these must always appear in this order
    ;
    .segment "VECTORS"
    .word NMI
    .word RESET
    .word 0

    ;
    ;   CODE
    ;   now that all the data is set up on the cartridge PRG and CHR ROM, this is what makes the magic happen.
    ;   all of this code will exist on the PRG ROM as well, but it's code not data
    ;
    .segment "CODE"
    NMI:
        ; transfer sprite data from $0200 to the PPU
        ; $0200 is as basically a copy of PPU internal 
        ;   - load $00 into PPU $2003 so that reading/writing to Sprite Memory starts at 
        ;       the base $00 address, and increments each time
        ;   - load $02 into PPU $4014, so the PPU knows it's going to be reading from RAM
        ;       $0200. since we wrote $00 to $2003, when it starts writing to PPU Sprite Memory
        ;       it will begin reading from RAM address $0200 and increment as it goes through the
        ;       256 bytes of sprite information
        LDA #$00
        STA $2003   ; load 0x0 into $2003 so that read/write from/to Sprite Memory starts at $xx00 and increments

        LDA #$02
        STA $4014   ; load 0x2 into $4014 so that 0x100 * 0x2 is the RAM address from which to transfer
                    ; everything to the PPU Sprite Memory

        JSR READY_CONTROLLERS
        JSR READ_PLAYER_1
        JSR READ_PLAYER_2

        RTI

    ; ================================================================== ;
    ;                          READY CONSOLE                             ;
    ; ================================================================== ;

    RESET:
        SEI             ; disable IRQs
        CLD             ; disable decimal mode

        ; the following code is just to clear out everything that used to be in memory and get the NES
        ; ready to reinitialize everything
        LDX #$40
        STX $4017       ; disable APU frame IRQ

        LDX #$FF
        TXS             ; set up stack pointer at 0xFF
        INX             ; X = 0
        STX $2000       ; disable NMI
        STX $2001       ; disable rendering
        STX $4010       ; disable DMC IRQs

    VBLANKWAIT1:        ; first wait for VBLANK to make sure PPU is ready
        BIT $2002       ; set Negative Flag to bit 7 of $2002
        BPL VBLANKWAIT1 ; if the negative flag is clear (positive), then repeat this code block

    CLRMEM:
        LDA #$00        ; set $0000 - $0100, $0300 - $0700 to $00. Skip $0200 because that's where sprites are
        STA $0000, X
        STA $0100, X
        STA $0300, X
        STA $0400, X 
        STA $0500, X
        STA $0600, X
        STA $0700, X 
        LDA #$FE        ; move all the sprites offscreen
        STA $0200, X
        INX             ; X, Z, N = X + 1 (Z: Zero Flag, N: Negative Flag)
        BNE CLRMEM      ; if the Zero Flag is clear, then repeat this code block. so X will increment from $00 to $FF
                        ; $FF + 1 = $00, Zero Flag gets set, continue out of this code block

    VBLANKWAIT2:        ; second wait for VBLANK, PPU is ready after this
        BIT $2002
        BPL VBLANKWAIT2

        ; end clearing out memory
        ; now we're reintialized

    ; pass $3F00 through PPU port $2006 to let the PPU know when it next
    ; receives data through PPU port $2007, pass that along to the PPU address
    ; $3F00 (this is the starting address of palette information in the PPU)
    READY_PPU_PALETTE:
        LDA $2002   ; read the PPU status, this resets the high/low latch to high
        LDA #$3F
        STA $2006   ; write the high byte
        LDA #$00
        STA $2006   ; write the low byte

        LDX #$00
    LOAD_PALETTES_LOOP:
        LDA PALETTE_DATA, X     ; load each byte from the PALETTE_DATA set up earlier, offset by the value in the X register
        STA $2007               ; pass this byte into the PPU, it will be stored at $3F00, $3F01, $3F02, etc
        INX
        CPX #$20                ; compare X to decimal 32 (limit of loop). set the Zero Flag if they're equal
        BNE LOAD_PALETTES_LOOP  ; if the Zero Flag is clear, repeat code block

        LDX #$00
    LOAD_SPRITES_LOOP:
        LDA SPRITE_DATA, X      ; load data from address (SPRITE_DATA + X)
        STA $0200, X            ; store into RAM address ($0200 + X)
        INX
        CPX #$20                ; stop after loading 32 bytes of sprite data
        BNE LOAD_SPRITES_LOOP   ; while Zero Flag is not set, repeat code block

        ; 7 6 5 4 3 2 1 0 PPUCTRL
        ; |   | | | | | |
        ; |   | | | | + + - Base nametable address (0: $2000; 1: $2400; 2: $2800; 3: $2C00)
        ; |   | | | + - - - VRAM address increment per CPU read/write of PPUDATA ($2007)
        ; |   | | |             (0: inc by 1, going across; 1: inc by 32, going down)
        ; |   | | + - - - - Sprite pattern table address for 8x8 sprites
        ; |   | |               (0: $0000; 1: $1000)
        ; |   | + - - - - - Background pattern table address (0: $0000; 1: $1000)
        ; |   + - - - - - - Sprite size (0: 8x8; 1: 8x16)
        ; | 
        ; + - - - - - - - - Generate an NMI at the start of the VBLANK (0: off; 1: on)
        LDA #%10000000
        STA $2000       ; enable NMI, sprites from Pattern Table 1

        ; 7 6 5 4 3 2 1 0 PPUMASK
        ; | | | | | | | |
        ; | | | | | | | + - Grayscale (0: normal color; 1: AND all palette entries with 0x30
        ; | | | | | | |      effectively making a monochrome display; color emphasis will
        ; | | | | | | |      still work with this on!)
        ; | | | | | | + - - Disable background clipping in leftmost 8 pixels of the screen
        ; | | | | | + - - - Disable sprite clipping in leftmost 8 pixels of the screen
        ; | | | | + - - - - Enable background rendering
        ; | | | + - - - - - Enable sprite rendering
        ; | | + - - - - - - Intensify reds (and darken other colors)
        ; | + - - - - - - - Intesify greens (and darken other colors)
        ; + - - - - - - - - Intesify blues (and darken other colors)
        LDA #%00010000
        STA $2001       ; write the PPUMASK, enable sprites

    FOREVER:
        JMP FOREVER

    ; ================================================================== ;
    ;                          READ CONTROLLERS                          ;
    ; ================================================================== ;

    ; CONTROLLER PORTS
    ; - Player 1: $4016
    ; - Player 2: $4017
    ; the buttons are sent one bit at a time, in bit 0. b0 = 0: not pressed, b0 = 1: pressed
    READY_CONTROLLERS:
        LDA #$01
        STA $4016
        LDA #$00
        STA $4016   ; load $0100 into $4016 to tell both controllers to latch buttons

        LDX #$00
        STX $07FE   ; player 1 controller memory address = 0
        STX $07FF   ; player 2 controller memory address = 0
        
        JSR READ_CONTROLLER_PLAYER_1
        LDX #$00
        JSR READ_CONTROLLER_PLAYER_2

        RTS

    
    ; READING CONTROLLERS
    ; - shift the byte in $07FE/$07FF to the left once to keep constructing the byte
    ;       bit by bit (this needs to be done first to prevent accumulator issues later)
    ; - load the player controller from $4016/$4017 depending into the accumulator
    ; - shift bit 0 from that byte into the Carry Flag
    ; - load 0 back into the accumulator
    ; - add the value in $07FE/$07FF to the accumulator (+ 0) + the Carry Flag
    ;       (if button pressed: + 1, if button not pressed: + 0)
    ; - store this new value back into $07FE/$07FF for the next iteration
    ; this method causes the controller to be read "backwards" (if there's such a thing as backwards/forwards)
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
        ASL $07FE   ; shift the value stored in $07FE left by one bit for the next button
        CLC
        LDA $4016   ; read player 1 controller
        LSR         ; shift bit 0 from player 1 controller into the carry bit
        LDA #$00    ; reset the accumulator to 0
        ADC $07FE   ; add the already existing controller byte to the accumulator + carry
        STA $07FE   ; store the new controller byte back from the accumulator to $07FE
        INX
        CPX #$08    ; once this has been run 8 times end this code block
        BNE READ_CONTROLLER_PLAYER_1
        RTS

    READ_CONTROLLER_PLAYER_2:   ; same as READ_CONTROLLER_PLAYER_1 except with $07FF
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
        LDX #$00
        LDY #$00
        JSR MOVE_SPRITE_UP
        RTS

    MOVE_1_DOWN:
        LDX #$00
        LDY #$00
        JSR MOVE_SPRITE_DOWN
        RTS
    
    MOVE_1_LEFT:
        LDX #$00
        LDY #$03
        JSR MOVE_SPRITE_LEFT
        RTS

    MOVE_1_RIGHT:
        LDX #$00
        LDY #$03
        JSR MOVE_SPRITE_RIGHT
        RTS

    MOVE_2_UP:
        LDX #$00
        LDY #$10
        JSR MOVE_SPRITE_UP
        RTS

    MOVE_2_DOWN:
        LDX #$00
        LDY #$10
        JSR MOVE_SPRITE_DOWN
        RTS
    
    MOVE_2_LEFT:
        LDX #$00
        LDY #$13
        JSR MOVE_SPRITE_LEFT
        RTS

    MOVE_2_RIGHT:
        LDX #$00
        LDY #$13
        JSR MOVE_SPRITE_RIGHT
        RTS

    MOVE_SPRITE_UP:
        LDA $0200, Y
        SEC
        SBC #$02
        STA $0200, Y
        JSR LOAD_NEXT_SPRITE_COORD
        INX
        CPX #$04            ; after going through the first 4 sprites, stop
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