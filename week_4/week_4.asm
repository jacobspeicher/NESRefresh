;
;   iNES HEADER
;
    .segment "HEADER"
    .byte "NES", $1A
    .byte $01           ; 16KB PRG code bank
    .byte $01           ; 8KB CHR code bank
    .byte %00000001     ; 0000 - NROM mapper, 0001 - vertical mirroring

    .segment "PALETTE"
    PALETTE_DATA:
        .byte $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F  ; background palette
        .byte $0F,$1C,$15,$14,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C  ; sprite palette

    .segment "TILES"
    .incbin "mario.chr"

    .segment "VECTORS"
    .word NMI   ; every time an NMI happens go to the NMI label
    .word RESET ; when the console starts or is reset go to the RESET label
    .word 0     ; no IRQ rn

    .segment "CODE"

    NMI:
        ; transfer sprite data from $0200 to the PPU
        ; - load $00 into PPU $2003 so that reading/writing to Sprite Memory starts at 
        ;   the base $00 address, and increments each time
        ; - load $02 into PPU $4014, so the PPU knows it's going to be reading from RAM
        ;   $0200. since we wrote $00 to $2003, when it starts writing to PPU Sprite Memory
        ;   it will begin reading from RAM address $0200 and increment as it goes through
        ;   $0100 bytes
        LDA #$00
        STA $2003   ; set the low byte of the RAM address
                    ; writing to $2003 sets the address of the 256-byte Sprite Memory
                    ; to be accessed via $2004
        LDA #$02
        STA $4014   ; set the high byte of the RAM address, start the transfer
                    ; writing a value N into $4014 causes an area of RAM at address
                    ; at $100*N to be transferred into Sprite Memory

        RTI

    RESET:
        SEI             ; disable IRQs
        CLD             ; disable decimal mode

        LDA %00000000
        STA $2001       ; write to the PPUMASK address

    ; pass $3F00 through PPU port $2006 to let the PPU know when it next
    ; receives data through PPU port $2007, pass that along to the PPU address
    ; $3F00 (this is one of the addresses that stores palette information)
    READY_PPU_PALETTE:
        LDA $2002   ; read PPU status to reset the high/low latch to high
        LDA #$3F
        STA $2006   ; write the high byte of $3F00 address
        LDA #$00
        STA $2006   ; write the low byte of $3F00 address

    ; the first write to PPU port $2007 will go to the previously-set $3F10 address
    ; each subsequent read/write, the PPU will automatically increment the address
    ; this sets the first 4 colors of the palette
    ; MAUNAL_PALETTE_LOAD:
    ; LDA #$32    ; code for light-blue-ish
    ; STA $2007   ; STA (PPU) $3F00
    ; LDA #$14    ; code for pink-ish
    ; STA $2007   ; STA (PPU) $3F01
    ; LDA #$2A    ; code for green-ish
    ; STA $2007   ; STA (PPU) $3F02
    ; LDA #$16    ; code for red-ish
    ; STA $2007   ; write to PPU $3F03

    SETUP_PALETTES_LOOP:
        LDX #$00
    LOAD_PALETTES_LOOP:
        LDA PALETTE_DATA, x     ; load data from address (PALETTE_DATA + value in x), so:
                                ; PALETTE_DATA + 0
                                ; PALETTE_DATA + 1
                                ; ...
        STA $2007               ; write to PPU (remember this increments 
                                ; the address within the PPU each time!)
        INX                     ; increment value in X
        CPX #$20                ; compare X to decimal 32
        BNE LOAD_PALETTES_LOOP  ; branch back to the top of this code block if CPX did not set
                                ; the zero flag (branch not equal), otherwise continue

    ; SPRITE DATA
    ; each sprite needs 4 bytes of data for its position and tile information (order matters):
    ; 1. Y Position
    ;       - vertical position of the sprite. $00 = top, > $EF = off the bottom of the screen
    ; 2. Tile Number
    ;       - number (0 to 256) for the graphic tile taken from the Pattern Table
    ; 3. Attributes
    ;       - color and display information
    ;           7 6 5 4 3 2 1 0 
    ;           | | |       | |
    ;           | | |       + + - Color palette (which set of 4 from the 16 colors to use)
    ;           | | + - - - - - - Priority (0: in front of background, 1: behind background)
    ;           | + - - - - - - - Flip sprite horizontally
    ;           + - - - - - - - - Flip sprite vertically
    ; 4. X Position
    ;       - horizontal position of the sprite. $00 = left, > $F9 = off the right of the screen
    ; 
    ; these 4 bytes repeat 64 times (one set per sprite) to fill the 256 bytes of sprite memory
    ; Sprite 1 = $0200 - $0203
    ; Sprite 2 = $0204 - $0207
    ; ...
    SPRITE_DATA:
        ; set up the sprite data as described above
        LDA #$80
        STA $0200       ; put sprite 0 in center ($80) of screen vertically
        STA $0203       ; put sprite 0 in center ($80) of screen horizontally
        LDA #$00
        STA $0201       ; tile number = 0
        STA $0202       ; color palette = 0, no flipping

        LDA #%10000000  ; enable NMI, sprites from Pattern Table 0
        STA $2000

        LDA #%00010000  ; no intensify (black background), enable sprites
        STA $2001

    FOREVER:
        JMP FOREVER
    



        

