# Rainbow CHR-ROM self-flashing how-to

**This document is still a WIP and can contain some errors...**  

## Introduction

This document explains how to erase/program the flash memory directly from your code. This can be useful for game saves, game updates, additional content, etc.

Keep in mind that flash memory chips have a limited number of cycles (which is called endurance), a cycle being an erase/program process per byte. Device specifications usually give a minimum of 10 000 cycles, and a guaranteed typical endurance of 100 000 cycles.  

Beyond those 100 000 cycles, errors may appear while erasing/programming the chip.  

In this document, the term *program* instead of *write* will be used to match the flash manufacturer datasheet.  

Please read [SST39SF datasheet](http://ww1.microchip.com/downloads/en/DeviceDoc/20005022C.pdf)'s "Device Operation" chapter for more informations.  

## Banks init

CHR banks need to be initialized in a specific way to perform erase/program actions. CHR mode 1 (2K banks) must be used in this case.

```
$0000-$07FF => bank to erase/program
$0800-$0BFF => bank %----1010 for $AAAA writes (e.g. 10)
$0C00-$0FFF => bank %----0101 for $5555 writes (e.g. 5)
```

```
; first you need to switch to CHR mode 1
lda #4
sta $5006

; however, PRG mode doesn't matter here,
; so you could do this to preserve current config
; (except CHR mode of course)
lda $5006
and #%11111001
ora #4
sta $5006

; bank init for command writes
lda #10
sta $5402
lda #5
sta $5403

; select destination banks
; 2 x 2K banks = 1 sector
ldx bank_to_flash
stx $5400
inx
stx $5401
```

## Erasing

Before you can program a new byte, you need to erase it.  

Unfortunately you can't erase just one byte, you can only erase 4K sectors, or the entire chip.  

## Sector Erase

To erase a sector, you need to write specific bytes at specific addresses to send a sector-erase command to the flash memory.  

Since the NES can only access the CHR-ROM via PPU registers, the erase command sequence is a bit longer than for the PRG-ROM.  

```
; erase command sequence

; first write: $AA @ $5555
lda #$15
sta $2006
lda #$55
sta $2006
lda #$AA
sta $2007

; second write: $55 @ $2AAA
lda #$1A
sta $2006
lda #$AA
sta $2006
lda #$55
sta $2007

; third write: $80 @ $5555
lda #$15
sta $2006
lda #$55
sta $2006
lda #$80
sta $2007

; fourth write: $AA @ $2AAA
lda #$15
sta $2006
lda #$55
sta $2006
lda #$AA
sta $2007

; fifth write: $55 @ $2AAA
lda #$1A
sta $2006
lda #$AA
sta $2006
lda #$55
sta $2007

; actual sector erase command

; sixth write: $30 @ $0000
lda #$00
sta $2006
lda #$00
sta $2006
lda #$30
sta $2007
```

Doing this will erase 4K of data in the given bank/sector.  
Erasing means that all bytes will be set to $ff.  

## Chip Erase

To erase the chip completely, you need to write specific bytes at specific addresses to send a chip-erase command to the flash memory.  

```
; erase command sequence

; first write: $AA @ $5555
lda #$15
sta $2006
lda #$55
sta $2006
lda #$AA
sta $2007

; second write: $55 @ $2AAA
lda #$1A
sta $2006
lda #$AA
sta $2006
lda #$55
sta $2007

; third write: $80 @ $5555
lda #$15
sta $2006
lda #$55
sta $2006
lda #$80
sta $2007

; fourth write: $AA @ $5555
lda #$15
sta $2006
lda #$55
sta $2006
lda #$AA
sta $2007

; fifth write: $55 @ $2AAA
lda #$1A
sta $2006
lda #$AA
sta $2006
lda #$55
sta $2007

; actual chip erase command

; sixth write: $10 @ $5555
lda #$15
sta $2006
lda #$55
sta $2006
lda #$10
sta $2007
```

Doing this will erase all bytes of the flash memory.  
Erasing means that all bytes will be set to $ff.  

## Programming

Once you erased a sector (or the entire chip), you can now program it.  

### Byte Program

To program a byte, you need to write specific bytes at specific addresses to send a byte-program command to the flash memory.

```
; byte program command sequence

; first write: $AA @ $5555
lda #$15
sta $2006
lda #$55
sta $2006
lda #$AA
sta $2007

; second write: $55 @ $2AAA
lda #$1A
sta $2006
lda #$AA
sta $2006
lda #$55
sta $2007

; third write: $A0 @ $5555
lda #$15
sta $2006
lda #$55
sta $2006
lda #$A0
sta $2007

; program the actual value

; fourth write: new value @ destination address
lda destination_address+0
sta $2006
lda destination_address+1
sta $2006
lda value_to_write
sta $2007
```

And that's it, your new byte is programmed.  

## Verifying

After erasing or programming the flash, it's good practice to make sure that the command was sucessful. As stated in the introduction, those commands are not immediate, and you need to make sure that they worked as intended before doing something else.  

### Erase

After sending an erase command (sector erase or chip erase), you need to wait until you can read back $ff from the sector/chip before programming it again.  

```
verify_erase:
  lda #$00
  sta $2006
  sta $2006
  lda $2007 ; dummy read
  lda $2007
  cmp #$ff
  bne verify_erase
```

### Program

After sending a byte program command, you need to wait until you can read back the written value from the sector/chip before writing another one.  

Because of how the byte program process works, reading the byte back twice is the safest way to make sure that the byte programming worked correctly.  

```
; destination_address is a pointer
; to the byte destination address

; value_to_write is the written value

  ldy #0
verify_write:
  ; first check
  lda destination_address+0
  sta $2006
  lda destination_address+1
  sta $2006
  lda $2007 ; dummy read
  lda $2007
  cmp value_to_write
  bne verify_write
  
  ; second check
  lda destination_address+0
  sta $2006
  lda destination_address+1
  sta $2006
  lda $2007 ; dummy read
  lda $2007
  cmp value_to_write
  bne verify_write
```

## Software ID

Software ID command allows you to get the chip manufacturer ID and chip ID. It can be used to determine the size of the PRG flash chip.  

### Entry

To enter software ID mode, you need to write specific bytes at specific addresses.  

```
; first write: $AA @ $5555
lda #$15
sta $2006
lda #$55
sta $2006
lda #$AA
sta $2007

; second write: $55 @ $2AAA
lda #$1A
sta $2006
lda #$AA
sta $2006
lda #$55
sta $2007

; third write: $90 @ $2AAA
lda #$15
sta $2006
lda #$55
sta $2006
lda #$90
sta $2007
```

### Read

Once you're in the software ID mode, you can read the manufacturer ID and the flash chip ID.  

```
lda #$00
sta $2006
sta $2006
lda $2007   ; dummy read
lda $2007   ; read $xxx0 to get manufacturer ID, should be $BF
lda $2007   ; read $xxx1 to get device ID
            ; SST39SF010 (128K) device ID = $B5
            ; SST39SF020 (256K) device ID = $B6
            ; SST39SF040 (512K) device ID = $B7
```

## Exit

There are two ways to exit software ID mode.  

```
; software ID exit command

; setting the address is optional here, since the address doesn't matter
lda #$00
sta $2006
sta $2006

lda #$F0
sta $2007
```

or

```
; software ID exit command sequence

; first write: $AA @ $5555
lda #$15
sta $2006
lda #$55
sta $2006
lda #$AA
sta $2007

; second write: $55 @ $2AAA
lda #$1A
sta $2006
lda #$AA
sta $2006
lda #$55
sta $2007

; third write: $90 @ $2AAA
lda #$15
sta $2006
lda #$55
sta $2006
lda #$90
sta $2007

; fourth write: $F0 @ $5555
lda #$15
sta $2006
lda #$55
sta $2006
lda #$F0
sta $2007
```
