;===============================================================================
; Copyright 2020 Ryan Clarke
; 
; Licensed under the Apache License, Version 2.0 (the "License"); you may not
; use this file except in compliance with the License. You may obtain a copy of
; the License at
; 
;   http://www.apache.org/licenses/LICENSE-2.0
; 
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
; WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
; License for the specific language governing permissions and limitations under
; the License.
;===============================================================================

;===============================================================================
; Program   : KitPIC
; File Name : kitpic.asm
; Project   : Kit-2 8-bit Computer
; Device    : PIC18F47K40
; Author    : Ryan Clarke
; E-mail    : kj6msg@icloud.com
;-------------------------------------------------------------------------------
; Purpose   : Source code for the KitPIC RAM loader and peripheral controller.
;===============================================================================


#include "p18f47k40.inc"
#include "config.inc"
#include "kitpic.inc"
#include "sdcard.inc"
#include "spi.inc"


;===============================================================================
; IMPORTS/EXPORTS
;===============================================================================

            global  reg8A, reg16A, reg32A
            global  reg8B, reg16B, reg32B
            global  reg8C, reg16C, reg32C
            global  printhex
            
            extern  sdc_init
            
            extern  uart_write
            extern  uart_puts
            
            extern  fat16_init
            extern  find_kitos
            extern  load_kitos


;===============================================================================
; CONSTANT VALUES
;===============================================================================

#define VERSION "0.1.0"


;= UART BAUD RATES =============================================================

B57600  equ .277                            ; 57,554 bps (0.08% error)
B115200 equ .138                            ; 115,108 bps (0.08% error)


;= CONTROL CHARACTERS ==========================================================

NUL equ 0x00
BEL equ 0x07
LF  equ 0x0A
ESC equ 0x1B


;===============================================================================
; MACROS
;===============================================================================

puts        MACRO   string
            
            movlw   upper string
            movwf   TBLPTRU, A
            movlw   high string
            movwf   TBLPTRH, A
            movlw   low string
            movwf   TBLPTRL, A
            call    uart_puts
            
            ENDM


;===============================================================================
; RESET VECTOR
;===============================================================================

RESET_VEC   CODE    0x0000

start:      bsf     NVMCON1, NVMREG1, A     ; errata fix for NVM read
            goto    main


;===============================================================================
; ISR HIGH VECTOR
;===============================================================================

ISRH_VEC    CODE    0x0008

            retfie


;===============================================================================
; ISR LOW VECTOR
;===============================================================================

ISRL_VEC    CODE    0x0018

            retfie


;===============================================================================
; MAIN PROGRAM
;===============================================================================

            CODE
            ; TODO: pullup resistors and open-drain for control pins
main:       ;- disable unused peripherals --------------------------------------
            banksel PMD0
            movlw   ~((1 << SYSCMD) | (1 << NVMMD))
            movwf   PMD0
            setf    PMD1
            setf    PMD2
            setf    PMD3
            movlw   ~((1 << UART1MD) | (1 << MSSP1MD))
            movwf   PMD4
            setf    PMD5
            
            ;- disable analog inputs -------------------------------------------
            banksel ANSELA
            clrf    ANSELA
            clrf    ANSELB
            clrf    ANSELC
            clrf    ANSELD
            clrf    ANSELE
            
            ;- setup control bus -----------------------------------------------
            movlw   1 << PH2                ; hold 6502 in reset, idle PH2 high,
            movwf   CTRL_LAT, A             ; and take control of the buses
            
            movlw   ~((1 << nRST) | (1 << BE) | (1 << PH2))
            movwf   CTRL_TRIS, A            ; nRST, BE, and PH2 as outputs
            
            ;- setup peripheral bus --------------------------------------------
            setf    PERIF_LAT, A            ; set all perifs high
            
            movlw   (1 << SDI1) | (1 << RX1)
            movwf   PERIF_TRIS, A           ; SDI1 and RX1 as inputs
            
            ;- setup address and data buses ------------------------------------
            clrf    AB_LAT_L, A             ; drive address and data buses low
            clrf    AB_LAT_H, A
            clrf    DB_LAT, A
            
            clrf    AB_TRIS_L, A            ; take address and data buses
            clrf    AB_TRIS_H, A
            clrf    DB_TRIS, A
            
            ;- setup software stack pointer ------------------------------------
            lfsr    FSR2, abyStack + 0xFF   ; FSR2->top of stack


