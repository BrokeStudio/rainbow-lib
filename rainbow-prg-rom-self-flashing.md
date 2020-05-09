# Rainbow PRG-ROM self-flashing how-to

**This document is still a WIP and can contain some errors...**  

## Banks init

Need to use PRG mode 1 (8K+8K+8K+8K fixed).  

```
$8000-$9FFF => bank to flash
$A000-$BFFF => bank 1 for $AAAA writes
$C000-$DFFF => bank 2 for $D555 writes
```

Please read [SST39SF datasheet](http://ww1.microchip.com/downloads/en/DeviceDoc/20005022C.pdf)'s "Device Operation" chapter for more informations.  

```
lda #1    ; change PRG mode to mode 1
sta $5006
lda #1    ; select 8K bank @ $A000
sta $5003
lda #2    ; select 8K bank @ $C000
sta $5004
```

## Byte Program

```
lda bank_to_flash ; select destination 8K bank @ $8000
sta $5002

lda #$AA
sta $D555
lda #$55
sta $AAAA
lda #$A0
sta $D555

lda #$AA    ; value to write
sta $9A55   ; destination address
```

## Sector Erase

```
lda bank_to_flash ; select destination 8K bank @ $8000
sta $5002

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

lda #$30
sta $8000   ; 4K sector to erase
            ; first half ot 8K bank ($8000) or second half of 8K bank ($9000)
```

## Chip Erase

```
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
lda #$10
sta $5555
```

## Software ID Entry

This needs to be executed from RAM.  

```
lda #$AA
sta $D555
lda #$55
sta $AAAA
lda #$90
sta $D555

lda $8000   ; read $xxx0 to get manufacturer ID, should be $BF
lda $8001   ; read $xxx1 to get device ID
            ; SST39SF010 (128K) device ID = $B5
            ; SST39SF020 (256K) device ID = $B6
            ; SST39SF040 (512K) device ID = $B7
```

## Software ID Exit

This needs to be executed from RAM.  

```
lda #$F0
sta $xxxx   ; address doesn't matter here
            ; as long as it's in $8000-$FFFF range
```

or

```
lda #$AA
sta $D555
lda #$55
sta $AAAA
lda #$90
sta $D555
lda #$F0
sta $D555
```
