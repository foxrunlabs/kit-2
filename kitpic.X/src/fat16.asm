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
; Program   : KitPIC
; File Name : fat16.asm
; Project   : Kit-2 8-bit Computer
; Author    : Ryan Clarke
; E-mail    : kj6msg@icloud.com
;-------------------------------------------------------------------------------
; Purpose   : KitPIC FAT16 routines.
;===============================================================================


#include "p18f47k40.inc"
#include "kitpic.inc"
#include "sdcard.inc"
#include "fat16.inc"


;===============================================================================
; IMPORTS/EXPORTS
;===============================================================================

            extern  reg8A, reg16A, reg32A
            extern  reg8B, reg16B, reg32B
            extern  reg8C, reg16C, reg32C
            
            extern  sdc_rd_blk
            extern  abySDCData
            
            extern  uart_write
            
            global  fat16_init
            global  find_kitos
            global  load_kitos
            
            
;===============================================================================
; FAT16 ROUTINES
;===============================================================================

            CODE


;= FAT16 INIT ==================================================================
; Initialize FAT16 volume.
;
; Parameters:
;   none.
;
; Returns:
;   W = status.
;
; Remarks:
;   This function loads the master boot record from a SD card, verifies the
;   first partition is FAT16, loads the boot sector, and then computes the FAT,
;   root directory, and data regions. It returns zero if successful and
;   returns non-zero if unsuccessful.

fat16_init: ;- read master boot record -----------------------------------------
            clrf    reg32A, A               ; MBR at sector 0x00000000
            clrf    reg32A+1, A
            clrf    reg32A+2, A
            clrf    reg32A+3, A
            call    sdc_rd_blk              ; read block
            
            tstfsz  WREG, A                 ; zero equals success
            retlw   0xFF                    ; exit with error if > 0
            
            ;- verify master boot record boot signature ------------------------
mbr_sig:    lfsr    FSR0, wMBRSig           ; FSR0->boot signature
            movlw   low SIGNATURE
            cpfseq  POSTINC0, A             ; check LSB of signature
            retlw   0xFF                    ; exit with error if not valid
            
            movlw   high SIGNATURE
            cpfseq  INDF0, A                ; check MSB of signature
            retlw   0xFF                    ; exit with error if not valid
            
            ;- check first partition -------------------------------------------
part1_type: lfsr    FSR0, byPart1Type       ; FSR0->parition type
            movlw   FAT16ID
            cpfseq  INDF0, A                ; check if FAT16 type
            retlw   0xFF                    ; return with error if not FAT16
            
            ;- load FAT16 boot sector ------------------------------------------
load_boot:  lfsr    FSR0, dwPart1Addr       ; FSR0->partition 1 boot sector
            movff   POSTINC0, dwBootAddr
            movff   POSTINC0, dwBootAddr+1
            movff   POSTINC0, dwBootAddr+2
            movff   INDF0, dwBootAddr+3
            
            movff   dwBootAddr, reg32A      ; load boot sector
            movff   dwBootAddr+1, reg32A+1
            movff   dwBootAddr+2, reg32A+2
            movff   dwBootAddr+3, reg32A+3
            call    sdc_rd_blk              ; read block
            
            tstfsz  WREG, A                 ; zero equals success
            retlw   0xFF                    ; exit with error if > 0
            
            ;- verify boot sector boot signature -------------------------------
boot_sig:   lfsr    FSR0, wBootSig          ; FSR0->boot signature
            movlw   low SIGNATURE
            cpfseq  POSTINC0, A             ; check LSB of signature
            retlw   0xFF                    ; exit with error if not valid
            
            movlw   high SIGNATURE
            cpfseq  INDF0, A                ; check MSB of signature
            retlw   0xFF                    ; exit with error if not valid
            
            ;- verify 512 bytes per logical sector -----------------------------
bytes_sec:  lfsr    FSR0, wBytesPerSec      ; FSR0->bytes/logical sec.
            movlw   low 0x200               ; must be 512 bytes
            cpfseq  POSTINC0, A             ; LSB of bytes per logical sector
            retlw   0xFF                    ; exit with error if not equal
            
            movlw   high 0x200
            cpfseq  INDF0, A                ; MSB of bytes per logical sector
            retlw   0xFF                    ; exit with error if not equal
            
            ;- compute FAT region starting address -----------------------------
