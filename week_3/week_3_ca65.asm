; JUST A NOTE: MAKE SURE DIRECTIVES ARE INDENTED OR ELSE NESASM WILL HAVE A FIT
;
;   iNES Header
;   gives all the info about the game including mapper, graphics mirroring, and PRG/CHR
;   sizes
;
    .SEGMENT "HEADER"
    .BYTE "NES", $1A
    .BYTE $01       ; 1x 16KB PGR code bank
    .BYTE $01       ; 1x 8KB CHR data bank
    .BYTE %00000001 ; mapper 0000 = NROM, no bank swapping (left nibble)
                    ; background mirroring 0001 (vertical mirroring) (right nibble)


    .SEGMENT "CODE"

RESET:
    SEI             ; disable IRQs
    CLD             ; disable decimal mode

    ; 7 6 5 4 3 2 1 0 PPUMASK binary code
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
    LDA #%00100000  ; intensify colors 
    STA $2001

FOREVER:
    JMP FOREVER     ; infinite loop

NMI:
    RTI

;
;   VECTORS
;   the NES processor will interrupt the code and jump to a new location three times:
;       NMI   - once per video frame, when enabled, the PPU tells the processor that the
;               VBLANK is starting so it's available for graphics updates
;       RESET - every time the NES starts up, or the RESET button is pressed
;       IRQ   - triggered from some mapper chips or audio interrupts
;   these must always appear in this order
;
    .SEGMENT "VECTORS"
    .WORD NMI     ; when an NMI happens the processor jumps to the NMI label
    .WORD RESET   ; when the processor first turns on or is reset, jumps to the RESET label
    .WORD 0       ; external interrupt IRQ not used


    .SEGMENT "TILES"
    .incbin "mario.chr" ; includes 8KB graphics file from SMB1