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
; File Name : uart.asm
; Project   : Kit-2 8-bit Computer
; Device    : PIC18F47K40
; Author    : Ryan Clarke
; E-mail    : kj6msg@icloud.com
;-------------------------------------------------------------------------------
; Purpose   : UART routines for the KitPIC RAM loader and peripheral controller.
;===============================================================================


#include "p18f47k40.inc"


;===============================================================================
; IMPORTS/EXPORTS
;===============================================================================

            extern  reg8A, reg16A, reg32A
            extern  reg8B, reg16B, reg32B
            
            global  uart_write
            global  uart_puts


;===============================================================================
; UART ROUTINES
;===============================================================================

            CODE


;= UART WRITE ==================================================================
; Write a byte to the UART.
;
; Parameters:
;   W - byte.
;
; Returns:
;   none.
;
; Remarks:
;   This function writes a byte directly to the UART.

uart_write: movlb   high PIR3               ; select appropriate bank
            btfss   PIR3, TX1IF             ; test if TX1REG is empty
            bra     $ - 2                   ; skipped if empty
            
            movwf   TX1REG, A               ; write byte to UART
            
            return


;= UART PUTS====================================================================
; Write a string to the UART.
;
; Parameters:
;   TBLPTR - pointer to null terminated string.
;
; Returns:
;   none.
;
; Remarks:
;   This function writes a null terminated string to the UART.

uart_puts:  tblrd   *+
            movf    TABLAT, W, A            ; retrieve character
            bz      $ + 8                   ; branch if null
            
            call    uart_write              ; write the character
            bra     uart_puts               ; keep writing
            
            return


;===============================================================================

            END
