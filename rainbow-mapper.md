# Rainbow mapper documentation

Rainbow or RNBW is a cartridge board intended for homebrew releases with its own unique mapper assigned to iNES Mapper xxx (TBD).  
The cartridge was initially designed with WiFi capabilities in mind, but can also be used without it.  
The board and mapper were designed by Broke Studio which also manufactures the cartridges.  

## Overview

- WiFi capabilities to allow online gaming, cartridge update, downloadable content... (optional)
- 2 PRG ROM banking modes
- 4 CHR ROM banking modes
- Up to 32KB of WRAM, mappable at \$6000-\$7FFF but also within \$8000-\$DFFF
- Scanline IRQ (identical to the one used in the MMC3 mapper)
- Three extra sound channels (2 pulse channels and 1 sawtooth channel, identical to those in the VRC6 mapper)
- Self-flashable PRG-ROM / CHR-ROM
- Possibility to use CHR-ROM for pattern tables and CHR-RAM for name/attribute tables
- 4 mirroring modes: vertical, horizontal, 1-screen, 4-screen
- Up to 4 independant nametables when using 1-screen mirroring (CHR-RAM only)
- Up to 4 sets of 4 nametables when using 4-screen mirroring (CHR-RAM only)

## Banks

### PRG mode 0 - 16K+8K+8K fixed

- CPU \$8000-\$BFFF: 16 KB switchable PRG ROM/RAM bank
- CPU \$C000-\$DFFF: 8 KB switchable PRG ROM/RAM bank
- CPU \$E000-\$FFFF: 8 KB PRG ROM bank, fixed to the last bank

### PRG mode 1 - 8K+8K+8K+8K fixed

- CPU \$8000-\$9FFF: 8 KB switchable PRG ROM/RAM bank
- CPU \$A000-\$BFFF: 8 KB switchable PRG ROM/RAM bank
- CPU \$C000-\$DFFF: 8 KB switchable PRG ROM/RAM bank
- CPU \$E000-\$FFFF: 8 KB PRG ROM bank, fixed to the last bank

### WRAM

- CPU \$6000-\$7FFF: 8 KB switchable PRG-RAM/ROM bank

### CHR mode 0 - 1K mode

- PPU \$0000-\$03FF: 1 KB switchable CHR bank
- PPU \$0400-\$07FF: 1 KB switchable CHR bank
- PPU \$0800-\$0BFF: 1 KB switchable CHR bank
- PPU \$0C00-\$0FFF: 1 KB switchable CHR bank
- PPU \$1000-\$13FF: 1 KB switchable CHR bank
- PPU \$1400-\$17FF: 1 KB switchable CHR bank
- PPU \$1800-\$1BFF: 1 KB switchable CHR bank
- PPU \$1C00-\$1FFF: 1 KB switchable CHR bank

### CHR mode 1 - 2K mode

- PPU \$0000-\$07FF: 2 KB switchable CHR bank
- PPU \$0800-\$0FFF: 2 KB switchable CHR bank
- PPU \$1000-\$17FF: 2 KB switchable CHR bank
- PPU \$1800-\$1FFF: 2 KB switchable CHR bank

### CHR mode 2 - 4K mode

- PPU \$0000-\$0FFF: 4 KB switchable CHR bank
- PPU \$1000-\$1FFF: 4 KB switchable CHR bank

### CHR mode 3 - 8K mode

- PPU \$0000-\$1FFF: 8 KB switchable CHR bank

## Registers

### Configuration (\$5006) R/W

Mapper configuration is done using register \$5006.  
This register is writable and readable.  