fat_region: lfsr    FSR0, wRsrvSec          ; FSR0->reserved logical sectors
            movf    POSTINC0, W, A
            banksel dwBootAddr
            addwf   dwBootAddr, W           ; add to boot sector address
            movwf   dwFATAddr               ; store into FAT address
            movf    INDF0, W, A
            addwfc  dwBootAddr+1, W
            movwf   dwFATAddr+1
            movlw   0x00
            addwfc  dwBootAddr+2, W
            movwf   dwFATAddr+2
            movlw   0
            addwfc  dwBootAddr+3, W
            movwf   dwFATAddr+3
            
            ;- compute root directory region starting address ------------------               
            movff   dwFATAddr, dwRootAddr   ; copy FAT address to root address
            movff   dwFATAddr+1, dwRootAddr+1
            movff   dwFATAddr+2, dwRootAddr+2
            movff   dwFATAddr+3, dwRootAddr+3
            
            lfsr    FSR0, byNumFATs         ; FSR0->number of FATs
            movff   INDF0, reg8A            ; use as a counter
            lfsr    FSR0, wSecPerFAT        ; FSR0->sectors per FAT
root_reg:   movf    POSTINC0, W, A
            addwf   dwRootAddr, F           ; add to root address
            movf    POSTDEC0, W, A
            addwfc  dwRootAddr+1, F
            movlw   0
            addwfc  dwRootAddr+2, F
            addwfc  dwRootAddr+3, F
            
            decf    reg8A, F, A             ; decrement FAT counter
            bnz     root_reg                ; branch if > 0
            
            ;- compute root directory region size ------------------------------
root_size:  lfsr    FSR0, wNumRoot          ; FSR0->number of root entries
            movff   POSTINC0, reg16A        ; save a copy into reg16A
            movff   INDF0, reg16A+1
            
            movlw   5                       ; multiply by 32
shift:      bcf     STATUS, C, A
            rlcf    reg16A, F, A            ; reg16A << 1
            rlcf    reg16A+1, F, A
            
            decf    WREG, W, A              ; decrement shift counter
            bnz     shift                   ; branch if > 0
            
            bcf     STATUS, C, A            ; clear carry
            rrcf    reg16A+1, W, A          ; divide by 512
            movwf   byRootSize              ; save to root size variable
                        
            ;- compute data region starting address ----------------------------
data_reg:   addwf   dwRootAddr, W           ; add number of root sectors with
            movwf   dwDataAddr              ; root region start and store in
            movlw   0                       ; data region start
            addwfc  dwRootAddr+1, W
            movwf   dwDataAddr+1
            movlw   0
            addwfc  dwRootAddr+2, W
            movwf   dwDataAddr+2
            movlw   0
            addwfc  dwRootAddr+3, W
            movwf   dwDataAddr+3
            
            retlw   0                       ; success!


;= FIND KITOS ==================================================================
; Find KitOS in the FAT16 file system.
;
; Parameters:
;   none.
;
; Returns:
;   reg16A = starting cluster.
;   reg32B = file size
;
; Remarks:
;   This function finds KitOS in the root directory of a FAT16 volume. It
;   returns the starting cluster of the file, or zero on error.

find_kitos: movff   dwRootAddr, reg32C      ; copy root dir. address to reg32C
            movff   dwRootAddr+1, reg32C+1
            movff   dwRootAddr+2, reg32C+2
            movff   dwRootAddr+3, reg32C+3

            ; load block from root directory region
load_block: movff   reg32C, reg32A          ; start at beginning of root dir.
            movff   reg32C+1, reg32A+1
            movff   reg32C+2, reg32A+2
            movff   reg32C+3, reg32A+3
            call    sdc_rd_blk              ; read block
            
            tstfsz  WREG, A                 ; zero equals success
            bra     not_found               ; exit with error if > 0
            
            ;- search through directory entries for file -----------------------
new_block:  lfsr    FSR0, abySDCData        ; FSR0->first root dir. entry of blk
            movlw   .16                     ; 16 entries per sector
            movwf   reg8A, A                ; directory entry counter
            
new_entry:  movlw   low sFilename           ; TBLPTR->KitOS filename
            movwf   TBLPTRL, A
            movlw   high sFilename
            movwf   TBLPTRH, A
            movlw   upper sFilename
            movwf   TBLPTRU, A
            
            movlw   .11                     ; 11 characters per filename
            movwf   reg8B, A                ; character counter
