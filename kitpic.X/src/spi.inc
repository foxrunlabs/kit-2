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
; File Name : spi.inc
; Project   : Kit-2 8-bit Computer
; Device    : PIC18F47K40
; Author    : Ryan Clarke
; E-mail    : kj6msg@icloud.com
;-------------------------------------------------------------------------------
; Purpose   : SPI macros for KitPIC.
;===============================================================================


;===============================================================================
; SPI CLOCK RATES
;===============================================================================

S100K equ .159                              ; 100 kHz
S1M   equ .15                               ; 1 MHz


;===============================================================================
; SPI MACROS
;===============================================================================

;= SPI WAIT ====================================================================
; Wait for a complete SPI transfer.
;
; Parameters:
;   none.
;
; Returns:
;   none.
;
; Remarks:
;   This macro polls the BF bit of SSP1STAT to wait for a complete transfer.

spi_wait    MACRO
            
            btfss   SSP1STAT, BF, A         ; poll BF flag for complete xfer
            bra     $ - 2                   ; branches to previous instruction 
            
            ENDM
