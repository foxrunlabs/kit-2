# KitBIOS

## Description:
BIOS source for the Kit-2 8-bit computer.

### BIOS Calls:
0. Reset
1. Write Character to Terminal
2. Write String to Terminal
3. Read Character from Terminal (No Echo)

### KitMon Functions:
* D  - dump
* E  - enter
* F  - fill
* J  - jump
* R  - registers
* S  - stack
* ?  - help
* ^R - reset

Terminal setup should be 57600 8-N-1, no echo, VT100 emulation, return key sends
LF, interpret standalone LF as CRLF. To view the help menu, type ```?``` and
press enter. All parameters are in hexadecimal format. Address ranges are
separated by a space.

### Legal:
The project is Copyright 2020 Ryan Clarke, licensed under the Apache License
version 2.0.