compare:    movf    POSTINC0, W, A          ; read char from directory entry
            bz      not_found               ; branch if null
            
            tblrd   *+                      ; read char from desired filename
            cpfseq  TABLAT, A               ; compare characters for match
            bra     next_file               ; branch if not equal
            
            decf    reg8B, F, A             ; increment character counter
            bnz     compare                 ; branch if characters remaining
            
            ;- get starting cluster --------------------------------------------
cluster:    movlw   b'11100000'
            andwf   FSR0L, F, A             ; reset FSR0 to begin of dir. entry
            
            movlw   CLUSTOFF
            addwf   FSR0L, F, A
            movlw   0
            addwfc  FSR0H, F, A             ; FSR0->first cluster of dir. entry
            
            movff   POSTINC0, reg16A
            movff   POSTINC0, reg16A+1      ; reg16A = 1st cluster of dir. entry
            
            movff   POSTINC0, reg32B
            movff   POSTINC0, reg32B+1
            movff   POSTINC0, reg32B+2
            movff   INDF0, reg32B+3         ; reg32B = file size
            
            return
            
            ;- search next directory entry -------------------------------------
next_file:  decf    reg8A, F, A             ; decrement entry counter
            bz      next_block              ; branch if no more entries in block
            
            movlw   b'11100000'
            andwf   FSR0L, F, A             ; reset FSR0 to begin of dir. entry
            movlw   .32                     ; each directory entry is 32 bytes
            addwf   FSR0L, F, A             ; add to FSR0
            movlw   0                       ; 16-bit addition
            addwfc  FSR0H, F, A
            
            bra     new_entry               ; check new directory entry
                        
            ;- load next sector of root directory region -----------------------
            banksel byRootSize
next_block: decf    byRootSize, F           ; using root size as a block counter
            bz      not_found               ; branch if no more root entries
            
            incf    reg32C, F, A            ; increment root region block
            movlw   0
            addwfc  reg32C+1, F, A
            addwfc  reg32C+2, F, A
            addwfc  reg32C+3, F, A
            
            bra     load_block              ; branch to load the new block
            
            ;- file not found --------------------------------------------------
not_found:  clrf    reg16A, A               ; 0x0000 equals failure
            clrf    reg16A+1, A
            
            return
            

;= LOAD KITOS ==================================================================
; Load KitOS into external RAM.
;
; Parameters:
;   reg16A = starting cluster of KitOS.
;
; Returns:
;   W = status.
;
; Remarks:
;   This function reads KitOS into RAM. It returns zero if successful or non-
;   zero if unsuccessful.

load_kitos: movff   reg16A, reg16C          ; save a copy of starting cluster
            movff   reg16A+1, reg16C+1
            
            ;- load FAT sector for cluster -------------------------------------
load_FAT:   movf    reg16C+1, W, A          ; sector = cluster / 256
            banksel dwFATAddr
            addwf   dwFATAddr, W            ; add computed sector to FAT start
            movwf   reg32A, A
            movlw   0
            addwfc  dwFATAddr+1, W
            movwf   reg32A+1, A
            movlw   0
            addwfc  dwFATAddr+2, W
            movwf   reg32A+2, A
            movlw   0
            addwfc  dwFATAddr+3, W
            movwf   reg32A+3, A
            call    sdc_rd_blk              ; read block
            
            tstfsz  WREG, A                 ; zero equals success
            retlw   0xFF                    ; exit with error if > 0
            
            ;- compute offset into data region ---------------------------------
data_off:   movlw   2                       ; adjust cluster by 2, because first
            subwf   reg16C, W, A            ; two clusters aren't valid
            movwf   reg16A, A               ; store in reg16A for SD card block
            movlw   0                       ; read
            subwfb  reg16C+1, W, A
            movwf   reg16A+1, A
            
            ;- compute RAM address of cluster ----------------------------------
            bcf     STATUS, C, A
            rlcf    reg16C, F, A            ; address = cluster(LSB) * 2
            clrf    reg16C+1, A             ; LSB is only one that matters
            rlcf    reg16C+1, F, A
            
            ;- get cluster value -----------------------------------------------
            lfsr    FSR0, abySDCData        ; FSR0->loaded FAT sector
            movf    reg16C, W, A            ; adjust FSR0 to point at correct
            addwf   FSR0L, F, A             ; cluster
            movf    reg16C+1, W, A
            addwfc  FSR0H, F, A             ; FSR0->FAT sector + cluster number
            
            movff   POSTINC0, reg16C
            movff   INDF0, reg16C+1         ; reg16C = cluster value
            
            ;- check for bad sector --------------------------------------------
            movlw   low BADSECTOR
            cpfseq  reg16C, A               ; compare cluster with bad sec. val
            bra     load_data               ; branch if not a bad sector
            movlw   high BADSECTOR
            cpfseq  reg16C+1, A             ; compare cluster with bad sec. val
            bra     load_data               ; branch if not a bad sector
            
            retlw   0xFF                    ; exit with error if bad sector
            
            ;- retrieve cluster data from data region --------------------------
            banksel dwDataAddr
