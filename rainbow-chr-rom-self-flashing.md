# Rainbow CHR-ROM self-flashing how-to

**This document is still a WIP and can contain some errors...**  

## Banks init

Need to use CHR 2K mode (1).  

```
$0000-$0FFF => bank to flash
$1000-$17FF => bank 10 for $AAAA writes
$1800-$1FFF => bank 5 for $5555 writes
```

Please read [SST39SF datasheet](http://ww1.microchip.com/downloads/en/DeviceDoc/20005022C.pdf)'s "Device Operation" chapter for more informations.  

```
lda #4  ; change CHR mode to mode 1 (2K)
sta $5006

; bank init for command writes
lda #10
sta $5402
lda #5
sta $5403

; select destination banks
ldx bank_to_flash
stx $5400
inx
stx $5401
```

## Byte Program

```
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

; erase sector

; sixth write: $30 @ destination address
lda #$00  ; destination address MSB
sta $2006
lda #$00  ; destination address LSB
sta $2006
lda #$30
sta $2007
```

## Chip Erase

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

; sixth write: $10 @ $5555
lda #$15
sta $2006
lda #$55
sta $2006
lda #$10
sta $2007
```

## Software ID Entry

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

## Software ID Exit

```
; setting the address is optional here, since the address doesn't matter
lda #$00
sta $2006
sta $2006

lda #$F0
sta $2007
```

or

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

; fourth write: $AA @ $5555
lda #$15
sta $2006
lda #$55
sta $2006
lda #$F0
sta $2007
```
