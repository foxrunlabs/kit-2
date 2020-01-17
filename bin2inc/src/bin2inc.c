/*******************************************************************************
 *  Copyright 2020 Ryan Clarke
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may not
 *  use this file except in compliance with the License. You may obtain a copy
 *  of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 *  License for the specific language governing permissions and limitations
 *  under the License.
 ******************************************************************************/

/*******************************************************************************
 *  Program   : bin2inc
 *  File Name : bin2inc.c
 *  Project   : Kit-2 8-bit Computer
 *  Author    : Ryan Clarke
 *  E-mail    : kj6msg@icloud.com
 *  ----------------------------------------------------------------------------
 *  Purpose   : Converts the KitBIOS .bin file to a PIC assembly include file
 *              for implementation in the KitPIC module.
 ******************************************************************************/
 

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/errno.h>
#include <sys/stat.h>


#define FILEHEADER "\
;===============================================================================\n\
; Copyright 2020 Ryan Clarke\n\
; \n\
; Licensed under the Apache License, Version 2.0 (the \"License\"); you may not\n\
; use this file except in compliance with the License. You may obtain a copy of\n\
; the License at\n\
; \n\
;     http://www.apache.org/licenses/LICENSE-2.0\n\
; \n\
; Unless required by applicable law or agreed to in writing, software\n\
; distributed under the License is distributed on an \"AS IS\" BASIS, WITHOUT\n\
; WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the\n\
; License for the specific language governing permissions and limitations under\n\
; the License.\n\
;===============================================================================\n\
\n\
;===============================================================================\n\
; Program   : KitBIOS\n\
; File Name : kitbios.inc\n\
; Project   : Kit-2 8-bit Computer\n\
; Device    : PIC18F47K40\n\
; Author    : Ryan Clarke\n\
; E-mail    : kj6msg@icloud.com\n\
;-------------------------------------------------------------------------------\n\
; Purpose   : BIOS image for the Kit-2 8-bit computer.\n\
;===============================================================================\n\
\n\
\n\
BIOS_ADDR equ 0x%04X\n\
\n\
BIOS_DATA   macro\n\
\n"

#define DATAFORMAT "\
            db      0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X\n"

int main(int argc, char *argv[])
{
    uint8_t  *buf;
    uint16_t start;
    int      i;
    FILE     *file_in;
    FILE     *file_out;
    struct   stat st;
    
    /* must supply two arguments */
    if((argc == 1) || (argc > 3))
    {
        fprintf(stderr, "usage: %s infile outfile\n", argv[0]);
        return EXIT_FAILURE;
    }
    
    /* open input file */
    if((file_in = fopen(argv[1], "rb")) == NULL)
    {
        fprintf(stderr, "%s: %s: No such file or directory\n", argv[0], argv[1]);
        return EXIT_FAILURE;
    }
    
    /* get input file stats */
    if(stat(argv[1], &st) != 0)
    {
        fprintf(stderr, "%s: %s: error %d\n", argv[0], argv[1], errno);
        fclose(file_in);
        return EXIT_FAILURE;
    }
    
    /* input file must be greater than 256 bytes and less than 64768 bytes */
    if((st.st_size < 256) || (st.st_size > 64768))
    {
        fprintf(stderr, "%s: %s: size must be between 256 and 64768 bytes\n", argv[0], argv[1]);
        fclose(file_in);
        return EXIT_FAILURE;
    }
    
    /* input file must be a multiple of 256 bytes */
    if(st.st_size % 256)
    {
        fprintf(stderr, "%s: %s: size must be a multiple of 256\n", argv[0], argv[1]);
        fclose(file_in);
        return EXIT_FAILURE;
    }
    
    /* create output file */
    if((file_out = fopen(argv[2], "wb")) == NULL)
    {
        fprintf(stderr, "%s: %s: unable to create file\n", argv[0], argv[2]);
        fclose(file_in);
        return EXIT_FAILURE;
    }
    
    /* allocate buffer for input file data */
    if((buf = malloc((size_t)st.st_size * sizeof(uint8_t))) == NULL)
    {
        fprintf(stderr, "%s: insufficent memory\n", argv[0]);
        fclose(file_in);
        fclose(file_out);
        return EXIT_FAILURE;
    }
    
    fread(buf, sizeof(uint8_t), (size_t)st.st_size, file_in);
    
    /* compute starting address of BIOS in Kit-2 RAM space */
    start = (uint16_t)(0x10000 - st.st_size);
    fprintf(file_out, FILEHEADER, start);
    
    /* convert individual bytes to hexadecimal format */
    for(i = 0; i < st.st_size; i += 8)
    {
        fprintf(file_out, DATAFORMAT, buf[i], buf[i+1], buf[i+2], buf[i+3],
                                      buf[i+4], buf[i+5], buf[i+6], buf[i+7]);
    }
    
    fputs("\n            endm\n", file_out);
    
    free(buf);
    fclose(file_in);
    fclose(file_out);
    
    return EXIT_SUCCESS;
}