;===============================================================================
; PERIPHERAL SETUP
;===============================================================================

;= UART ========================================================================

uart_setup: ;- set peripheral pins ---------------------------------------------
            movlw   b'00001100'             ; RX1 on RB4
            banksel RX1PPS
            movwf   RX1PPS
            
            movlw   0x09                    ; TX1 on RB5
            banksel RB5PPS
            movwf   RB5PPS
            
            ;- set baud rate ---------------------------------------------------
            bsf     TX1STA, BRGH, A         ; high baud rate
            bsf     BAUD1CON, BRG16, A      ; 16-bit baud rate generator
            movlw   low B115200
            movwf   SP1BRGL, A
            movlw   high B115200            ; computed for 64 MHz Fosc
            movwf   SP1BRGH, A     
            
            ;- enable UART -----------------------------------------------------
            bsf     TX1STA, TXEN, A         ; transmitter enabled
            bsf     RC1STA, CREN, A         ; receiver enabled
            bsf     RC1STA, SPEN, A         ; serial port enabled


;= SPI =========================================================================

spi_setup:  ;- set peripheral pins ---------------------------------------------
            movlw   b'00001010'             ; SDI1 on RB2
            banksel SSP1DATPPS
            movwf   SSP1DATPPS
            
            movlw   0x10                    ; SDO1 on RB1
            banksel RB1PPS
            movwf   RB1PPS
            
            movlw   0x0F                    ; SCK1 on RB3
            banksel RB3PPS
            movwf   RB3PPS
            
            ;- set SCK1 frequency ----------------------------------------------
            movlw   S100K                   ; SCK1 is 100 kHz
            movwf   SSP1ADD, A
            
            ;- setup SPI mode 0 ------------------------------------------------
            movlw   b'11000000'             ; data sampled at middle of output
            movwf   SSP1STAT, A             ; transmit on SCK high to low
            
            movlw   b'00101010'             ; SPI enabled, SCK idle low
            movwf   SSP1CON1, A             ; SCK determined by SSP1ADD


;===============================================================================
; PRINT BANNER
;===============================================================================

banner:     puts    szClrScr
            puts    szBanner


;===============================================================================
; LOAD KITOS
;===============================================================================
            
            ;- initialize SD card ----------------------------------------------
load_os:    call    sdc_init                ; initialize SD card
            tstfsz  WREG, A                 ; zero equals success
            bra     load_error              ; branch if fail to initialize
            
            ;- initialize FAT16 volume -----------------------------------------
            call    fat16_init              ; initialize FAT16 volume
            tstfsz  WREG, A                 ; zero equals success
            bra     load_error              ; branch if fail to initialize
            
            ;- find KitOS on FAT16 volume --------------------------------------
            call    find_kitos              ; find KitOS on the FAT16 volume
            movf    reg16A+1, W, A          ; return value of zero is an error
            bnz     check_size
            movf    reg16A, W, A
            bz      load_error              ; branch if KitOS not found
            
check_size: movf    reg32B, W, A            ; verify file size is 65536 bytes
            bnz     load_error              ; branch if not 0x00
            movf    reg32B+1, W, A
            bnz     load_error              ; branch if not 0x00
            movlw   1
            cpfseq  reg32B+2, A
            bra     load_error              ; branch if not 0x01
            movf    reg32B+3, W, A
            bz      load_ram                ; branch if not 0x00
            
            ;- KitOS loading error ---------------------------------------------