load_data:  movf    reg16A, W, A            ; add cluster offset to data region
            addwf   dwDataAddr, W           ; starting address
            movwf   reg32A, A
            movf    reg16A+1, W, A
            addwfc  dwDataAddr+1, W
            movwf   reg32A+1, A
            movlw   0
            addwfc  dwDataAddr+2, W
            movwf   reg32A+2, A
            movlw   0
            addwfc  dwDataAddr+3, W
            movwf   reg32A+3, A
            call    sdc_rd_blk              ; read block
            
            tstfsz  WREG, A                 ; zero equals success
            retlw   0xFF                    ; exit with error if > 0
            
            ;- write to external RAM -------------------------------------------
write_ram:  lfsr    FSR0, abySDCData        ; FSR0->file data
            
            setf    DB_TRIS, A              ; release data bus to RAM
            bcf     PERIF_LAT, nRAM, A      ; select RAM, currently in read mode
            
            ;- copy image data from ROM to external RAM ------------------------
            clrf    reg8B, A
            clrf    reg8B+1, A              ; reg8B = 512 byte counter
load_loop:  movff   POSTINC0, DB_LAT        ; (11R) read file data, put on bus
            
            bcf     PERIF_LAT, RnW, A       ; (12R) set write mode
            clrf    DB_TRIS, A              ; (1W) take control of data bus
            
            nop                             ; (2W) timing adjustment
            nop                             ; (3W) timing adjustment
            
            bsf     PERIF_LAT, RnW, A       ; (4W) set read mode
            setf    DB_TRIS, A              ; (1R) release data bus to RAM
            
            incf    AB_LAT_L, F, A          ; (2R) increment address LSB
            movlw   0                       ; (3R) 16-bit addition
            addwfc  AB_LAT_H, F, A          ; (4R) increment address MSB
            
            incf    reg8B, F, A             ; (5R) increment byte counter LSB
            addwfc  reg8B+1, F, A           ; (6R) increment byte counter MSB
            
            btfss   reg8B+1, 1, A           ; (7R) check if 512 bytes loaded
            bra     load_loop               ; (9R) branch if < 512 bytes
            
            bsf     PERIF_LAT, nRAM, A      ; deselect RAM
            clrf    DB_TRIS, A              ; take back data bus
            
            movlw   '.'
            call    uart_write              ; write dot to terminal
            
            ;- check for end of cluster chain ----------------------------------
chk_high:   movlw   high 0xFFF0             ; verify next cluster is less than 
            cpfseq  reg16C+1, A             ; 0xFFF0. If it is not, then it is
            bra     chk_low                 ; the end of the cluster chain.
            movlw   low 0xFFF0
            cpfslt  reg16C, A
            retlw   0                       ; success!
            
chk_low:    movlw   high 0x0002             ; verify next cluster is greater
            cpfseq  reg16C+1, A             ; than 0x0001. If it is not, then it
            bra     load_FAT                ; is the end of the cluster chain.
            movlw   low 0x0002
            cpfslt  reg16C, A
            bra     load_FAT
            retlw   0                       ; success


;===============================================================================
; UNINITIALIZED INTERNAL RAM
;===============================================================================

;= LOCAL VARIABLES =============================================================

BSS         UDATA

dwBootAddr: res     4                       ; boot sector address
dwFATAddr:  res     4                       ; FAT region start address
dwRootAddr: res     4                       ; root directory region start addr
dwDataAddr: res     4                       ; data region start address

byRootSize: res     1                       ; root directory region size in sec.


;===============================================================================
; READ ONLY DATA - PROGRAM ROM
;===============================================================================

RODATA      CODE_PACK

sFilename:  db      "KITOS   BIN"           ; filename of KitOS


;===============================================================================

            END
