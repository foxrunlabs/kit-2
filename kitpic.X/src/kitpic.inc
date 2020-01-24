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
; File Name : kitpic.inc
; Project   : Kit-2 8-bit Computer
; Device    : PIC18F47K40
; Author    : Ryan Clarke
; E-mail    : kj6msg@icloud.com
;-------------------------------------------------------------------------------
; Purpose   : Pin mapping for KitPIC.
;===============================================================================


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
#define SDO1 RB1                            ; PIC -> SD card
#define SDI1 RB2                            ; SD card -> PIC
#define SCK1 RB3                            ; SPI clock
#define RX1  RB4                            ; FTDI USB-to-Serial -> PIC
#define TX1  RB5                            ; PIC -> FTDI USB-to-Serial
#define nRAM RB6                            ; RAM chip select
#define RnW  RB7                            ; R/W signal