load_error: puts    szLoadErr               ; loading error
            bra     $
            
            ;- load external RAM with KitOS ------------------------------------
load_ram:   puts    szLoadOS
            
            call    load_kitos              ; load the external RAM with KitOS
            tstfsz  WREG, A                 ; zero equals success
            bra     load_error


;===============================================================================
; INITIALIZE REGISTER TABLE
;===============================================================================

init_reg_tbl:
            lfsr    FSR0, awRegTable        ; FSR0 points to reg. table in RAM
            
            movlw   upper awRegTblROM       ; TBLPTR points to reg. table in ROM
            movwf   TBLPTRU, A              ; which hold peripheral register
            movlw   high awRegTblROM        ; addresses
            movwf   TBLPTRH, A
            movlw   low awRegTblROM
            movwf   TBLPTRL, A
            
            ;- copy register locations from ROM to internal RAM ----------------
            movlw   8                       ; move 8 words from ROM to RAM
reg_loop:   tblrd   *+                      ; read register LSB from ROM
            movff   TABLAT, POSTINC0        ; write to register table in RAM
            tblrd   *+                      ; read register MSB from ROM
            movff   TABLAT, POSTINC0        ; write to register table in RAM
            
            decf    WREG, W, A              ; decrement word counter
            bnz     reg_loop                ; branch while words remain
                        
            lfsr    FSR0, awRegTable        ; FSR0 points to reg. table in RAM


;===============================================================================
; RESET 65C02
;===============================================================================

reset_6502: setf    DB_TRIS, A              ; release data bus to 65C02
            setf    AB_TRIS_L, A            ; release address bus to 65C02
            setf    AB_TRIS_H, A     
            bsf     PERIF_TRIS, RnW, A      ; release RnW pin to 65C02
            bsf     CTRL_LAT, BE, A         ; 65C02 now controls the buses
            
            movlw   5                       ; five clock cycles in reset
reset_loop: bcf     CTRL_LAT, PH2, A        ; (8H) clock is now low
            nop                             ; (1L)
            nop                             ; (2L)
            nop                             ; (3L)
            nop                             ; (4L)
            nop                             ; (5L)
            nop                             ; (6L)
            nop                             ; (7L)
            bsf     CTRL_LAT, PH2, A        ; (8L) clock is now high
            
            nop                             ; (1H)
            nop                             ; (2H)
            nop                             ; (3H)
            nop                             ; (4H)
            decf    WREG, W, A              ; (5H) decrement cycle counter
            bnz     reset_loop              ; (7H) branch if cycle count > 0
            
            bsf     CTRL_LAT, nRST, A       ; (7H) let the 6502 go!


;===============================================================================
; CLOCK/LOGIC LOOP
;===============================================================================

clk_loop:   bcf     CTRL_LAT, PH2, A        ; (xH) clock is now low
            
            setf    DB_TRIS, A              ; (1L) release data bus
            
            movlw   0x02                    ; (2L) IO is at RAM page 0x02
            nop                             ; (3L) let address bus settle
            cpfseq  AB_PORT_H, A            ; (4L) RAM // (5L) IO
            bra     ram_access              ; (6L) RAM access request
            
            ;- IO access request -----------------------------------------------
io_access:  bsf     PERIF_LAT, nRAM, A      ; (6L) deselect RAM
            
            movf    AB_PORT_L, W, A         ; (7L) read register selection
            bsf     CTRL_LAT, PH2, A        ; (8L) clock is now high
            andlw   0x07                    ; (1L) limit to 8 registers
            
            bcf     STATUS, C, A            ; (2H) clear carry for rotate
            rlcf    WREG, W, A              ; (3H) 2*W for 16-bit words
            
            movff   PLUSW0, FSR1L           ; (5H) set FSR1 to point to register
            incf    WREG, W, A              ; (6H)
            movff   PLUSW0, FSR1H           ; (8H)
            
            btfss   PERIF_PORT, RnW, A      ; (9H) write // (10H) read
            bra     io_write                ; (11H) IO write request
            
            ;- IO read request -------------------------------------------------