```
7  bit  0
---- ----
ssmm rccp
|||| ||||
|||| |||+-  p - PRG banking mode
|||| |||          0: 16K switchable + 8K switchable + 8K fixed
|||| |||          1: 8K switchable + 8K switchable + 8K switchable + 8K fixed
|||| |++--  cc - CHR banking mode
|||| |            00: 1K chr mode (chr bank 0 to 7 are used) - see note below
|||| |            01: 2K chr mode (chr bank 0 to 3 are used)
|||| |            10: 4K chr mode (chr bank 0 and 1 are used)
|||| |            11: 8k chr mode (chr bank 0 is used)
|||| +----  r - CHR chip selector for pattern tables
||||              0: CHR-ROM
||||              1: CHR-RAM
||++------  mm - mirroring mode
||                00: vertical (CIRAM)
||                01: horizontal (CIRAM)
||                10: 1-screen 4 nametables (uses CIRAM (0-1) and CHR-RAM (2-3))
||                11: 4-screen 4 sets of 4 nametables (uses CHR-RAM)
++--------  ss - 1-screen selector, when using mirroring mode %10.
                  00: uses CIRAM nametable @ 2000
                  01: uses CIRAM nametable @ 2400
                  10: uses CHR-RAM as nametable @ $7800
                  11: uses CHR-RAM as nametable @ $7C00

                4-screen set selector, when using mirroring mode %11 (uses CHR-RAM)
                  00: 1st set starts @ $7000
                  01: 2nd set starts @ $6000
                  10: 3rd set starts @ $5000
                  11: 4th set starts @ $4000

Note: when using 1K chr banking mode with 512K CHR-ROM,
      banks 0 to 3 address the first 256K 
      and banks 4 to 7 address the last 256K,
      providing 256K for background and 256K for sprites
      the drawback is that you can't use background tiles
      as sprites without duplicating them
      however, you can switch background and sprite page
      if needed using register $2000
```

### PRG banking (\$5002-\$5004) Write-only

This register is only writable.  

```
7  bit  0
---- ----
c.BB BBbb
| || ||||
| ++-++++-  bank index
+---------  chip selector (0: PRG-ROM, 1: WRAM)
```

#### PRG mode 0 (16K+8K+8K fixed)

- Register \$5002 controls 16K bank @ \$8000-\$BFFF
- Register \$5004 controls  8K bank @ \$C000-\$DFFF

Register \$5002:

- when chip selector is 0, \$8000-\$BFFF is mapped to PRG-ROM and 'BBBbb' is used to select the 16K bank
- when chip selector is 1, \$8000-\$9FFF is mapped to WRAM and 'bb' is used to select the 8K bank
                           \$A000-\$BFFF is mapped to WRAM and ('bb' + 1) & 3 is used to select the 8K bank

Register \$5004:

- when chip selector is 0, \$C000-\$DFFF is mapped to PRG-ROM and 'BBBBbb' is used to select the 8K bank
- when chip selector is 1, \$C000-\$DFFF is mapped to WRAM and 'bb' is used to select the 8K bank

#### PRG mode 1 (8K+8K+8K+8K fixed)

- Register \$5002 controls 8K bank @ \$8000-\$9FFF
- Register \$5003 controls 8K bank @ \$A000-\$BFFF
- Register \$5004 controls 8K bank @ \$C000-\$DFFF

Register \$5002:

- when chip selector is 0, \$8000-\$9FFF is mapped to PRG-ROM and 'BBBBbb' is used to select the 8K bank
- when chip selector is 1, \$8000-\$9FFF is mapped to WRAM and 'bb' is used to select the 8K bank

Register \$5003:

- when chip selector is 0, \$A000-\$BFFF is mapped to PRG-ROM and 'BBBBbb' is used to select the 8K bank
- when chip selector is 1, \$A000-\$BFFF is mapped to WRAM and 'bb' is used to select the 8K bank

Register \$5004:

- when chip selector is 0, \$C000-\$DFFF is mapped to PRG-ROM and 'BBBBbb' is used to select the 8K bank
- when chip selector is 1, \$C000-\$DFFF is mapped to WRAM and 'bb' is used to select the 8K bank

### WRAM banking (\$5005) Write-only

This register is only writable.  

```
7  bit  0
---- ----
c.BB BBbb
| || ||||
| ++-++++-  bank index
+---------  chip selector (0: PRG-ROM, 1: WRAM)
```

Register \$5005:

- when chip selector is 0, \$6000-\$7FFF is mapped to PRG-ROM and 'BBBBbb' is used to select the 8K bank
- when chip selector is 1, \$6000-\$7FFF is mapped to WRAM and 'bb' is used to select the 8K bank

