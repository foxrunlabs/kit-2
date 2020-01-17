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
; File Name : config.inc
; Project   : Kit-2 8-bit Computer
; Device    : PIC18F47K40
; Author    : Ryan Clarke
; E-mail    : kj6msg@icloud.com
;-------------------------------------------------------------------------------
; Purpose   : Configuration bits for KitPIC.
;===============================================================================


;===============================================================================
; CONFIGURATION BITS
;===============================================================================

;- CONFIG1L --------------------------------------------------------------------
            config  FEXTOSC = OFF               ; External Oscillator mode Selection bits (Oscillator not enabled)
            config  RSTOSC  = HFINTOSC_64MHZ    ; Power-up default value for COSC bits (HFINTOSC with HFFRQ = 64 MHz and CDIV = 1:1)

;- CONFIG1H --------------------------------------------------------------------
            config  CLKOUTEN = OFF              ; Clock Out Enable bit (CLKOUT function is disabled)
            config  CSWEN    = OFF              ; Clock Switch Enable bit (The NOSC and NDIV bits cannot be changed by user software)
            config  FCMEN    = OFF              ; Fail-Safe Clock Monitor Enable bit (Fail-Safe Clock Monitor disabled)

;- CONFIG2L --------------------------------------------------------------------
            config  MCLRE   = EXTMCLR           ; Master Clear Enable bit (If LVP = 0, MCLR pin is MCLR; If LVP = 1, RE3 pin function is MCLR )
            config  PWRTE   = OFF               ; Power-up Timer Enable bit (Power up timer disabled)
            config  LPBOREN = OFF               ; Low-power BOR enable bit (ULPBOR disabled)
            config  BOREN   = OFF               ; Brown-out Reset Enable bits (Brown-out Reset disabled)

;- CONFIG2H --------------------------------------------------------------------
            config  BORV    = VBOR_2P45         ; Brown Out Reset Voltage selection bits (Brown-out Reset Voltage (VBOR) set to 2.45V)
            config  ZCD     = OFF               ; ZCD Disable bit (ZCD disabled. ZCD can be enabled by setting the ZCDSEN bit of ZCDCON)
            config  PPS1WAY = OFF               ; PPSLOCK bit One-Way Set Enable bit (PPSLOCK bit can be set and cleared repeatedly (subject to the unlock sequence))
            config  STVREN  = ON                ; Stack Full/Underflow Reset Enable bit (Stack full/underflow will cause Reset)
            config  DEBUG   = OFF               ; Debugger Enable bit (Background debugger disabled)
            config  XINST   = OFF               ; Extended Instruction Set Enable bit (Extended Instruction Set and Indexed Addressing Mode disabled)

;- CONFIG3L --------------------------------------------------------------------
            config  WDTCPS = WDTCPS_31          ; WDT Period Select bits (Divider ratio 1:65536; software control of WDTPS)
            config  WDTE   = OFF                ; WDT operating mode (WDT Disabled)

;- CONFIG3H --------------------------------------------------------------------
            config  WDTCWS = WDTCWS_7           ; WDT Window Select bits (window always open (100%); software control; keyed access not required)
            config  WDTCCS = SC                 ; WDT input clock selector (Software Control)

;- CONFIG4L --------------------------------------------------------------------
            config  WRT0 = OFF                  ; Write Protection Block 0 (Block 0 (000800-003FFFh) not write-protected)
            config  WRT1 = OFF                  ; Write Protection Block 1 (Block 1 (004000-007FFFh) not write-protected)
            config  WRT2 = OFF                  ; Write Protection Block 2 (Block 2 (008000-00BFFFh) not write-protected)
            config  WRT3 = OFF                  ; Write Protection Block 3 (Block 3 (00C000-00FFFFh) not write-protected)
            config  WRT4 = OFF                  ; Write Protection Block 3 (Block 4 (010000-013FFFh) not write-protected)
            config  WRT5 = OFF                  ; Write Protection Block 3 (Block 5 (014000-017FFFh) not write-protected)
            config  WRT6 = OFF                  ; Write Protection Block 3 (Block 6 (018000-01BFFFh) not write-protected)
            config  WRT7 = OFF                  ; Write Protection Block 3 (Block 7 (01C000-01FFFFh) not write-protected)

;- CONFIG4H --------------------------------------------------------------------
            config  WRTC  = OFF                 ; Configuration Register Write Protection bit (Configuration registers (300000-30000Bh) not write-protected)
            config  WRTB  = OFF                 ; Boot Block Write Protection bit (Boot Block (000000-0007FFh) not write-protected)
            config  WRTD  = OFF                 ; Data EEPROM Write Protection bit (Data EEPROM not write-protected)
            config  SCANE = OFF                 ; Scanner Enable bit (Scanner module is NOT available for use, SCANMD bit is ignored)
            config  LVP   = ON                  ; Low Voltage Programming Enable bit (Low voltage programming enabled. MCLR/VPP pin function is MCLR. MCLRE configuration bit is ignored)

;- CONFIG5L --------------------------------------------------------------------
            config  CP  = OFF                   ; UserNVM Program Memory Code Protection bit (UserNVM code protection disabled)
            config  CPD = OFF                   ; DataNVM Memory Code Protection bit (DataNVM code protection disabled)

;- CONFIG5H --------------------------------------------------------------------

;- CONFIG6L --------------------------------------------------------------------
            config  EBTR0 = OFF                 ; Table Read Protection Block 0 (Block 0 (000800-003FFFh) not protected from table reads executed in other blocks)
            config  EBTR1 = OFF                 ; Table Read Protection Block 1 (Block 1 (004000-007FFFh) not protected from table reads executed in other blocks)
            config  EBTR2 = OFF                 ; Table Read Protection Block 2 (Block 2 (008000-00BFFFh) not protected from table reads executed in other blocks)
            config  EBTR3 = OFF                 ; Table Read Protection Block 3 (Block 3 (00C000-00FFFFh) not protected from table reads executed in other blocks)
            config  EBTR4 = OFF                 ; Table Read Protection Block 4 (Block 4 (010000-013FFFh) not protected from table reads executed in other blocks)
            config  EBTR5 = OFF                 ; Table Read Protection Block 5 (Block 5 (014000-017FFFh) not protected from table reads executed in other blocks)
            config  EBTR6 = OFF                 ; Table Read Protection Block 6 (Block 6 (018000-01BFFFh) not protected from table reads executed in other blocks)
            config  EBTR7 = OFF                 ; Table Read Protection Block 7 (Block 7 (01C000-01FFFFh) not protected from table reads executed in other blocks)

;- CONFIG6H --------------------------------------------------------------------
            config  EBTRB = OFF                 ; Boot Block Table Read Protection bit (Boot Block (000000-0007FFh) not protected from table reads executed in other blocks)
