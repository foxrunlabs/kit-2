# Kit-2 8-bit Computer

Kit-2 is an experimental homebrew computer combining a **WDC W65C02 CPU** with a **Microchip PIC18F47K40 support controller**. The 65C02 runs the system software; the PIC loads SRAM at startup, controls reset and bus ownership, generates the CPU clock, and supplies memory-mapped serial I/O.

The project explores how a modern microcontroller can support a classic microprocessor while preserving its instruction set and programming model. It brings together bus timing, firmware for two processor architectures, and host-side development tools.

**Status:** experimental and incomplete. The repository contains KitBIOS, the KitMon machine monitor, and KitPIC controller firmware. The `kitos` branch adds an experimental SD/FAT16 boot loader, but neither `master` nor `kitos` contains a separate KitOS operating-system implementation. Build targets and source code describe the intended behavior; they do not establish a currently reproducible hardware build or validated SD boot.

## Hardware and architecture

| Component | Design |
| --- | --- |
| Primary processor | WDC W65C02 |
| Support controller | Microchip PIC18F47K40 |
| SRAM | Alliance AS6C1008, 128 KiB physical capacity |
| CPU address space | 64 KiB; no bank-switching implementation is provided |
| Clock | PIC software generates PHI2; nominal 1 MHz for ordinary RAM cycles |
| Serial | PIC EUSART, exposed to the CPU through memory-mapped registers |
| Storage | PIC-connected microSD interface; loader code is on `kitos` |
| Hardware documentation | Legacy KiCad schematic in `doc/schematic/` |

```text
                W65C02
                   |
          address / data / control
             /             \
           SRAM       PIC18F47K40
                      | reset and bus control
                      | software-generated PHI2
                      | UART
                      | SPI / microSD (kitos loader)
```

The PIC remains active after startup. Its clock/logic loop distinguishes SRAM accesses from accesses to I/O page `$02`, controls the SRAM chip select, and transfers data between the 65C02 bus and selected PIC registers. I/O cycles take longer than ordinary RAM cycles, so the CPU clock is not uniformly 1 MHz for every access.

The CPU has no permanently mapped physical ROM. Its initial firmware and interrupt vectors reside in SRAM. This does not make the whole CPU address space ordinary RAM: `$0200–$02FF` is intercepted for I/O during execution.

The KiCad PCB file is a dummy placeholder, not a completed board layout or fabrication package.

## Branches and boot paths

| | `master` (default) | `kitos` |
| --- | --- | --- |
| Initial memory image | Embedded in PIC program memory | Read from microSD |
| PIC entry source | `kitpic.X/src/kitpic.asm` | `kitpic.X/src/main.asm` |
| Image preparation | KitBIOS binary converted with `bin2inc` | Loader expects `KITOS.BIN` on FAT16 |
| Storage code | No SD/FAT16 loader | `sdcard.asm` and `fat16.asm` |
| Serial speed | 57600 baud | 115200 baud |
| 65C02 software | KitBIOS + KitMon | Identical KitBIOS + KitMon sources |
| Separate KitOS source or build target | Absent | Absent |

### Embedded-image boot on `master`

1. The PIC holds CPU reset and bus enable low and takes the address/data buses.
2. It configures the UART and its peripheral-register table.
3. It copies a 65,536-byte image from PIC program memory to SRAM, starting at `$0000`.
4. It releases the buses, enables CPU bus ownership, clocks five reset cycles, and releases reset.
5. The CPU starts through the reset vector and enters KitBIOS / KitMon. The PIC continues generating the clock and servicing I/O.

The build connects the two firmware architectures:

```text
65C02 assembly -> ca65 / ld65 -> kitbios/bin/kitbios.bin
                                      |
                                   bin2inc
                                      |
                           kitpic.X/src/kitbios.inc
                                      |
                            MPASM PIC firmware build
```

`bin2inc` requires an input of exactly 65,536 bytes. The embedded data is a complete CPU memory image, even though KitBIOS and KitMon occupy the upper 4 KiB region.

### Experimental SD boot on `kitos`

The PIC initializes SPI and the SD card, reads the MBR and FAT16 metadata, searches the root directory for the short filename `KITOS.BIN`, checks that the directory entry reports exactly 65,536 bytes, and attempts to load its contents into SRAM before releasing the CPU.

The filename is a loader convention. It does not imply that a separate KitOS implementation exists. The branch still builds `kitbios.bin`; it has no target that creates or copies `KITOS.BIN` to a card.

The loader has specific requirements and limitations:

- It reads the first MBR partition and accepts partition type **`0x06`**. It does not implement general FAT16 partition discovery or FAT32/exFAT support.
- It requires **512-byte logical sectors** and the root-directory short name **`KITOS   BIN`**.
- Its cluster-to-sector calculation and read loop assume **one 512-byte sector per cluster**, without validating the sectors-per-cluster field. A generic FAT16 format is therefore insufficient to establish compatibility.
- The SD driver does not determine card addressing mode through CMD58/OCR or convert sector numbers for byte-addressed cards. Card compatibility needs verification.
- Some polling loops have no timeout. Reported loading errors halt the PIC before CPU reset is released; other failures can leave it waiting indefinitely.
- The directory-entry size check is not a bounded 64 KiB transfer check. The loader follows the FAT chain and does not validate that the bytes actually loaded match the declared size before releasing the CPU.

Treat this branch as loader development work, not a verified general-purpose SD boot environment. The runtime I/O table still exposes UART registers and dummy entries; it does not provide a 65C02 filesystem or SD block-service API.

## KitBIOS and KitMon

KitBIOS initializes the BIOS call-table pointers, provides polling terminal I/O, installs interrupt vectors, and enters KitMon.

