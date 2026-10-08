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
; File Name : sdcard.asm
; Project   : Kit-2 8-bit Computer
; Device    : PIC18F47K40
; Author    : Ryan Clarke
; E-mail    : kj6msg@icloud.com
;-------------------------------------------------------------------------------
; Purpose   : SD card routines for the KitPIC RAM loader and peripheral
;             controller.
;===============================================================================


#include "p18f47k40.inc"
#include "kitpic.inc"
#include "sdcard.inc"
#include "spi.inc"


;===============================================================================
; IMPORTS/EXPORTS
;===============================================================================

            extern  reg8A, reg16A, reg32A
            extern  reg8B, reg16B, reg32B
            
            global  sdc_init
            global  sdc_rd_blk
            global  abySDCData


;===============================================================================
; SD CARD ROUTINES
;===============================================================================

            CODE


;= SD CARD COMMAND =============================================================
; Send command to SD card.
;
; Parameters:
;   W      = command.
;   reg32A = 32-bit command argument.
;   reg8B  = 8-bit CRC.
;
; Returns:
;   W = response.
;
; Remarks:
;   This function sends an 8-bit command, a 32-bit argument, and an 8-bit CRC
;   to the SD card. It returns an 8-bit response. The caller must select and
;   deselect the SD card before calling this function.

sdc_cmd:    movwf   SSP1BUF, A              ; send command
            spi_wait                        ; wait for transfer to complete
            movf    SSP1BUF, W, A           ; clear BF flag
            
            ;- send 32-bit argument -------------------------------------------- 
            movff   reg32A+3, SSP1BUF       ; send MSB first
            spi_wait                        ; wait for transfer to complete
            movf    SSP1BUF, W, A           ; clear BF flag
            
            movff   reg32A+2, SSP1BUF
            spi_wait
            movf    SSP1BUF, W, A
            
            movff   reg32A+1, SSP1BUF
            spi_wait
            movf    SSP1BUF, W, A
            
            movff   reg32A, SSP1BUF
            spi_wait
            movf    SSP1BUF, W, A
            
            ;- send CRC --------------------------------------------------------
            movff   reg8B, SSP1BUF          ; send CRC
            spi_wait                        ; wait for transfer to complete
            movf    SSP1BUF, W, A           ; clear BF flag
            
            ;- wait for response -----------------------------------------------
            movlw   .10                     ; 10 attempts at reception
            movwf   reg8A, A
            movlw   0xFF
            movwf   reg8B, A
response:   setf    SSP1BUF, A              ; send dummy data
            spi_wait
            movf    SSP1BUF, W, A
            cpfseq  reg8B, A
            bra     $ + 6                   ; if it's not 0xFF, we're done
            
            decfsz  reg8A, F, A             ; decrement counter
            bra     response                ; branch if > 0
            
            return


;= SD CARD INIT ================================================================
; Initialize the SD card.
;
; Parameters:
;   none.
;
; Returns:
;   W - status.
;
; Remarks:
;   This function initializes the SD card. It returns non-zero if the card
;   remains uninitialized/invalid, and returns zero if initialized.

sdc_init:   ;- set native mode -------------------------------------------------
            movlw   .10                     ; send 80 clocks
            movwf   reg8A, A
set_native: setf    SSP1BUF                 ; send dummy data
            spi_wait                        ; wait for transfer to complete
            movf    SSP1BUF, W, A           ; clear BF flag
            
            decfsz  reg8A, F, A             ; decrement loop counter
            bra     set_native              ; skipped if 10 iterations complete
            
            ;- set SD card to idle state ---------------------------------------
set_idle:   clrf    reg32A, A               ; argument is 0x00000000
            clrf    reg32A+1, A
            clrf    reg32A+2, A
            clrf    reg32A+3, A
            movlw   0x95                    ; CMD0 CRC always 0x95
            movwf   reg8B, A
            movlw   SDC_CMD0                ; GO_IDLE_STATE
            bcf     PERIF_LAT, nSDC, A      ; select SD card
            rcall   sdc_cmd                 ; send command to SD card
            
            movwf   reg8A, A                ; move response to reg8A
            movlw   (1 << IDLE)
            cpfseq  reg8A, A                ; compare response with IDLE
            bra     init_fail               ; branch if SD card not idle
            
            ;- test for card version -------------------------------------------
card_ver:   movlw   0xAA                    ; argument is 0x000001AA
            movwf   reg32A, A
            movlw   0x01
            movwf   reg32A+1, A
            clrf    reg32A+2, A
            clrf    reg32A+3, A
            movlw   0x87                    ; CMD8 CRC is always 0x87
            movwf   reg8B, A
            movlw   SDC_CMD8                ; SEND_IF_COND
            rcall   sdc_cmd                 ; send command to SD card
            
            movwf   reg8A, A                ; save R1 response embedded in R7
            
            setf    SSP1BUF                 ; get remaining 4 R7 response bytes
            spi_wait
            movf    SSP1BUF, W, A
            
            setf    SSP1BUF
            spi_wait
            movf    SSP1BUF, W, A
            
            setf    SSP1BUF
            spi_wait
            movf    SSP1BUF, W, A
            
            setf    SSP1BUF
            spi_wait
            movff   SSP1BUF, reg8B          ; save 'echo back' from R7
            
            btfsc   reg8A, ILLEGAL, A       ; check illegal flag
            bra     init_fail               ; possibly version 1 or MMC
            
            movlw   0xAA                    ; check 'echo back'
            cpfseq  reg8B, A                ; compare with received R7 LSB
            bra     init_fail               ; unknown card
            
            ;- activate initialization routine ---------------------------------
