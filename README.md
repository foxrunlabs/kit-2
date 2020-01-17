# Kit-2 8-bit Computer

## Description:
The Kit-2 is an 8-bit computer based on the 65C02 CPU. Specifications include:

* WDC W65C02 CPU
* Microchip PIC18F47K40 microcontroller
* Alliance AS6C1008 128 KiB SRAM (64 KiB usable)
* 1 MHz system clock generated from PIC
* UART via PIC
* microSD card reader via PIC

## Boot Sequence
The Kit-2 is initially held in reset by the PIC upon power-up or hard reset.
During this reset period, the PIC loads the SRAM with a full 64 KiB image. Once
this is complete, the PIC releases the bus and changes roles to a peripheral
controller. The BIOS initializes the peripherals and searches for a valid KitOS
file on the SD card. If KitOS is not found, then the BIOS will launch the ROM
monitor.

## Getting Started
The firmware and software can be built by issuing the ```make``` command in the
project root directory. This will build the tool chain, BIOS, PIC firmware, and
KitOS. Program the PIC18F47K40 with the firmware and copy KitOS to the root
directory of a FAT16 partition on a microSD card.  

To create a simulator version of the BIOS for py65mon, execute ```make sim```
and then execute ```./simulate.sh```.

### Legal:
The source code is Copyright 2019 Ryan Clarke, licensed under the Apache License
version 2.0. A copy of the license is found in the ```doc/``` directory.
