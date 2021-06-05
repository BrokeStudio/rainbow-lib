# Rainbow PRG-ROM self-flashing how-to

**This document is still a WIP and can contain some errors...**  

## Introduction

This document explains how to erase/program the flash memory directly from your code. This can be useful for game saves, game updates, additional content, etc.

Since those operations are not immediate, you need to execute your code from RAM so your game/program can still run while the flash chip is being updated.  

Keep in mind that flash memory chips have a limited number of cycles (which is called endurance), a cycle being an erase/program process per byte. Device specifications usually give a minimum of 10 000 cycles, and a guaranteed typical endurance of 100 000 cycles.  

Beyond those 100 000 cycles, errors may appear while erasing/programming the chip.  

In this document, the term *program* instead of *write* will be used to match the flash manufacturer datasheet.  

Please read [SST39SF datasheet](http://ww1.microchip.com/downloads/en/DeviceDoc/20005022C.pdf)'s "Device Operation" chapter for more informations.  

## Banks init

PRG banks need to be initialized in a specific way to perform erase/program actions. PRG mode 1 (8K+8K+8K+8K fixed) must be used in this case.

```
$8000-$9FFF => bank to erase/program
$A000-$BFFF => bank %-----01 for $AAAA writes (e.g. 1)
$C000-$DFFF => bank %-----10 for $D555 writes (e.g. 2)
```

```
; first you need to switch to PRG mode 1
lda #1
sta $5006

; however, CHR mode doesn't matter here,
; so you could do this to preserve current config
; (except PRG mode of course)
lda $5006
ora #1
sta $5006

lda #1    ; select 8K bank @ $A000
sta $5003
lda #2    ; select 8K bank @ $C000
sta $5004
```

## Erasing

Before you can program a new byte, you need to erase it.  

Unfortunately you can't erase just one byte, you can only erase 4K sectors, or the entire chip.  

### Sector Erase

To erase a sector, you need to write specific bytes at specific addresses to send a sector-erase command to the flash memory.  

```
; select destination 8K bank @ $8000
lda bank_to_flash
sta $5002

; erase command sequence
lda #$AA
sta $D555
lda #$55
sta $AAAA
lda #$80
sta $D555
lda #$AA
sta $D555
lda #$55
sta $AAAA

; actual sector erase command
lda #$30
sta $8000   ; 4K sector to erase
            ; write to $8000 to erase first half of 8K bank
            ; write to $9000 to erase second half of 8K bank
```

Doing this will erase 4K of data in the given bank/sector.  
Erasing means that all bytes will be set to $ff.  

### Chip Erase

To erase the chip completely, you need to write specific bytes at specific addresses to send a chip-erase command to the flash memory.  

```
; erase command sequence
lda #$AA
sta $D555
lda #$55
sta $AAAA
lda #$80
sta $D555
lda #$AA
sta $D555
lda #$55
sta $AAAA

; actual chip erase command
lda #$10
sta $5555
```

Doing this will erase all bytes of the flash memory.  
Erasing means that all bytes will be set to $ff.  

**Note:** this will also erase vector pointers at $FFFA, $FFFC, $FFFE, meaning that if NMI and /or IRQ are enabled, or if you press reset, the CPU won't be able to jump to usable code. Therefore, this command is highly **NOT** recommended.  

## Programming

Once you erased a sector (or the entire chip), you can now program it.  

### Byte Program

To program a byte, you need to write specific bytes at specific addresses to send a byte-program command to the flash memory.  

```
; select destination 8K bank @ $8000
lda bank_to_flash
sta $5002

; byte program command sequence
lda #$AA
sta $D555
lda #$55
sta $AAAA
lda #$A0
sta $D555

; program the actual value
ldy #0
lda value_to_write
sta destination_address,y   ; must be in $8000-$9FFF range
```

And that's it, your new byte is programmed.  

## Verifying

After erasing or programming the flash, it's good practice to make sure that the command was sucessful. As stated in the introduction, those commands are not immediate, and you need to make sure that they worked as intended before doing something else.  

### Erase

After sending an erase command (sector erase or chip erase), you need to wait until you can read back $ff from the sector/chip before programming it again.  

```
verify_erase:
  lda $8000 ; or $9000 depending on the sector erased
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
  lda (destination_address), y
  cmp value_to_write
  bne verify_write
  
  ; second check
  lda (destination_address), y
  cmp value_to_write
  bne verify_write
```

## Software ID

Software ID command allows you to get the chip manufacturer ID and chip ID. It can be used to determine the size of the PRG flash chip.  

### Entry

To enter software ID mode, you need to write specific bytes at specific addresses.  

```
; software ID entry command sequence
lda #$AA
sta $D555
lda #$55
sta $AAAA
lda #$90
sta $D555
```

### Read

Once you're in the software ID mode, you can read the manufacturer ID and the flash chip ID.  

```
lda $8000   ; read $xxx0 to get manufacturer ID, should be $BF
lda $8001   ; read $xxx1 to get device ID
            ; SST39SF010 (128K) device ID = $B5
            ; SST39SF020 (256K) device ID = $B6
            ; SST39SF040 (512K) device ID = $B7
```

**Note:** this code must run from RAM because once you enter software ID mode, the chip won't return correct values when read.  

### Exit

There are two ways to exit software ID mode.  

```
; software ID exit command
lda #$F0
sta $xxxx   ; address doesn't matter here
            ; as long as it's in $8000-$FFFF range
```

or

```
; software ID exit command sequence
lda #$AA
sta $D555
lda #$55
sta $AAAA
lda #$90
sta $D555
lda #$F0
sta $D555
```
