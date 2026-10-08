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
; File Name : sdcard.inc
; Project   : Kit-2 8-bit Computer
; Device    : PIC18F47K40
; Author    : Ryan Clarke
; E-mail    : kj6msg@icloud.com
;-------------------------------------------------------------------------------
; Purpose   : SD card constants for KitPIC.
;===============================================================================


;= COMMANDS ====================================================================

SDC_CMD0   equ 0x40                 ; GO_IDLE_STATE
SDC_CMD1   equ 0x41                 ; SEND_OP_COND
SDC_CMD8   equ 0x48                 ; SEND_IF_COND
SDC_CMD16  equ 0x50                 ; SET_BLOCKLEN
SDC_CMD17  equ 0x51                 ; READ_SINGLE_BLOCK
SDC_CMD24  equ 0x58                 ; WRITE_BLOCK
SDC_ACMD41 equ 0x69                 ; APP_SEND_OP_COND
SDC_CMD55  equ 0x77                 ; APP_CMD
SDC_CMD58  equ 0x7A                 ; READ_OCR


;= RESPONSES ===================================================================

;- R1 response bits ------------------------------------------------------------
IDLE    equ 0x00                    ; idle state
ERASE   equ 0x01                    ; erase reset
ILLEGAL equ 0x02                    ; illegal command
COMCRC  equ 0x03                    ; com CRC error
SEQ     equ 0x04                    ; erase sequence error
ADDRESS equ 0x05                    ; address error
PARAM   equ 0x06                    ; parameter error

;- read/write block responses --------------------------------------------------
ACCEPT  equ 0x05                    ; data accepted
DATATKN equ 0xFE                    ; data packet token
