; ################################################################################
; RAINBOW LIBRARY
.out "# Rainbow library..."

.scope RNBW

; ################################################################################
; INCLUDES

  .include "rainbow-config.s"
  .include "rainbow-constants.s"

; ################################################################################
; ALIASES

  enableIRQ           = RNBW_enableIRQ
  disableIRQ          = RNBW_disableIRQ
  getData             = RNBW_getData
  sendData            = RNBW_sendData
  waitReady           = RNBW_waitReady
  debugA              = RNBW_debug_A
  debug_A             = RNBW_debug_A
  debugX              = RNBW_debug_X
  debug_X             = RNBW_debug_X
  debugY              = RNBW_debug_Y
  debug_Y             = RNBW_debug_Y
  getRandomByte       = RNBW_getRandomByte
  getRandomByteRange  = RNBW_getRandomByteRange
  getRandomWord       = RNBW_getRandomWord
  getRandomWordRange  = RNBW_getRandomWordRange

; ################################################################################
; ZEROPAGE

.pushseg
.zeropage

rnbwTmp:  .res 2

.popseg

; ################################################################################
; MACROS

.if .not .definedmacro(RNBW_waitResponse)
  .macro RNBW_waitResponse
    ; wait for response
  :
    bit $5001
    bpl :-
  .endmacro
.endif

.if .not .definedmacro(RNBW_waitAnswer)
  .macro RNBW_waitAnswer
    ; wait for response
  :
    bit $5001
    bpl :-
  .endmacro
.endif

; ################################################################################
; CODE

  .proc RNBW_disableIRQ

    ; disable ESP IRQ
    lda $5001
    and #$3f
    sta $5001

    ; return
    rts

  .endproc

  .proc RNBW_enableIRQ

    ; disable ESP IRQ
    lda $5001
    ora #$40
    sta $5001

    ; return
    rts

  .endproc

  .proc RNBW_sendData
    ; A: message pointer lo byte
    ; X: message pointer hi byte

    sta rnbwTmp+0
    stx rnbwTmp+1

    ldy #0
    lda (rnbwTmp),y
    tax
    inx
  :
    lda (rnbwTmp),y
    sta $5000
    iny
    dex
    bne :-

    ; return
    rts
  .endproc

  .proc RNBW_getData

    lda $5000         ; dummy read
    nop               ; seems to be needed when a long message is coming
    ldx $5000         ; get bytes number
    stx BUF_IN+0
    ldy #1
  :
    lda $5000
    sta BUF_IN,Y
    iny
    dex
    bne :-

    ; return
    rts

  .endproc

  .proc RNBW_waitReady

    ; ask for ESP status
    lda #1
    sta $5000
    lda #TO_ESP::ESP_GET_STATUS
    sta $5000

    ; wait for answer
  :
    bit $5001
    bpl :-

    ; get data
    jsr RNBW_getData

    ; make sure that the data ready flag is cleared
  :
    bit $5001
    bmi :-

/*
    lda BUF_IN+1
    cmp #FROM_ESP::READY
    beq done

    lda $5001

  done:
*/

    ; return
    rts

  .endproc

  .proc RNBW_debug_A
    
    ; data to debug in A
    pha
    lda #2
    sta $5000
    lda #TO_ESP::DEBUG_LOG
    sta $5000
    pla
    sta $5000 ; DATA

    ; return
    rts

  .endproc

  .proc RNBW_debug_X

    ; data to debug in X
    lda #2
    sta $5000
    lda #TO_ESP::DEBUG_LOG
    sta $5000
    stx $5000 ; DATA

    ; return
    rts

  .endproc

  .proc RNBW_debug_Y
  
    ; data to debug in Y
    lda #2
    sta $5000
    lda #TO_ESP::DEBUG_LOG
    sta $5000
    sty $5000 ; DATA

    ; return
    rts

  .endproc

  .proc RNBW_getWifiStatusSync

    ; ask for wifi status
    lda #1
    sta $5000
    lda #TO_ESP::WIFI_GET_STATUS
    sta $5000

    ; wait for answer
  :
    bit $5001
    bpl :-

    ; get data
    jsr RNBW_getData

    ; return wifi status in A
    lda BUF_IN+2

    ; return
    rts

  .endproc

  .proc RNBW_getServerStatusSync

    ; ask for server status
    lda #1
    sta $5000
    lda #TO_ESP::SERVER_GET_STATUS
    sta $5000

    ; wait for answer
  :
    bit $5001
    bpl :-

    ; get data
    jsr RNBW_getData

    ; return server status in A
    lda BUF_IN+2

    ; return
    rts

  .endproc

  .proc RNBW_getRandomByte

    lda #1
    sta $5000
    lda #TO_ESP::RND_GET_BYTE
    sta $5000
    RNBW_waitResponse
    jmp RNBW_getData

  .endproc

  .proc RNBW_getRandomByteRange
    ; X: min
    ; Y: max

    lda #3
    sta $5000
    lda #TO_ESP::RND_GET_BYTE_RANGE
    sta $5000
    stx $5000
    sty $5000
    RNBW_waitResponse
    jmp RNBW_getData

  .endproc

  .proc RNBW_getRandomWord

    lda #1
    sta $5000
    lda #TO_ESP::RND_GET_WORD
    sta $5000
    RNBW_waitResponse
    jmp RNBW_getData

  .endproc

  .proc RNBW_getRandomWordRange
    ; X: min
    ; Y: max

    lda #3
    sta $5000
    lda #TO_ESP::RND_GET_WORD_RANGE
    sta $5000
    stx $5000
    sty $5000
    RNBW_waitResponse
    jmp RNBW_getData

  .endproc

.endscope