io_read:    movff   INDF1, DB_LAT           ; (12H) copy reg. value to data bus
            clrf    DB_TRIS, A              ; (13H) take control of data bus
            bra     clk_loop                ; (15H) keep clocking

            ;- IO write request ------------------------------------------------
io_write:   movff   DB_PORT, INDF1          ; (13H) copy data bus to register
            bra     clk_loop                ; (15H) keep clocking
            
            ;- external RAM access request -------------------------------------
ram_access: nop                             ; (7L) timing adjustment
            bsf     CTRL_LAT, PH2, A        ; (8L) clock is now high

            bcf     PERIF_LAT, nRAM, A      ; (1H) select RAM            
            nop                             ; (2H) timing adjustment
            nop                             ; (3H) timing adjustment
            nop                             ; (4H) timing adjustment
            nop                             ; (5H) timing adjustment
            bra     clk_loop                ; (7H) done


;===============================================================================
; HELPER FUNCTIONS
;===============================================================================

;= PRINTHEX ====================================================================
; Print byte in ASCII hexadecimal to the terminal.
;
; Parameters:
;   W - byte.
;
; Returns:
;   none.
;
; Remarks:
;   This function prints an 8-bit byte to the terminal in ASCII hexadecimal
;   format.

printhex:   movwf   reg8A, A
            
            swapf   WREG, W, A
            movwf   reg8B, A
            
            movlw   0x0F
            andwf   reg8B, F, A
            
            movlw   0x0A
            cpfslt  reg8B, A
            bra     notless0
            
conv0:      movlw   0x30
            xorwf   reg8B, W, A
            call    uart_write
            
            movlw   0x0F
            andwf   reg8A, F, A
            
            movlw   0x0A
            cpfslt  reg8A, A
            bra     notless1
            
conv1:      movlw   0x30
            xorwf   reg8A, W, A
            call    uart_write
            
            return
            
notless0:   movlw   0x67
            addwf   reg8B, F, A
            bra     conv0
            
notless1:   movlw   0x67
            addwf   reg8A, F, A
            bra     conv1


;===============================================================================
; UNINITIALIZED INTERNAL RAM
;===============================================================================

BSS         UDATA

awRegTable: res     2 * 8                   ; 8 peripheral register addresses
byDummyReg: res     2                       ; dummy register for unused regs


STACK       UDATA

abyStack    res     .256


;===============================================================================
; UNINITIALIZED INTERNAL ACCESS RAM
;===============================================================================

BSS_ACS     UDATA_ACS

;= PSEUDO REGISTERS ============================================================

reg8A:
reg16A:
reg32A:     res     4                       ; register A

reg8B:
reg16B:
reg32B:     res     4                       ; register B

reg8C:
reg16C:
reg32C:     res     4                       ; register C


;===============================================================================
; READ ONLY DATA - PROGRAM ROM
;===============================================================================

RODATA      CODE_PACK

;= REGISTER TABLE ==============================================================

            ;- device 0 - EUSART -----------------------------------------------
awRegTblROM dw      RC1REG
            dw      TX1REG
            dw      PIR3
            dw      RC1STA
            dw      byDummyReg
            dw      byDummyReg
            dw      byDummyReg
            dw      byDummyReg


;= STRINGS =====================================================================

szClrScr:   db      ESC, "[2J"            ; clear terminal
            db      ESC, "[H", NUL        ; reset cursor
            
szBanner:   db      "KitLoad ", VERSION, LF
            db      "Copyright 2020 Ryan Clarke", LF, LF, NUL
            
szLoadErr:  db      BEL, "Unable to Load KitOS", LF, NUL

szLoadOS:   db      "Loading KitOS", NUL


;===============================================================================

            END