init_cmd:   clrf    reg32A, A               ; argument is 0x00000000
            clrf    reg32A+1, A
            clrf    reg32A+2, A
            clrf    reg32A+3, A
            setf    reg8B, A                ; dummy CRC
            movlw   SDC_CMD55               ; APP_CMD
            rcall   sdc_cmd                 ; send command to SD card
            
            clrf    reg32A, A               ; argument is 0x40000000
            clrf    reg32A+1, A
            clrf    reg32A+2, A
            movlw   0x40
            movwf   reg32A+3, A
            setf    reg8B, A                ; dummy CRC
            movlw   SDC_ACMD41              ; APP_SEND_OP_COND
            rcall   sdc_cmd                 ; send command to SD card
            
            btfsc   WREG, ILLEGAL, A        ; check illegal flag
            bra     init_fail               ; unknown card
            
            btfsc   WREG, IDLE, A           ; check idle flag
            bra     init_cmd                ; branch if card idle
            
            ;- increase SCK1 frequency -----------------------------------------
chg_clk:    movlw   S1M                     ; SCK1 is 1 MHz
            movwf   SSP1ADD, A
            
            ;- set block size to 512 bytes -------------------------------------
blk_sz_cmd: clrf    reg32A, A               ; argument is 0x00000200 (512 bytes)
            movlw   0x02
            movwf   reg32A+1, A
            clrf    reg32A+2, A
            clrf    reg32A+3, A
            setf    reg8B, A                ; dummy CRC
            movlw   SDC_CMD16               ; SET_BLOCKLEN
            rcall   sdc_cmd                 ; send command to SD card
            
            btfsc   WREG, ILLEGAL, A        ; check illegal flag
            bra     init_fail               ; unknown card
            
            clrf    reg8A, A                ; success!
            bra     init_exit               ; clean up
            
            ;- fail to initialize ----------------------------------------------
init_fail:  setf    reg8A, A                ; non-zero means error
            
            ;- deselect and flush ----------------------------------------------
init_exit:  bsf     PERIF_LAT, nSDC, A      ; deselect SD card
            
            setf    SSP1BUF                 ; send dummy data
            spi_wait                        ; wait for transfer to complete
            movf    SSP1BUF, W, A           ; clear BF flag
            
            movf    reg8A, W, A             ; status in W
            return


;= SD CARD READ BLOCK ==========================================================
; Initialize the SD card.
;
; Parameters:
;   reg32A - SD card block address.
;
; Returns:
;   W - status.
;
; Remarks:
;   This function reads a single 512 byte block from a SD card. It returns zero
;   if successful and non-zero if unsuccesful.

sdc_rd_blk: lfsr    FSR0, abySDCData        ; FSR0->location to save data
            bcf     PERIF_LAT, nSDC, A      ; select SD card
            
            ;- read block ------------------------------------------------------
rd_blk_cmd: setf    reg8B, A                ; dummy CRC
            movlw   SDC_CMD17               ; READ_SINGLE_BLOCK
            rcall   sdc_cmd                 ; send command to SD card
            tstfsz  WREG, A                 ; zero means success
            bra     rd_fail                 ; branch if failure
            
            ;- get data token --------------------------------------------------
get_token:  setf    SSP1BUF,A               ; send dummy data
            spi_wait                        ; wait for transfer to complete
            movlw   DATATKN                 ; data start token
            cpfseq  SSP1BUF, A              ; compare response with data token
            bra     get_token               ; branch if not equal
            
            ;- get data --------------------------------------------------------
            clrf    reg16A, A               ; reg16A is the byte counter
            movlw   high .512
            movwf   reg16A+1, A             ; 512 bytes to receive
get_data:   setf    SSP1BUF, A              ; send dummy data
            spi_wait                        ; wait for transfer to complete
            movff   SSP1BUF, POSTINC0       ; save received byte and clear BF
            
            decf    reg16A, F, A            ; decrement byte counter
            movlw   0x00
            subwfb  reg16A+1, F, A
            
            tstfsz  reg16A+1, A             ; check if byte counter MSB == 0
            bra     get_data                ; nope, keep getting data
            tstfsz  reg16A, A               ; check if byte counter LSB == 0
            bra     get_data                ; nope, keep getting data
            
            ;- get CRC bytes ---------------------------------------------------
get_CRC:    setf    SSP1BUF, A              ; send dummy data
            spi_wait                        ; wait for transfer to complete
            movf    SSP1BUF, W, A           ; clear BF flag
            
            setf    SSP1BUF, A              ; send dummy data
            spi_wait                        ; wait for transfer to complete
            movf    SSP1BUF, W, A           ; clear BF flag
            
            clrf    reg8A, A                ; success!
            bra     rd_exit                 ; clean up
            
            ;- fail to read ----------------------------------------------------
rd_fail:    setf    reg8A, A                ; non-zero means error
            
            ;- deselect and flush ----------------------------------------------
rd_exit:    bsf     PERIF_LAT, nSDC, A      ; deselect SD card
            
            setf    SSP1BUF                 ; send dummy data
            spi_wait                        ; wait for transfer to complete
            movf    SSP1BUF, W, A           ; clear BF flag
            
            movf    reg8A, W, A             ; status in W
            return


;= SD CARD BLOCK DATA ==========================================================

SDCDATA     UDATA

abySDCData: res     .512                    ; location for SD card block data


;===============================================================================

            END