### CHR banking (\$5007,\$5400-\$5407) Write-only

Those registers are only writable.  

\$5400-\$5407 registers work as follow:

```
7  bit  0
---- ----
BBBB BBBB
|||| ||||
++++-++++-  bank index
```

#### CHR mode 0 (1K banking)

Register \$5007 controls the upper CHR bank bit.  

```
7  bit  0
---- ----
.... ...p
        |
        +-  256K page index
```

This allows you to address 512 banks in total.  
To access all 512K in CHR mode 0, first write the upper bank bit to register \$5007 and then write the lower bits to \$5400-\$5407.  
Each individual 1K bank can have a different upper CHR bank bit.  
This bit will not be modified when using other CHR modes.  

Registers \$5400 to \$5407 select 1K banks.  

*note*: for some reason, you need to add a `nop` after writing to \$5007. This may change in the future.  

#### CHR mode 1 (2K banking)

Registers \$5400 to \$5403 select 2K banks.  

#### CHR mode 2 (4K banking)

Registers \$5400 to \$5401 select 4K banks.  

#### CHR mode 3 (8K banking)

Register \$5400 selects 8K bank.  

### Scanline IRQ

Scanline IRQ works exactly like MMC3 IRQ (new/normal behaviour).  
For more informations: https://wiki.nesdev.com/w/index.php/MMC3#IRQ_Specifics.  

#### IRQ latch (\$5C04) Write-only

This register specifies the IRQ counter reload value. When the IRQ counter is zero (or a reload is requested through $C001), this value will be copied to the IRQ counter at the NEXT rising edge of the PPU address, presumably at PPU cycle 260 of the current scanline.  
This register is only writable.  

```
7  bit  0
---- ----
DDDD DDDD
|||| ||||
++++-++++- IRQ latch value
```

#### IRQ reload (\$5C05) Write-only

Writing any value to this register reloads the MMC3 IRQ counter at the NEXT rising edge of the PPU address, presumably at PPU cycle 260 of the current scanline.  
This register is only writable.  

```
7  bit  0
---- ----
xxxx xxxx
```

#### IRQ disable (\$5C06) Write-only

Writing any value to this register will disable MMC3 interrupts AND acknowledge any pending interrupts.  
This register is only writable.  

```
7  bit  0
---- ----
xxxx xxxx
```

#### IRQ enable (\$5C07) Write-only

Writing any value to this register will enable MMC3 interrupts.  
This register is only writable.  

```
7  bit  0
---- ----
xxxx xxxx
```

### Sound / Audio Expansion (\$5800-\$5805 and \$5C00-\$5C02)

Channels registers work exactly like VRC6 audio expansion minus the frequency scaling register.  
For more informations: https://wiki.nesdev.com/w/index.php/VRC6_audio.  

#### Pulse control (\$5800,\$5803) Write-only

\$5800 controls Pulse 1  
\$5803 controls Pulse 2  
Those registers are only writable.  

```
7  bit  0
---- ----
MDDD VVVV
|||| ||||
|||| ++++- volume
|+++------ duty Cycle
+--------- mode (1: ignore duty)
```

#### Saw Accum Rate (\$5C00) Write-only

This register is only writable.  

```
7  bit  0
---- ----
..AA AAAA
  ++-++++- accumulator Rate (controls volume)
```

#### Freq Low (\$5801,\$5804,\$5C01) Write-only

\$5801 controls Pulse 1  
\$5804 controls Pulse 2  
\$5C01 controls Saw  
Those registers are only writable.  

```
7  bit  0
---- ----
FFFF FFFF
|||| ||||
++++-++++- low 8 bits of frequency
```

#### Freq High (\$5802,\$5805,\$5C02) Write-only

\$5802 controls Pulse 1  
\$5805 controls Pulse 2  
\$5C02 controls Saw  
Those registers are only writable.  

```
7  bit  0
---- ----
E... FFFF
|    ||||
|    ++++-  high 4 bits of frequency
+---------  enable (0: channel disabled)
```

### WiFi (\$5000,\$5001)

#### Data transfer (\$5000) R/W

Read or write a byte to communicate with the ESP.  
This register is readable and writable.  

