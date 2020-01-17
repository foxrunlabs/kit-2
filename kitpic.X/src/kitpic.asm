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
; Purpose   : Source code for the KitPIC loader and peripheral controller.
;===============================================================================


#include "p18f47k40.inc"

#include "config.inc"
#include "kitbios.inc"


;===============================================================================
; PIN DEFINITIONS
;===============================================================================

;- control bus -----------------------------------------------------------------
#define CTRL_PORT PORTE
#define CTRL_LAT  LATE
#define CTRL_TRIS TRISE

#define nRST RE0                            ; 65C02 reset
#define PH2  RE1                            ; 65C02 clock
#define BE   RE2                            ; 65C02 bus enable

;- address bus -----------------------------------------------------------------
#define AB_PORT_L PORTC                     ; AB0-AB7
#define AB_LAT_L  LATC
#define AB_TRIS_L TRISC

#define AB_PORT_H PORTD                     ; AB8-AB9
#define AB_LAT_H  LATD
#define AB_TRIS_H TRISD

;- data bus --------------------------------------------------------------------
#define DB_PORT PORTA                       ; DB0-DB7
#define DB_LAT  LATA
#define DB_TRIS TRISA

;- peripheral bus --------------------------------------------------------------
#define PERIF_PORT PORTB
#define PERIF_LAT  LATB
#define PERIF_TRIS TRISB

#define nSDC RB0                            ; SD card slave select
#define MOSI RB1                            ; SD card data input
#define MISO RB2                            ; SD card data output
#define SCLK RB3                            ; SD card clock
#define RX1  RB4                            ; FTDI USB-to-Serial -> PIC
#define TX1  RB5                            ; PIC -> FTDI USB-to-Serial
#define nRAM RB6                            ; RAM chip select
#define RnW  RB7                            ; R/W signal


;===============================================================================
; RESET VECTOR
;===============================================================================

RESET_VEC   CODE    0x0000

            goto    start


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
; STARTUP
;===============================================================================

            CODE

start:      bsf     NVMCON1, NVMREG1, A     ; errata fix for NVM read
            
            ;- disable unused peripherals --------------------------------------
            banksel PMD0
            movlw   ~((1 << SYSCMD) | (1 << NVMMD))
            movwf   PMD0
            setf    PMD1
            setf    PMD2
            setf    PMD3
            movlw   ~(1 << UART1MD)
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
            movlw   1 << PH2                ; hold BE and nRST low, PH2 high
            movwf   CTRL_LAT, A
            
            movlw   ~((1 << nRST) | (1 << BE) | (1 << PH2))
            movwf   CTRL_TRIS, A            ; nRST, BE, and PH2 as outputs
            
            ;- setup peripheral bus --------------------------------------------
            setf    PERIF_LAT, A            ; hold everything high
            
            movlw   (1 << MISO) | (1 << RX1)
            movwf   PERIF_TRIS, A           ; MISO and RX1 as inputs
            
            ;- setup address and data buses ------------------------------------
            clrf    AB_LAT_L, A             ; drive address and data buses low
            clrf    AB_LAT_H, A
            clrf    DB_LAT, A
            
            clrf    AB_TRIS_L, A            ; take address and data buses
            clrf    AB_TRIS_H, A
            clrf    DB_TRIS, A


;===============================================================================
; SETUP PERIPHERALS
;===============================================================================

uart_setup: movlw   b'00001100'             ; RX1 on RB4
            banksel RX1PPS
            movwf   RX1PPS
            
            movlw   0x09                    ; TX1 on RB5
            banksel RB5PPS
            movwf   RB5PPS
            
            ;- set baud rate ---------------------------------------------------
            bsf     TX1STA, BRGH, A         ; high baud rate
            bsf     BAUD1CON, BRG16, A      ; 16-bit baud rate generator
            movlw   low .277                ; 57554 bps for a -0.08% error
            movwf   SP1BRGL, A
            movlw   high .277               ; computed 64 MHz Fosc
            movwf   SP1BRGH, A     
            
            ;- enable UART -----------------------------------------------------
            bsf     TX1STA, TXEN, A         ; transmitter enabled
            bsf     RC1STA, CREN, A         ; receiver enabled
            bsf     RC1STA, SPEN, A         ; serial port enabled


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
; LOAD IMAGE
;===============================================================================

load_bios:  movlw   upper abyBIOS           ; TBLPTR points to BIOS data
            movwf   TBLPTRU, A     
            movlw   high abyBIOS
            movwf   TBLPTRH, A     
            movlw   low abyBIOS
            movwf   TBLPTRL, A     
            
            ;- setup buses for transfer ----------------------------------------
            clrf    AB_LAT_L, A             ; start at address 0x0000
            clrf    AB_LAT_H, A
            
            setf    DB_TRIS, A              ; release data bus to RAM
            bcf     PERIF_LAT, nRAM, A      ; select RAM
            
            ;- copy image data from ROM to external RAM ------------------------
load_loop:  tblrd   *+                      ; (8R) read BIOS data
            movff   TABLAT, DB_LAT          ; (10R) place on data bus
            
            bcf     PERIF_LAT, RnW, A       ; (11R) set write mode
            clrf    DB_TRIS, A              ; (1W) take control of data bus
            
            nop                             ; (2W) timing adjustment
            nop                             ; (3W) timing adjustment
            nop                             ; (4W) timing adjustment
            
            bsf     PERIF_LAT, RnW, A       ; (5W) set read mode
            setf    DB_TRIS, A              ; (1R) release data bus to RAM
            
            incf    AB_LAT_L, F, A          ; (2R) increment address LSB
            movlw   0x00                    ; (3R) 16-bit addition
            addwfc  AB_LAT_H, F, A          ; (4R) increment address MSB
            bnc     load_loop               ; (6R) branch if address < 0xFFFF
            
            bsf     PERIF_LAT, nRAM, A      ; deselect RAM


;===============================================================================
; RESET 65C02
;===============================================================================

reset_6502: setf    AB_TRIS_L, A            ; release address bus to 65C02
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
; UNINITIALIZED INTERNAL RAM
;===============================================================================

            UDATA

awRegTable  res     2 * 8                   ; 8 peripheral register addresses
byDummyReg  res     2                       ; dummy register for unused regs


;===============================================================================
; REGISTER TABLE ROM
;===============================================================================

REG_TABLE   CODE_PACK

            ;- device 0 - EUSART -----------------------------------------------
awRegTblROM dw      RC1REG
            dw      TX1REG
            dw      PIR3
            dw      RC1STA
            dw      byDummyReg
            dw      byDummyReg
            dw      byDummyReg
            dw      byDummyReg


;===============================================================================
; EXTERNAL SRAM IMAGE
;===============================================================================

BIOS        CODE_PACK

abyBIOS     BIOS_DATA

            END