| BIOS call | Function |
| --- | --- |
| 0 | Reset |
| 1 | Write one terminal character |
| 2 | Write a NUL-terminated string, up to 256 characters |
| 3 | Read one terminal character without echo |

KitMon provides memory inspection and editing, register display/editing, program execution, and stack inspection. On hardware, the BIOS BRK handler saves CPU state and enters the monitor; NMI and ordinary IRQ handling do not supply additional peripheral services.

| Command | Purpose |
| --- | --- |
| `D [address]` | Dump memory |
| `E address list` | Enter bytes |
| `F range byte` | Fill an address range |
| `J [address]` | Jump to an address / resume execution |
| `R [register byte]` | Display or edit registers |
| `S` | Display stack |
| `?` | Show help |
| Ctrl-R | Reset the BIOS / monitor |
| Ctrl-D | Enter the py65 monitor, simulator build only |

Parameters are hexadecimal. Range endpoints are separated by a space. Use `?` for the monitor's built-in command summary. Ctrl-R is a software reset; it does not rerun the PIC memory loader.

### Terminal configuration

Use **8 data bits, no parity, 1 stop bit**, local echo disabled, and VT100-compatible escape handling. On hardware, configure Enter to send LF and display standalone LF as a new line with carriage return.

- `master`: **57600 baud**.
- `kitos`: **115200 baud**, including the PIC loader banner and subsequent CPU UART access.

The shared `kitbios/README.md` documents 57600 baud; the `kitos` PIC source selects 115200. The simulator build also accepts CR as an input line terminator.

## Memory map

The shared KitBIOS linker configuration divides the CPU address space as follows:

| Address range | Use |
| --- | --- |
| `$0000–$00FF` | Zero page; includes BIOS pointers and monitor state |
| `$0100–$01FF` | CPU stack |
| `$0200–$02FF` | PIC-serviced memory-mapped I/O |
| `$0300–$EFFF` | General RAM region |
| `$F000–$FFFF` | KitBIOS / KitMon region in SRAM |
| `$FFFA–$FFFF` | NMI, reset, and IRQ/BRK vectors within that region |

The I/O page uses only the lowest three address bits to select one of eight register-table entries, so those entries repeat every eight bytes throughout the page.

| Base address | PIC register / use |
| --- | --- |
| `$0200` | `RC1REG`: received character |
| `$0201` | `TX1REG`: transmitted character |
| `$0202` | `PIR3`: UART status flags |
| `$0203` | `RC1STA`: receiver status/control |
| `$0204–$0207` | Dummy entries on hardware |

The simulator build substitutes `$0204` for character output and `$0205` for character input.

## Build and simulation

### Tools

- Make and a shell environment compatible with the supplied Makefiles.
- The **cc65 toolchain**, specifically `ca65` and `ld65`, for 65C02 software.
- **Clang** for `bin2inc` on `master`; its Makefile defaults to `clang -Weverything`.
- **MPLAB X with the legacy MPASM toolchain** for the PIC project. The checked-in project configuration records `MPASMWIN` version **5.86**.
- **py65**, with `py65mon` available on PATH, for simulation.
- A PIC programmer and the physical hardware for hardware execution.

The checked-in PIC Makefile includes `nbproject/Makefile-impl.mk` and `nbproject/Makefile-variables.mk`, which are absent from both branches. Open/configure `kitpic.X` in a compatible MPLAB X environment and generate its build files before expecting the PIC command-line targets to work. The PIC sources use MPASM syntax; compatibility with another assembler is not established here.

### Build the BIOS independently

From the repository root, on either branch:

```sh
make -C kitbios
```

The configured output is `kitbios/bin/kitbios.bin`; assembly listings and linker maps go under `kitbios/build/`.

### Build the simulator version

From the repository root:

```sh
make sim
./simulate.sh
```

This builds `kitbios/bin/kitbios-sim.bin` and runs:

```sh
py65mon -m 65C02 -r kitbios/bin/kitbios-sim.bin -o 0204 -i 0205
```

Simulation exercises the 65C02 BIOS and monitor with host terminal I/O. It does not simulate the PIC, electrical bus timing, SRAM loader, or SD/FAT16 boot path.

### Full build on `master`

After preparing the PIC build environment:

```sh
make
```

The top-level dependency chain builds `bin2inc`, builds KitBIOS, regenerates `kitpic.X/src/kitbios.inc`, and invokes the PIC project build. Building the PIC project alone uses the existing include and does not refresh it from BIOS source.

### Full build on `kitos`

After preparing the PIC build environment:

```sh
make
```

This invokes the BIOS and PIC builds as separate targets. It does not build `bin2inc`, regenerate the embedded include, produce a separate KitOS, or prepare an SD card. The old embedded `kitbios.inc` remains tracked but is not included by `main.asm`.

On either branch, the top-level cleanup command is `make clean`. It also invokes PIC cleanup and therefore depends on the generated PIC Makefiles. `make -C kitbios clean` cleans only the BIOS outputs.

These instructions describe the checked-in build logic. A successful build, simulator session, and hardware boot must be verified in the intended toolchain and hardware environment.

On `kitos`, PIC code is split into `main.asm`, `uart.asm`, `sdcard.asm`, and `fat16.asm`, with related include files and a custom linker script. That branch removes `bin2inc/` and `sdcard.bin`.

## License

Software and firmware in this repository are licensed under the [Apache License 2.0](LICENSES/Apache-2.0.txt).

Hardware design files and schematics are licensed under the [CERN Open Hardware License Version 2 – Permissive (CERN-OHL-P-2.0)](LICENSES/CERN-OHL-P-2.0.txt).

Copyright © 2020 Ryan Clarke