```
7  bit  0
---- ----
DDDD DDDD
|||| ||||
++++-++++-  byte to write (W) or read (R)
```

#### Configuration (\$5001) R/W

This register is readable and writable.  

```
7  bit  0
---- ----
di.. ...e
||      |
||      +-  ESP enable (0: disable, 1: enable) R/W
|+--------  IRQ enable (0: disable, 1: enable) R/W
+---------  data ready (0: false, 1:true) R
            'd' flag is set to 1 when the ESP has data to transmit to the NES
            if both 'd' and 'i' flags are set, then NES IRQ will be triggered
```

### Mapper version (\$5C03) Read-only

Read this register to get mapper version.  
This register is only readable.  

```
7  bit  0
---- ----
PPPv vvvv
|||| ||||
|||+-++++-  version
+++-------  platform
```

| Platform (PPP) | Description  |
| -------------- | ------------ |
| 0              | PCB          |
| 1              | Emulator     |
| 2              | Web emulator |

| Version (vvvvv) | PCB (0)                   | EMU (1) | WEB (2) |
| --------------- | ------------------------- | ------- | ------- |
| 0               | v1.0 (first proto board)  | v1.0    | v1.0    |
| 1               | v1.1 (second proto board) | n/a     | n/a     |

## Unused registers

\$5806  
\$5807  

## Recap / Cheat sheet

### ESP/WiFi

- \$5000  (R/W) data transfer  
- \$5001  (R/W) configuration  

### PRG-ROM banking

**Note:** \$E000-\$FFFF is fixed to last 8K bank  

- \$5002  (W)
  - 16K @ \$8000-\$BFFF (mode 0)  
  - 8K @ \$C000-\$DFFF (mode 1)  
- \$5003  (W)
  - 8K @ \$A000-\$BFFF(mode 1)  
- \$5004  (W)
  - 8K @ \$C000-\$DFFF(mode 0/1)  

### PRG-RAM banking

- \$5005  (W)  8K @\$6000-\$7FFF  

### Mapper configuration

- \$5006  (W/R) %ssmm rccp  
  - ss - 1-screen selector  
  - mm - mirroring mode  
  - r - CHR chip selector for pattern tables  
  - cc - CHR banking mode  
  - p - PRG banking mode  

### CHR-ROM/RAM banking

- \$5007  (W)
  - 1K upper CHR bank bit (mode 0)
- \$5400  (W)
  - 1K @ \$0000-\$03FF (mode 0)  
  - 2k @ \$0000-\$07FF (mode 1)  
  - 4k @ \$0000-\$0FFF (mode 2)  
  - 8k @ \$0000-\$07FF (mode 3)  
- \$5401  (W)
  - 1K @ \$0400-\$07FF (mode 0)  
  - 2k @ \$0800-\$0FFF (mode 1)  
  - 4k @ \$1000-\$1FFF (mode 2)  
- \$5402  (W)
  - 1K @ \$0800-\$0BFF (mode 0)  
  - 2k @ \$1000-\$17FF (mode 1)  
- \$5403  (W)
  - 1K @ \$0C00-\$0FFF (mode 0)  
  - 2k @ \$1800-\$1FFF (mode 1)  
- \$5404  (W)
  - 1K @ \$1000-\$13FF (mode 0)  
- \$5405  (W)
  - 1K @ \$1400-\$17FF (mode 0)  
- \$5406  (W)
  - 1K @ \$1800-\$1BFF (mode 0)  
- \$5407  (W)
  - 1K @ \$1C00-\$1FFF (mode 0)  

### Scanline IRQ

\$5C04  (W) latch  
\$5C05  (W) reload  
\$5C06  (W) disable  
\$5C07  (W) enable  

### Audio expansion

\$5800  (W) pusle 1 control  
\$5801  (W) pulse 1 low freq  
\$5802  (W) pulse 1 high freq  
\$5803  (W) pusle 2 control  
\$5804  (W) pulse 2 low freq  
\$5805  (W) pulse 2 high freq  
\$5C00  (W) saw accumulator rate  
\$5C01  (W) saw low freq  
\$5C02  (W) saw high freq  