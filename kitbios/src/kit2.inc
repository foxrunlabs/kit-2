;===============================================================================
; Copyright 2020 Ryan Clarke
;
; Licensed under the Apache License, Version 2.0 (the "License"); you may not
; use this file except in compliance with the License. You may obtain a copy of
; the License at
; 
;     http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
; WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
; License for the specific language governing permissions and limitations under
; the License.
;===============================================================================

;===============================================================================
; Program   : KitBIOS
; File Name : kit1.inc
; Project   : Kit-2 8-bit Computer
; Author    : Ryan Clarke
; E-mail    : kj6msg@icloud.com
;-------------------------------------------------------------------------------
; Purpose   : Include file for KitBIOS and KitMon.
;===============================================================================


;===============================================================================
; ASCII CHARACTER CONSTANTS
;===============================================================================

NUL  = $00
SOH  = $01
_STX = $02
ETX  = $03
EOT  = $04
ENQ  = $05
ACK  = $06
BEL  = $07
BS   = $08
HT   = $09
LF   = $0A
VT   = $0B
FF   = $0C
CR   = $0D
SO   = $0E
SI   = $0F
DLE  = $10
DC1  = $11
DC2  = $12
DC3  = $13
DC4  = $14
NAK  = $15
SYN  = $16
ETB  = $17
CAN  = $18
EM   = $19
SUB  = $1A
ESC  = $1B
FS   = $1C
GS   = $1D
RS   = $1E
US   = $1F
DEL  = $7F


;===============================================================================
; ZERO PAGE MEMORY MAP
;===============================================================================

;= BIOS CALL TABLE =============================================================

papfnBIOSCallsL = $00           ; BIOS call table (LSBs) pointer
papfnBIOSCallsH = $02           ; BIOS call table (MSBs) pointer


;= BIOS ROUTINES ===============================================================

pszString = $04                 ; string pointer for cputs


;= KITMON ======================================================================

dwArg1  = $06                   ; command line arguments
dwArg2  = $0A

wPCreg  = $0E                   ; CPU register storage
byAreg  = $10
byXreg  = $11
byYreg  = $12
bySreg  = $13
byPreg  = $14

pabDump = $15                   ; pointer to data for dump command


;===============================================================================
; HARDWARE DEVICES
;===============================================================================

;= IO MEMORY MAP ===============================================================

IO = $0200

;- device 0 - UART -------------------------------------------------------------
UART        = IO + $00
UART_RC1REG = UART + $0
UART_TX1REG = UART + $1
UART_PIR3   = UART + $2
UART_RC1STA = UART + $3


;= UART ========================================================================

;- PIR3 flags ------------------------------------------------------------------
PIR3_RC1IF = %00100000
PIR3_TX1IF = %00010000

;- RC1STA flags ----------------------------------------------------------------
RC1STA_FERR = %00000100
RC1STA_OERR = %00000010
