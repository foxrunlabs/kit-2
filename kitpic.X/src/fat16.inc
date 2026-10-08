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
; File Name : fat16.inc
; Project   : Kit-2 8-bit Computer
; Device    : PIC18F47K40
; Author    : Ryan Clarke
; E-mail    : kj6msg@icloud.com
;-------------------------------------------------------------------------------
; Purpose   : FAT16 constants for KitPIC.
;===============================================================================


;= CONSTANTS ===================================================================

SIGNATURE equ 0xAA55            ; boot signature
BADSECTOR equ 0xFFF7            ; bad sector marker
FAT16ID   equ 0x06              ; FAT16 partition ID


;= MASTER BOOT RECORD ==========================================================

PART1     equ 0x1BE             ; partition 1 location in MBR
PART1TYPE equ PART1 + 0x004     ; partition 1 type
PART1ADDR equ PART1 + 0x008     ; partition 1 first sector LBA

MBRSIG    equ 0x1FE             ; MBR boot signature location in MBR

#define byPart1Type (abySDCData + PART1TYPE)
#define dwPart1Addr (abySDCData + PART1ADDR)
#define wMBRSig (abySDCData + MBRSIG)


;= BOOT SECTOR =================================================================

BPB         equ 0x00B
BYTESPERSEC equ BPB             ; bytes per logical sector (16-bit)
RSRVSEC     equ BPB + 0x003     ; number of reserved sectors (16-bit)
NUMFATS     equ BPB + 0x005     ; number of FATs (8-bit)
NUMROOT     equ BPB + 0x006     ; number of root directory entries (16-bit)
SECPERFAT   equ BPB + 0x00B     ; number of logical sectors per FAT (16-bit)

BOOTSIG     equ 0x1FE           ; boot sector signature location in boot sector

#define wBytesPerSec (abySDCData + BYTESPERSEC)
#define wRsrvSec (abySDCData + RSRVSEC)
#define byNumFATs (abySDCData + NUMFATS)
#define wSecPerFAT (abySDCData + SECPERFAT)
#define wNumRoot (abySDCData + NUMROOT)
#define wBootSig (abySDCData + BOOTSIG)


;= DIRECTORY ENTRY =============================================================

CLUSTOFF equ 0x1A               ; location of first cluster in directory entry
SIZEOFF  equ 0x1C               ; location of file size in directory entry
