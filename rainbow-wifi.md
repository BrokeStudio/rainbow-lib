# Rainbow WiFi documentation

> **Disclaimer**  
>  
> This document and the project are still WIP and are subject to modifications.  
> &nbsp;  

## Credits

The Rainbow project is developed by [Antoine Gohin / Broke Studio](https://twitter.com/Broke_Studio).  

Thanks to :

- [Paul](https://twitter.com/InfiniteNesLive) / [InfiniteNesLives](http://www.infiniteneslives.com) for taking time to explain me lots of hardware stuff
- Christian Gohin, my father, who helped me designing the first prototype board
- [Sylvain Gadrat](https://sgadrat.itch.io/super-tilt-bro) aka [RogerBidon](https://twitter.com/RogerBidon) for helping me update [FCEUX](http://www.fceux.com) to emulate the Rainbow mapper ❤
- The NES WiFi Club (cheers guys 😊)
- [NESdev](http://www.nesdev.com) community

## Table of content

- [Rainbow WiFi documentation](#rainbow-wifi-documentation)
  - [Credits](#credits)
  - [Table of content](#table-of-content)
  - [What is Rainbow?](#what-is-rainbow)
  - [Why 'Rainbow'?](#why-rainbow)
  - [Mapper registers](#mapper-registers)
  - [Rainbow registers](#rainbow-registers)
    - [UART (\$5000 - R/W)](#uart-5000---rw)
    - [Status (\$5001 - R/W)](#status-5001---rw)
  - [Buffers](#buffers)
  - [Messages format](#messages-format)
  - [Commands overview](#commands-overview)
    - [Commands to the ESP](#commands-to-the-esp)
    - [Commands from the ESP](#commands-from-the-esp)
  - [Commands details](#commands-details)
    - [ESP_GET_STATUS](#esp_get_status)
    - [DEBUG_GET_LEVEL](#debug_get_level)
    - [DEBUG_SET_LEVEL](#debug_set_level)
    - [DEBUG_LOG](#debug_log)
    - [BUFFER_CLEAR_RX_TX](#buffer_clear_rx_tx)
    - [BUFFER_DROP_FROM_ESP](#buffer_drop_from_esp)
    - [WIFI_GET_STATUS](#wifi_get_status)
    - [ESP_RESTART](#esp_restart)
    - [RND_GET_BYTE](#rnd_get_byte)
    - [RND_GET_BYTE_RANGE](#rnd_get_byte_range)
    - [RND_GET_WORD](#rnd_get_word)
    - [RND_GET_WORD_RANGE](#rnd_get_word_range)
    - [SERVER_GET_STATUS](#server_get_status)
    - [SERVER_GET_PING](#server_get_ping)
    - [SERVER_SET_PROTOCOL](#server_set_protocol)
    - [SERVER_GET_SETTINGS](#server_get_settings)
    - [SERVER_GET_CONFIG_SETTINGS](#server_get_config_settings)
    - [SERVER_SET_SETTINGS](#server_set_settings)
    - [SERVER_RESTORE_SETTINGS](#server_restore_settings)
    - [SERVER_CONNECT](#server_connect)
    - [SERVER_DISCONNECT](#server_disconnect)
    - [SERVER_SEND_MESSAGE](#server_send_message)
    - [NETWORK_SCAN](#network_scan)
    - [NETWORK_GET_DETAILS](#network_get_details)
    - [NETWORK_GET_REGISTERED](#network_get_registered)
    - [NETWORK_GET_REGISTERED_DETAILS](#network_get_registered_details)
    - [NETWORK_REGISTER](#network_register)
    - [NETWORK_UNREGISTER](#network_unregister)
  - [File commands details](#file-commands-details)
    - [File paths](#file-paths)
    - [FILE_OPEN](#file_open)
    - [FILE_CLOSE](#file_close)
    - [FILE_STATUS](#file_status)
    - [FILE_EXISTS](#file_exists)
    - [FILE_DELETE](#file_delete)
    - [FILE_SET_CUR](#file_set_cur)
    - [FILE_READ](#file_read)
    - [FILE_WRITE](#file_write)
    - [FILE_APPEND](#file_append)
    - [FILE_COUNT](#file_count)
    - [FILE_GET_LIST](#file_get_list)
    - [FILE_GET_FREE_ID](#file_get_free_id)
    - [FILE_GET_INFO](#file_get_info)
    - [FILE_DOWNLOAD](#file_download)
    - [FILE_FORMAT](#file_format)
  - [Bootloader](#bootloader)
  - [TODO](#todo)

---

## What is Rainbow?

**Rainbow** is a mapper for the **NES** that allows to connect the console to the Internet.  
It uses a WiFi chip (**ESP8266**, called **ESP** in this doc) embedded on the cart.

## Why 'Rainbow'?

There are two reasons for this name.  

The first one is because when I was learning Verilog and was playing with my CPLD dev board, I wired it with a lot of colored floating wires as you can see in this [Tweet](https://twitter.com/Broke_Studio/status/1031836021976170497), and it looked a lot like a rainbow.  

Second reason is because Kevin Hanley from KHAN games is working on a game called Unicorn, which is based on an old BBS game called Legend of the Red Dragon, and therefore needs a connection to the outside world to be played online. This project would be a great oppurtunity to help him, and as everyone knows, Unicorns love Rainbows :)

## Mapper registers

First Rainbow prototypes were based on UNROM-512 mapper to make the development easier.  
Now the board uses its own mapper. Detailed documentation of the mapper can be found here: [rainbow-mapper.md](rainbow-mapper.md).  

## Rainbow registers

\$5000-5001 registers can be read and written to in order to communicate with the ESP.

### UART (\$5000 - R/W)

Read register $5000 to get next byte from the ESP.  

```
  ; this is how to read an incomming message
  ; and store it in a buffer

  lda $5000         ; dummy read
  nop               ; let it breathe
  lda $5000         ; read first byte (message length)...
  sta buffer+0      ; ... and store it
  
  ; get the rest of the message

  ldx #0            ; set X to 0
:
  lda $5000         ; read next byte...
  sta buffer+1,x    ; ... and store it
  inx               ; increment X
  cpx buffer+0      ; compare X to message length
  bne :-            ; loop if not equal
```

**Note:** because of the mapper buffer, the first read of a new message will always return a dummy byte, so a dummy read is required in this case.  

Write to register $5000 to send byte to the ESP.  

```
  ; this is how to send a message from a buffer

  ldx #0            ; set X to 0
  lda buffer+0      ; get message length...
  sta $5000         ; ... and send it
:
  lda buffer+1,x    ; get next message byte...
  sta $5000         ; ... and send it
  inx               ; increment X
  cpx buffer+0      ; compare X to message length
  bne :-            ; loop if not equal

  ; this is how to send a short message or fixed values message

  lda #3                      ; message length
  sta $5000
  lda #TO_ESP::FILE_DELETE    ; command
  sta $5000
  lda #FILE_PATHS::ROMS       ; paramater (path id)
  sta $5000
  lda #0                      ; parameter (file id)
  sta $5000

  ; this is possible too

  lda #2
  ldx #TO_ESP::FILE_GET_LIST
  ldy #FILE_PATHS::ROMS
  sta $5000
  stx $5000
  sty $5000
```

**Note:** after you send the first byte of a new message, you have one second to send the rest of the message before the RX buffer is reset. This is to prevent the ESP to get stuck, waiting for a message that could never come.  

### Status (\$5001 - R/W)

```
7  bit  0
---- ----
DI.. ...E
||      |
||      + ESP enable ( 0 : disable | 1 : enable ) R/W
|+------- IRQ enable ( 0 : disable | 1 : enable ) R/W
+-------- Data ready ( 0 : disable | 1 : enable ) R
          this flag is set to 1 when the ESP has data to transmit to the NES
          if the I flag is set, NES IRQ will be triggered
```

Note : the D flag won't be set to 0 immediately once the NES read the last byte from the ESP.
Therefore, it's recommended to process the data immediately after receiving it if you use the IRQ feature.

## Buffers

The ESP has 2 FIFO buffers :  

- **TX:** data from the ESP to the NES buffer  
- **RX:** data from the NES to the ESP buffer  

Both buffers can store up to 20 messages.

## Messages format

A message always have the same format and follows these rules:  

- First byte is the message length (number of bytes following this first byte, can't be 0, minimum is 1).
- Second byte is the command (see [Commands to the ESP](#Commands-to-the-ESP)).
- Following bytes are the parameters/data for the command.

## Commands overview

### Commands to the ESP

| Value | Command                                                           | Description                                                               |
| ----- | ----------------------------------------------------------------- | ------------------------------------------------------------------------- |
|       |                                                                   | **ESP CMDS**                                                              |
| 0     | [ESP_GET_STATUS](#ESP_GET_STATUS)                                 | Get ESP status                                                            |
| 1     | [DEBUG_GET_LEVEL](#DEBUG_GET_LEVEL)                               | Get debug level                                                           |
| 2     | [DEBUG_SET_LEVEL](#DEBUG_SET_LEVEL)                               | Set debug level                                                           |
| 3     | [DEBUG_LOG](#DEBUG_LOG)                                           | Debug / Log data                                                          |
| 4     | [BUFFER_CLEAR_RX_TX](#BUFFER_CLEAR_RX_TX)                         | Clear RX/TX buffers                                                       |
| 5     | [BUFFER_DROP_FROM_ESP](#BUFFER_DROP_FROM_ESP)                     | Drop messages from TX (ESP->NES) buffer                                   |
| 6     | [WIFI_GET_STATUS](#WIFI_GET_STATUS)                               | Get WiFi connection status                                                |
| 7     | [ESP_RESTART](#ESP_RESTART)                                       | Restart the ESP                                                           |
|       |                                                                   | **RND CMDS**                                                              |
| 8     | [RND_GET_BYTE](#RND_GET_BYTE)                                     | Get random byte                                                           |
| 9     | [RND_GET_BYTE_RANGE](#RND_GET_BYTE_RANGE)                         | Get random byte between custom min/max                                    |
| 10    | [RND_GET_WORD](#RND_GET_WORD)                                     | Get random word                                                           |
| 11    | [RND_GET_WORD_RANGE](#RND_GET_WORD_RANGE)                         | Get random word between custom min/max                                    |
|       |                                                                   | **SERVER CMDS**                                                           |
| 12    | [SERVER_GET_STATUS](#SERVER_GET_STATUS)                           | Get server connection status                                              |
| 13    | [SERVER_GET_PING](#SERVER_GET_PING)                               | Get ping between ESP and server                                           |
| 14    | [SERVER_SET_PROTOCOL](#SERVER_SET_PROTOCOL)                       | Set protocol to be used to communicate (WS/TCP/UDP)                       |
| 15    | [SERVER_GET_SETTINGS](#SERVER_GET_SETTINGS)                       | Get current server host name and port                                     |
| 16    | [SERVER_GET_CONFIG_SETTINGS](#SERVER_GET_CONFIG_SETTINGS)         | Get server host name and port defined in the Rainbow config file          |
| 17    | [SERVER_SET_SETTINGS](#SERVER_SET_SETTINGS)                       | Set current server host name and port                                     |
| 18    | [SERVER_RESTORE_SETTINGS](#SERVER_RESTORE_SETTINGS)               | Restore server host name and port to values defined in the Rainbow config |
| 19    | [SERVER_CONNECT](#SERVER_CONNECT)                                 | Connect to server                                                         |
| 20    | [SERVER_DISCONNECT](#SERVER_DISCONNECT)                           | Disconnect from server                                                    |
| 21    | [SERVER_SEND_MESSAGE](#SERVER_SEND_MESSAGE)                       | Send message to server                                                    |
|       |                                                                   | **NETWORK CMDS**                                                          |
| 22    | [NETWORK_SCAN](#NETWORK_SCAN)                                     | Scan networks around and return count                                     |
| 23    | [NETWORK_GET_DETAILS](#NETWORK_GET_DETAILS)                       | Get network SSID                                                          |
| 24    | [NETWORK_GET_REGISTERED](#NETWORK_GET_REGISTERED)                 | Get registered networks status                                            |
| 25    | [NETWORK_GET_REGISTERED_DETAILS](#NETWORK_GET_REGISTERED_DETAILS) | Get registered network SSID                                               |
| 26    | [NETWORK_REGISTER](#NETWORK_REGISTER)                             | Register network                                                          |
| 27    | [NETWORK_UNREGISTER](#NETWORK_UNREGISTER)                         | Unregister network                                                        |
|       |                                                                   | **FILE CMDS**                                                             |
| 28    | [FILE_OPEN](#FILE_OPEN)                                           | Open working file                                                         |
| 29    | [FILE_CLOSE](#FILE_CLOSE)                                         | Close working file                                                        |
| 30    | [FILE_STATUS](#FILE_STATUS)                                       | Get working file status                                                   |
| 31    | [FILE_EXISTS](#FILE_EXISTS)                                       | Check if file exists                                                      |
| 32    | [FILE_DELETE](#FILE_DELETE)                                       | Delete a file                                                             |
| 33    | [FILE_SET_CUR](#FILE_SET_CUR)                                     | Set working file cursor position a file                                   |
| 34    | [FILE_READ](#FILE_READ)                                           | Read working file (at specific position)                                  |
| 35    | [FILE_WRITE](#FILE_WRITE)                                         | Write working file (at specific position)                                 |
| 36    | [FILE_APPEND](#FILE_APPEND)                                       | Append data to working file                                               |
| 37    | [FILE_COUNT](#FILE_COUNT)                                         | Get number of tiles in a specific path                                    |
| 38    | [FILE_GET_LIST](#FILE_GET_LIST)                                   | Get list of existing files in a specific path                             |
| 39    | [FILE_GET_FREE_ID](#FILE_GET_FREE_ID)                             | Get an unexisting file ID in a specific path.                             |
| 40    | [FILE_GET_INFO](#FILE_GET_INFO)                                   | Get file info (size + crc32)                                              |
| 41    | [FILE_DOWNLOAD](#FILE_DOWNLOAD)                                   | Download a file from a giving URL to a specific path index / file index   |
| 42    | [FILE_FORMAT](#FILE_FORMAT)                                       | Format file system                                                        |

### Commands from the ESP

| Value | Command                                                       | Description      |
| ----- | ------------------------------------------------------------- | ---------------- |
|       |                                                               | **ESP CMDS**     |
| 0     | [READY](#ESP_GET_STATUS)                                      |                  |
| 1     | [DEBUG_LEVEL](#DEBUG_GET_LEVEL)                               |                  |
| 2     | [WIFI_STATUS](#WIFI_GET_STATUS)                               |                  |
|       |                                                               | **RND CMDS**     |
| 3     | [RND_BYTE](#RND_GET_BYTE)                                     |                  |
| 4     | [RND_WORD](#RND_GET_WORD)                                     |                  |
|       |                                                               | **SERVER CMDS**  |
| 5     | [SERVER_STATUS](#SERVER_GET_STATUS)                           |                  |
| 6     | [SERVER_PING](#SERVER_GET_PING)                               |                  |
| 7     | [SERVER_SETTINGS](#SERVER_GET_SETTINGS)                       |                  |
| 8     | [MESSAGE_FROM_SERVER](#SERVER_SEND_MESSAGE)                   |                  |
|       |                                                               | **NETWORK CMDS** |
| 9     | [NETWORK_COUNT](#NETWORK_SCAN)                                |                  |
| 10    | [NETWORK_SCANNED_DETAILS](#NETWORK_GET_SCANNED_DETAILS)       |                  |
| 11    | [NETWORK_REGISTERED_DETAILS](#NETWORK_GET_REGISTERED_DETAILS) |                  |
| 12    | [NETWORK_REGISTERED](#NETWORK_GET_REGISTERED)                 |                  |
|       |                                                               | **FILE CMDS**    |
| 13    | [FILE_STATUS](#FILE_STATUS)                                   |                  |
| 14    | [FILE_EXISTS](#FILE_EXISTS)                                   |                  |
| 15    | [FILE_DELETE](#FILE_DELETE)                                   |                  |
| 16    | [FILE_LIST](#FILE_GET_LIST)                                   |                  |
| 17    | [FILE_DATA](#FILE_READ)                                       |                  |
| 18    | [FILE_COUNT](#FILE_COUNT)                                     |                  |
| 19    | [FILE_ID](#FILE_GET_FREE_ID)                                  |                  |
| 20    | [FILE_INFO](#FILE_GET_INFO)                                   |                  |
| 21    | [FILE_DOWNLOAD](#FILE_DOWNLOAD)                               |                  |

## Commands details

### ESP_GET_STATUS

This command asks the WiFi module if it's ready.  
The ESP will only answer when ready, so once you sent the message, just wait for the answer.  

| Byte | Description                                 | Example          |
| ---- | ------------------------------------------- | ---------------- |
| 0    | Length of the message (excluding this byte) | `1`              |
| 1    | Command ID (see commands to ESP)            | `ESP_GET_STATUS` |

**Returns:**

| Byte | Description                                 | Example |
| ---- | ------------------------------------------- | ------- |
| 0    | Length of the message (excluding this byte) | `1`     |
| 1    | Command ID (see commands from ESP)          | `READY` |

[Back to command list](#Commands-overview)

---

### DEBUG_GET_LEVEL

This command returns the debug level. 

| Byte | Description                                 | Example           |
| ---- | ------------------------------------------- | ----------------- |
| 0    | Length of the message (excluding this byte) | `1`               |
| 1    | Command ID (see commands to ESP)            | `DEBUG_GET_LEVEL` |

**Returns:**

| Byte | Description                                 | Example       |
| ---- | ------------------------------------------- | ------------- |
| 0    | Length of the message (excluding this byte) | `2`           |
| 1    | Command ID (see commands from ESP)          | `DEBUG_LEVEL` |
| 2    | Debug configuration value                   | `0`           |

See [DEBUG_SET_LEVEL](#DEBUG_SET_LEVEL) command for debug level value details

[Back to command list](#Commands-overview)

---

### DEBUG_SET_LEVEL

This command sets the debug level. 

| Byte | Description                                 | Example           |
| ---- | ------------------------------------------- | ----------------- |
| 0    | Length of the message (excluding this byte) | `2`               |
| 1    | Command ID (see commands to ESP)            | `DEBUG_SET_LEVEL` |
| 2    | Debug level value                           | `1`               |

**The debug level value uses bits like this:**

```
7  bit  0
---- ----
.... .nsd
      |||
      ||+-  enable/disable dev logs
      |+--  enable/disable serial logs
      |     outputs what is sent to the NES
      +---  enable/disable network logs
            outputs what is received from the outside world (WebSocket/TCP/UDP)

Note: serial/network logs are not recommended when lots of messages are exchanged (ex: during real-time game)

```

[Back to command list](#Commands-overview)

---

### DEBUG_LOG

This command logs data on the serial port of the ESP.  
Can be read using a UART/USB adapter, RX to pin 5 of the ESP board edge connector, GND to pin 6.  
Bit 1 of the debug level needs to be set (see [DEBUG_SET_LEVEL](#DEBUG_SET_LEVEL)).  

| Byte | Description                                 | Example     |
| ---- | ------------------------------------------- | ----------- |
| 0    | Length of the message (excluding this byte) | `4`         |
| 1    | Command ID (see commands to ESP)            | `DEBUG_LOG` |
| 2    | Data length                                 | `2`         |
| 3    | Data                                        | `0x41`      |
| 4    | Data                                        | `0xAC`      |

[Back to command list](#Commands-overview)

---

### BUFFER_CLEAR_RX_TX

This command clears TX/RX buffers.  
Should be used on startup to make sure that we start with a clean setup.  

**Important** do NOT send another message right after sending a BUFFER_CLEAR_RX_TX command. The new message would arrive before the buffers are cleared and would then be lost. However, you can send ESP_GET_STATUS until you get a response, and then read $5000 until $5001.7 is 0.

**Note:** sending a BUFFER_CLEAR_RX_TX at the ROM startup is HIGLY recommended to avoid undefined behaviour if resetting the console in the middle of communication between the NES and the ESP.  

| Byte | Description                                 | Example              |
| ---- | ------------------------------------------- | -------------------- |
| 0    | Length of the message (excluding this byte) | `1`                  |
| 1    | Command ID (see commands to ESP)            | `BUFFER_CLEAR_RX_TX` |

[Back to command list](#Commands-overview)

---

### BUFFER_DROP_FROM_ESP

This command drops messages of a given type from TX (ESP->NES) buffer.  
You can keep the most recent messages using the second parameter.  

| Byte | Description                                 | Example                |
| ---- | ------------------------------------------- | ---------------------- |
| 0    | Length of the message (excluding this byte) | `3`                    |
| 1    | Command ID (see commands to ESP)            | `BUFFER_DROP_FROM_ESP` |
| 2    | Message type / ID (see commands to ESP)     | `MESSAGE_FROM_SERVER`  |
| 3    | Number of most recent messages to keep      | `1`                    |

[Back to command list](#Commands-overview)

---

### WIFI_GET_STATUS

This command asks the WiFi status.

| Byte | Description                                 | Example           |
| ---- | ------------------------------------------- | ----------------- |
| 0    | Length of the message (excluding this byte) | `1`               |
| 1    | Command ID (see commands to ESP)            | `WIFI_GET_STATUS` |

**Returns:**

| Byte | Description                                 | Example                  |
| ---- | ------------------------------------------- | ------------------------ |
| 0    | Length of the message (excluding this byte) | `2`                      |
| 1    | Command ID (see commands from ESP)          | `WIFI_STATUS`            |
| 2    | WiFi status (see below)                     | `WIFI_STATUS::CONNECTED` |

**WiFi status:**

| Value | WIFI_STATUS     | Description            |
| ----- | --------------- | ---------------------- |
| 255   | NO_SHIELD       | -                      |
| 0     | IDLE_STATUS     | -                      |
| 1     | NO_SSID_AVAIL   | -                      |
| 2     | SCAN_COMPLETED  | Network scan completed |
| 3     | CONNECTED       | WiFi connected         |
| 4     | CONNECT_FAILED  | WiFi connection failed |
| 5     | CONNECTION_LOST | WiFi connection lost   |
| 6     | DISCONNECTED    | WiFi disconnected      |

[Back to command list](#Commands-overview)

---

### ESP_RESTART

This command resets the ESP.  

| Byte | Description                                 | Example       |
| ---- | ------------------------------------------- | ------------- |
| 0    | Length of the message (excluding this byte) | `1`           |
| 1    | Command ID (see commands to ESP)            | `ESP_RESTART` |

[Back to command list](#Commands-overview)

---

### RND_GET_BYTE

This command returns a random byte between 0 and 255.

| Byte | Description                                 | Example        |
| ---- | ------------------------------------------- | -------------- |
| 0    | Length of the message (excluding this byte) | `1`            |
| 1    | Command ID (see commands to ESP)            | `RND_GET_BYTE` |

**Returns:**

| Byte | Description                                 | Example    |
| ---- | ------------------------------------------- | ---------- |
| 0    | Length of the message (excluding this byte) | `2`        |
| 1    | Command ID (see commands from ESP)          | `RND_BYTE` |
| 2    | Random value between 0 and 255              | `0xAA`     |

[Back to command list](#Commands-overview)

---

### RND_GET_BYTE_RANGE

This command returns a random byte between custom min and max values.  

| Byte | Description                                 | Example              |
| ---- | ------------------------------------------- | -------------------- |
| 0    | Length of the message (excluding this byte) | `3`                  |
| 1    | Command ID (see commands to ESP)            | `RND_GET_BYTE_RANGE` |
| 2    | Custom min value (0 to 254)                 | `0x00`               |
| 3    | Custom max value (1 to 255)                 | `0x80`               |

**Returns:**

| Byte | Description                                 | Example    |
| ---- | ------------------------------------------- | ---------- |
| 0    | Length of the message (excluding this byte) | `2`        |
| 1    | Command ID (see commands from ESP)          | `RND_BYTE` |
| 2    | Random value between 0 and 255              | `0x14`     |

[Back to command list](#Commands-overview)

---

### RND_GET_WORD

This command returns a random word between 0 and 65535.

| Byte | Description                                 | Example        |
| ---- | ------------------------------------------- | -------------- |
| 0    | Length of the message (excluding this byte) | `1`            |
| 1    | Command ID (see commands to ESP)            | `RND_GET_WORD` |

**Returns:**

| Byte | Description                                 | Example    |
| ---- | ------------------------------------------- | ---------- |
| 0    | Length of the message (excluding this byte) | `3`        |
| 1    | Command ID (see commands from ESP)          | `RND_WORD` |
| 2    | Random value HI byte                        | `0xA7`     |
| 3    | Random value LO byte                        | `0xEF`     |

[Back to command list](#Commands-overview)

---

### RND_GET_WORD_RANGE

This command returns a random word between custom min and max values.

| Byte | Description                                 | Example              |
| ---- | ------------------------------------------- | -------------------- |
| 0    | Length of the message (excluding this byte) | `5`                  |
| 1    | Command ID (see commands to ESP)            | `RND_GET_WORD_RANGE` |
| 2    | Custom min value (0 to 65534) HI byte       | `0x00`               |
| 3    | Custom min value (0 to 65534) LO byte       | `0x00`               |
| 4    | Custom max value (1 to 65535) HI byte       | `0x20`               |
| 5    | Custom max value (1 to 65535) LO byte       | `0x00`               |

**Returns:**

| Byte | Description                                 | Example    |
| ---- | ------------------------------------------- | ---------- |
| 0    | Length of the message (excluding this byte) | `3`        |
| 1    | Command ID (see commands from ESP)          | `RND_WORD` |
| 2    | Random value HI byte                        | `0x06`     |
| 3    | Random value LO byte                        | `0x82`     |

[Back to command list](#Commands-overview)

---

### SERVER_GET_STATUS

This command asks the server status.

| Byte | Description                                 | Example             |
| ---- | ------------------------------------------- | ------------------- |
| 0    | Length of the message (excluding this byte) | `1`                 |
| 1    | Command ID (see commands to ESP)            | `SERVER_GET_STATUS` |

**Returns:**

| Byte | Description                                 | Example                    |
| ---- | ------------------------------------------- | -------------------------- |
| 0    | Length of the message (excluding this byte) | `2`                        |
| 1    | Command ID (see commands from ESP)          | `SERVER_STATUS`            |
| 2    | Server status (see below)                   | `SERVER_STATUS::CONNECTED` |

**Server status:**

| Value | SERVER_STATUS | Description  |
| ----- | ------------- | ------------ |
| 0     | DISCONNECTED  | Disconnected |
| 1     | CONNECTED     | Connected    |

[Back to command list](#Commands-overview)

---

### SERVER_GET_PING

This command pings the server and returns the min, max and average round-trip time and number of lost packets.  
If another ping is already in progress, the command will be ignored.  
Returned round-trip time is divided by 4 to fit in only 1 byte, so time precision is 4ms.  
If no number of pings is passed, the default value will be 4.  

| Byte | Description                                                            | Example           |
| ---- | ---------------------------------------------------------------------- | ----------------- |
| 0    | Length of the message (excluding this byte)                            | `1` or `2`        |
| 1    | Command ID (see commands to ESP)                                       | `SERVER_GET_PING` |
|      | *the next byte is required if you want to specify the number of pings* |                   |
| 2    | Number of pings                                                        | `4`               |
|      | *if 0 is passed, this will perform 4 pings by default*                 |                   |

**Returns:**

Following message will be sent if server hostname couldn't be resolved or is empty:

| Byte | Description                                 | Example       |
| ---- | ------------------------------------------- | ------------- |
| 0    | Length of the message (excluding this byte) | `1`           |
| 1    | Command ID (see commands from ESP)          | `SERVER_PING` |

Following message will be sent after ping:

| Byte | Description                                  | Example       |
| ---- | -------------------------------------------- | ------------- |
| 0    | Length of the message (excluding this byte)  | `5`           |
| 1    | Command ID (see commands from ESP)           | `SERVER_PING` |
| 2    | Minimum ping round-trip time (4ms precision) | `0x2D`        |
| 3    | Maximum ping round-trip time (4ms precision) | `0x42`        |
| 4    | Average ping round-trip time (4ms precision) | `0x37`        |
| 5    | Number of lost packets                       | `0x01`        |

[Back to command list](#Commands-overview)

---

### SERVER_SET_PROTOCOL

This command sets the protocol to be use when talking to game server.

| Byte | Description                                 | Example               |
| ---- | ------------------------------------------- | --------------------- |
| 0    | Length of the message (excluding this byte) | `2`                   |
| 1    | Command ID (see commands to ESP)            | `SERVER_SET_PROTOCOL` |
| 2    | Protocol value (see below)                  | `PROTOCOL::WS`        |

**Protocol values:**

| Value | PROTOCOL | Description       |
| ----- | -------- | ----------------- |
| 0     | WS       | WebSocket         |
| 1     | WS_S     | WebSocket Secured |
| 2     | TCP      | TCP               |
| 3     | TCP_S    | TCP Secured       |
| 4     | UDP      | UDP               |

[Back to command list](#Commands-overview)

---

### SERVER_GET_SETTINGS

This command returns the current server settings (hostname and port).  

| Byte | Description                                 | Example               |
| ---- | ------------------------------------------- | --------------------- |
| 0    | Length of the message (excluding this byte) | `1`                   |
| 1    | Command ID (see commands to ESP)            | `SERVER_GET_SETTINGS` |

**Returns:**

| Byte | Description                                                                                    | Example         |
| ---- | ---------------------------------------------------------------------------------------------- | --------------- |
| 0    | Length of the message (excluding this byte)                                                    | `1` or more     |
| 1    | Command ID (see commands from ESP)                                                             | `HOST_SETTINGS` |
|      | **_next bytes are returned if a server hostname AND port are set in the Rainbow config file_** |                 |
| 2    | Port MSB                                                                                       | `0x0B`          |
| 3    | Port LSB                                                                                       | `0xB8`          |
| 4    | Hostname string                                                                                | `G`             |
| 5    | ...                                                                                            | `A`             |
| 6    | ...                                                                                            | `M`             |
| 7    | ...                                                                                            | `E`             |
| 8    | ...                                                                                            | `.`             |
| 9    | ...                                                                                            | `S`             |
| 10   | ...                                                                                            | `E`             |
| 11   | ...                                                                                            | `R`             |
| 12   | ...                                                                                            | `V`             |
| 13   | ...                                                                                            | `E`             |
| 14   | ...                                                                                            | `R`             |
| 15   | ...                                                                                            | `.`             |
| 16   | ...                                                                                            | `N`             |
| 17   | ...                                                                                            | `E`             |
| 18   | ...                                                                                            | `T`             |

[Back to command list](#Commands-overview)

---

### SERVER_GET_CONFIG_SETTINGS

This command returns the server settings (hostname and port) from the Rainbow config file.  

| Byte | Description                                 | Example                      |
| ---- | ------------------------------------------- | ---------------------------- |
| 0    | Length of the message (excluding this byte) | `1`                          |
| 1    | Command ID (see commands to ESP)            | `SERVER_GET_CONFIG_SETTINGS` |

**Returns:**

| Byte | Description                                                                                    | Example         |
| ---- | ---------------------------------------------------------------------------------------------- | --------------- |
| 0    | Length of the message (excluding this byte)                                                    | `1` or more     |
| 1    | Command ID (see commands from ESP)                                                             | `HOST_SETTINGS` |
|      | **_next bytes are returned if a server hostname AND port are set in the Rainbow config file_** |                 |
| 2    | Port MSB                                                                                       | `0x0B`          |
| 3    | Port LSB                                                                                       | `0xB8`          |
| 4    | Hostname string                                                                                | `G`             |
| 5    | ...                                                                                            | `A`             |
| 6    | ...                                                                                            | `M`             |
| 7    | ...                                                                                            | `E`             |
| 8    | ...                                                                                            | `.`             |
| 9    | ...                                                                                            | `S`             |
| 10   | ...                                                                                            | `E`             |
| 11   | ...                                                                                            | `R`             |
| 12   | ...                                                                                            | `V`             |
| 13   | ...                                                                                            | `E`             |
| 14   | ...                                                                                            | `R`             |
| 15   | ...                                                                                            | `.`             |
| 16   | ...                                                                                            | `N`             |
| 17   | ...                                                                                            | `E`             |
| 18   | ...                                                                                            | `T`             |

[Back to command list](#Commands-overview)

---

### SERVER_SET_SETTINGS

This command sets the current server settings (hostname and port).  
It doesn't overwrite values set in the Rainbow config file.  

| Byte | Description                                 | Example                          |
| ---- | ------------------------------------------- | -------------------------------- |
| 0    | Length of the message (excluding this byte) | `18` (depends on message length) |
| 1    | Command ID (see commands to ESP)            | `SERVER_SET_SETTINGS`            |
| 2    | Port MSB                                    | `0x0B`                           |
| 3    | Port LSB                                    | `0xB8`                           |
| 4    | Hostname string                             | `S`                              |
| 5    | ...                                         | `E`                              |
| 6    | ...                                         | `R`                              |
| 7    | ...                                         | `V`                              |
| 8    | ...                                         | `E`                              |
| 9    | ...                                         | `R`                              |
| 10   | ...                                         | `.`                              |
| 11   | ...                                         | `N`                              |
| 12   | ...                                         | `E`                              |
| 13   | ...                                         | `T`                              |

[Back to command list](#Commands-overview)

---

### SERVER_RESTORE_SETTINGS

This command sets the current server settings (hostname and port) to what is defined in the Rainbow config file.

| Byte | Description                                 | Example                   |
| ---- | ------------------------------------------- | ------------------------- |
| 0    | Length of the message (excluding this byte) | `1`                       |
| 1    | Command ID (see commands to ESP)            | `SERVER_RESTORE_SETTINGS` |

[Back to command list](#Commands-overview)

---

### SERVER_CONNECT

When using WS protocol, this command connects to the server.  
When using TCP protocol, this command conects to the server.  
When using UDP protocol, this command starts the UDP server on the ESP side using a random port between 49152 and 65535.  

| Byte | Description                                 | Example          |
| ---- | ------------------------------------------- | ---------------- |
| 0    | Length of the message (excluding this byte) | `1`              |
| 1    | Command ID (see commands to ESP)            | `SERVER_CONNECT` |

[Back to command list](#Commands-overview)

---

### SERVER_DISCONNECT

When using WS protocol, this command disconnects from server.  
When using TCP protocol, this command disconnects from server.  
When using UDP protocol, this command stops the UDP server on the ESP side.  

| Byte | Description                                 | Example             |
| ---- | ------------------------------------------- | ------------------- |
| 0    | Length of the message (excluding this byte) | `1`                 |
| 1    | Command ID (see commands to ESP)            | `SERVER_DISCONNECT` |

[Back to command list](#Commands-overview)

---

### SERVER_SEND_MESSAGE

This command sends a message to the server.  

| Byte | Description                                 | Example                          |
| ---- | ------------------------------------------- | -------------------------------- |
| 0    | Length of the message (excluding this byte) | `30` (depends on message length) |
| 1    | Command ID (see commands to ESP)            | `SERVER_SEND_MESSAGE`            |
| 2    | Data                                        | `0xAA`                           |
| ...  | Data                                        | `0x12`                           |
| 30   | Data                                        | `0xE9`                           |

[Back to command list](#Commands-overview)

---

### NETWORK_SCAN

This command scans the networks around and returns the number of networks found.  

| Byte | Description                                 | Example        |
| ---- | ------------------------------------------- | -------------- |
| 0    | Length of the message (excluding this byte) | `1`            |
| 1    | Command ID (see commands to ESP)            | `NETWORK_SCAN` |

**Returns:**

| Byte | Description                                 | Example         |
| ---- | ------------------------------------------- | --------------- |
| 0    | Length of the message (excluding this byte) | `2`             |
| 1    | Command ID (see commands from ESP)          | `NETWORK_COUNT` |
| 2    | Network count                               | `3`             |

[Back to command list](#Commands-overview)

---

### NETWORK_GET_DETAILS

This command returns the network SSID of a scanned network referenced by the passed ID.  

| Byte | Description                                 | Example               |
| ---- | ------------------------------------------- | --------------------- |
| 0    | Length of the message (excluding this byte) | `2`                   |
| 1    | Command ID (see commands to ESP)            | `NETWORK_GET_DETAILS` |
| 2    | Network ID                                  | `0x01`                |

**Returns:**

| Byte | Description                                 | Example                                       |
| ---- | ------------------------------------------- | --------------------------------------------- |
| 0    | Length of the message (excluding this byte) | `13` (depends on message length)              |
|      |                                             | (max is 43 because SSID is 32 characters max) |
| 1    | Command ID (see commands from ESP)          | `NETWORK_SCANNED_DETAILS`                     |
| 2    | Encryption type                             | `4` (see below for details)                   |
| 3    | RSSI (absolute value)                       | `0x47` (means -70 DbM)                        |
| 4    | Channel LSB                                 | `0x00`                                        |
| 5    | Channel                                     | `0x00`                                        |
| 6    | Channel                                     | `0x00`                                        |
| 7    | Channel MSB                                 | `0x01`                                        |
| 8    | Hidden?                                     | `0` (0: no / 1: yes))                         |
| 9    | SSID string length                          | `4`                                           |
| 10   | SSID string                                 | `S`                                           |
| 11   | ...                                         | `S`                                           |
| 12   | ...                                         | `I`                                           |
| 13   | ...                                         | `D`                                           |

**Encryption types:**

| Value | Description      |
| ----- | ---------------- |
| 5     | WEP              |
| 2     | WPA / PSK        |
| 4     | WPA2 / PSK       |
| 7     | open network     |
| 8     | WPA / WPA2 / PSK |

[Back to command list](#Commands-overview)

---

### NETWORK_GET_REGISTERED

The Rainbow configuration can hold up to 3 network settings.  
This command returns 1 or 0 if an SSID/password is registered or not for each network.  

| Byte | Description                                 | Example                  |
| ---- | ------------------------------------------- | ------------------------ |
| 0    | Length of the message (excluding this byte) | `1`                      |
| 1    | Command ID (see commands to ESP)            | `NETWORK_GET_REGISTERED` |

**Returns:**

| Byte | Description                                 | Example              |
| ---- | ------------------------------------------- | -------------------- |
| 0    | Length of the message (excluding this byte) | `4`                  |
| 1    | Command ID (see commands from ESP)          | `NETWORK_REGISTERED` |
| 2    | Network 1 status                            | `1`                  |
| 3    | Network 2 status                            | `1`                  |
| 4    | Network 3 status                            | `0`                  |

[Back to command list](#Commands-overview)

---

### NETWORK_GET_REGISTERED_DETAILS

The Rainbow configuration can hold up to 3 network settings.  
This command returns the SSID of the requested configuration network.  

| Byte | Description                                 | Example                          |
| ---- | ------------------------------------------- | -------------------------------- |
| 0    | Length of the message (excluding this byte) | `2`                              |
| 1    | Command ID (see commands to ESP)            | `NETWORK_GET_REGISTERED_DETAILS` |
| 2    | Network ID                                  | `0`                              |

**Returns:**

| Byte | Description                                 | Example                         |
| ---- | ------------------------------------------- | ------------------------------- |
| 0    | Length of the message (excluding this byte) | `6` (depends on message length) |
| 1    | Command ID (see commands from ESP)          | `NETWORK_REGISTERED_DETAILS`    |
| 2    | SSID string length                          | `4`                             |
| 3    | SSID string                                 | `S`                             |
| 4    | ...                                         | `S`                             |
| 5    | ...                                         | `I`                             |
| 6    | ...                                         | `D`                             |

[Back to command list](#Commands-overview)

---

### NETWORK_REGISTER

The Rainbow configuration can hold up to 3 network settings.  
This command registers a network in one of the spots.  

| Byte | Description                                 | Example                          |
| ---- | ------------------------------------------- | -------------------------------- |
| 0    | Length of the message (excluding this byte) | `16` (depends on message length) |
| 1    | Command ID (see commands to ESP)            | `NETWORK_REGISTER`               |
| 2    | Network ID                                  | `0`                              |
| 3    | SSID string length                          | `4`                              |
| 4    | SSID string                                 | `S`                              |
| 5    | ...                                         | `S`                              |
| 6    | ...                                         | `I`                              |
| 7    | ...                                         | `D`                              |
| 8    | PASSWORD string length                      | `8`                              |
| 9    | PASSWORD string                             | `P`                              |
| 10   | ...                                         | `A`                              |
| 11   | ...                                         | `S`                              |
| 12   | ...                                         | `S`                              |
| 13   | ...                                         | `W`                              |
| 14   | ...                                         | `O`                              |
| 15   | ...                                         | `R`                              |
| 16   | ...                                         | `D`                              |

**Notes:**
- Strings can only use ASCII characters between 0x20 to 0x7E.  
- SSID is 32 characters max.
- Password is 64 characters max.
- Current ESP WiFi settings will be reset to take in account modification immediately.

[Back to command list](#Commands-overview)

---

### NETWORK_UNREGISTER

The Rainbow configuration can hold up to 3 network settings.  
This command unregister a network from one of the spots.  

| Byte | Description                                 | Example              |
| ---- | ------------------------------------------- | -------------------- |
| 0    | Length of the message (excluding this byte) | `2`                  |
| 1    | Command ID (see commands to ESP)            | `NETWORK_UNREGISTER` |
| 2    | Network ID                                  | `0`                  |

[Back to command list](#Commands-overview)

---

## File commands details

Files management can be a bit tricky.  
They can be accessed in **auto mode** or in **manual mode**.  
- **auto mode** allows you to use predefined folders and files using simple IDs  
- **manual mode** allows you to use real path and file names  

**Auto mode** is recommended since it makes messages shorter and easier to read, however **manual mode** can be useful in specific situations.  

### File paths

File paths for **auto mode** are defined as follow.  

| Value | FILE_PATHS | Description                                 |
| ----- | ---------- | ------------------------------------------- |
| 0     | SAVE       | Can be used to load/save game data          |
| 1     | ROMS       | Can be used to dump/flash ROMS, patches     |
| 2     | USER       | Can be used to read/write data for the user |

### FILE_OPEN

This command opens a file as the working file.  
It can be used in auto mode (using predefined path index and filename index) or in manual mode (using path/filename string).  
If the file does not exists, an empty one will be created.  
If the same file is already opened, then the file cursor will be reset to 0.  
If another file is already opened, it will be closed.  

Message first bytes:  

| Byte | Description                                     | Example     |
| ---- | ----------------------------------------------- | ----------- |
| 0    | Length of the message (excluding this byte)     | `4` or more |
| 1    | Command ID (see commands to ESP)                | `FILE_OPEN` |
| 2    | Config                                          | `%zzzzzzzm` |
|      | m: access mode (0: auto / 1: manual)            |             |
|      | z: reserved for future use, must be set to zero |             |

Using **auto mode**:  

| Byte | Description                                | Example            |
| ---- | ------------------------------------------ | ------------------ |
| 3    | Path index (see [FILE_PATHS](#File-paths)) | `FILE_PATHS::SAVE` |
| 4    | File index                                 | `5 (0 to 63)`      |

Using **manual mode**:  

| Byte | Description        | Example |
| ---- | ------------------ | ------- |
| 3    | File string length | `13`    |
| 4    | File string        | `p`     |
| 5    | ...                | `a`     |
| 6    | ...                | `t`     |
| 7    | ...                | `h`     |
| 8    | ...                | `/`     |
| 9    | ...                | `f`     |
| 10   | ...                | `i`     |
| 11   | ...                | `l`     |
| 12   | ...                | `e`     |
| 13   | ...                | `.`     |
| 14   | ...                | `e`     |
| 15   | ...                | `x`     |
| 16   | ...                | `t`     |

[Back to command list](#Commands-overview)

---

### FILE_CLOSE

This command closes the working file.  

| Byte | Description                                 | Example      |
| ---- | ------------------------------------------- | ------------ |
| 0    | Length of the message (excluding this byte) | `1`          |
| 1    | Command ID (see commands to ESP)            | `FILE_CLOSE` |

[Back to command list](#Commands-overview)

---

### FILE_STATUS

This command returns the working file status.  
It can be used in auto mode (using predefined path index and filename index) or in manual mode (using path/filename string).  

| Byte | Description                                 | Example       |
| ---- | ------------------------------------------- | ------------- |
| 0    | Length of the message (excluding this byte) | `1`           |
| 1    | Command ID (see commands to ESP)            | `FILE_STATUS` |

**Returns:**

If a file is currently opened, the returned status details will be the same as the parameters used in the **FILE_OPEN** command to open the file.  

Message first bytes:  

| Byte | Description                                                     | Example       |
| ---- | --------------------------------------------------------------- | ------------- |
| 0    | Length of the message (excluding this byte)                     | `2` or more   |
| 1    | Command ID (see commands from ESP)                              | `FILE_STATUS` |
| 2    | File status (0: no file opened / 1: a file is currently opened) | `0` or `1`    |
|      | **_next bytes are sent only if a file is currently opened_**    |               |
| 3    | Config                                                          | `%zzzzzzzm`   |
|      | m: access mode (0: auto / 1: manual)                            |               |
|      | z: reserved for future use, must be set to zero                 |               |

If file is opened in **auto mode**:  

| Byte | Description                                | Example            |
| ---- | ------------------------------------------ | ------------------ |
| 4    | Path index (see [FILE_PATHS](#File-paths)) | `FILE_PATHS::SAVE` |
| 5    | File index                                 | `5 (0 to 63)`      |

If file is opened in **manual mode**:  

| Byte | Description        | Example |
| ---- | ------------------ | ------- |
| 4    | File string length | `13`    |
| 5    | File string        | `p`     |
| 6    | ...                | `a`     |
| 7    | ...                | `t`     |
| 8    | ...                | `h`     |
| 9    | ...                | `/`     |
| 10   | ...                | `f`     |
| 11   | ...                | `i`     |
| 12   | ...                | `l`     |
| 13   | ...                | `e`     |
| 14   | ...                | `.`     |
| 15   | ...                | `e`     |
| 16   | ...                | `x`     |
| 17   | ...                | `t`     |

[Back to command list](#Commands-overview)

---

### FILE_EXISTS

This command checks if a file exists.  
It can be used in auto mode (using predefined path index and filename index) or in manual mode (using path/filename string).  
It returns 1 if the file exists, or 0 if it doesn't.  

Message first bytes:  

| Byte | Description                                     | Example       |
| ---- | ----------------------------------------------- | ------------- |
| 0    | Length of the message (excluding this byte)     | `4` or more   |
| 1    | Command ID (see commands to ESP)                | `FILE_EXISTS` |
| 2    | Config                                          | `%zzzzzzzm`   |
|      | m: access mode (0: auto / 1: manual)            |               |
|      | z: reserved for future use, must be set to zero |               |

Using **auto mode**:  

| Byte | Description                                | Example            |
| ---- | ------------------------------------------ | ------------------ |
| 3    | Path index (see [FILE_PATHS](#File-paths)) | `FILE_PATHS::SAVE` |
| 4    | File index                                 | `5 (0 to 63)`      |

Using **manual mode**:  

| Byte | Description        | Example |
| ---- | ------------------ | ------- |
| 4    | File string length | `13`    |
| 5    | File string        | `p`     |
| 6    | ...                | `a`     |
| 7    | ...                | `t`     |
| 8    | ...                | `h`     |
| 9    | ...                | `/`     |
| 10   | ...                | `f`     |
| 11   | ...                | `i`     |
| 12   | ...                | `l`     |
| 13   | ...                | `e`     |
| 14   | ...                | `.`     |
| 15   | ...                | `e`     |
| 16   | ...                | `x`     |
| 17   | ...                | `t`     |

**Returns:**

| Byte | Description                                           | Example       |
| ---- | ----------------------------------------------------- | ------------- |
| 0    | Length of the message (excluding this byte)           | `2`           |
| 1    | Command ID (see commands from ESP)                    | `FILE_EXISTS` |
| 2    | File status (0: file does not exist / 1: file exists) | `0` or `1`    |

[Back to command list](#Commands-overview)

---

### FILE_DELETE

This command deletes (if exists) the file corresponding of the passed index.  
It can be used in auto mode (using predefined path index and filename index) or in manual mode (using path/filename string).  

Message first bytes:  

| Byte | Description                                     | Example       |
| ---- | ----------------------------------------------- | ------------- |
| 0    | Length of the message (excluding this byte)     | `4` or more   |
| 1    | Command ID (see commands to ESP)                | `FILE_DELETE` |
| 2    | Config                                          | `%zzzzzzzm`   |
|      | m: access mode (0: auto / 1: manual)            |               |
|      | z: reserved for future use, must be set to zero |               |

Using **auto mode**:  

| Byte | Description                                | Example            |
| ---- | ------------------------------------------ | ------------------ |
| 3    | Path index (see [FILE_PATHS](#File-paths)) | `FILE_PATHS::SAVE` |
| 4    | File index                                 | `5 (0 to 63)`      |

Using **manual mode**:  

| Byte | Description        | Example |
| ---- | ------------------ | ------- |
| 4    | File string length | `13`    |
| 5    | File string        | `p`     |
| 6    | ...                | `a`     |
| 7    | ...                | `t`     |
| 8    | ...                | `h`     |
| 9    | ...                | `/`     |
| 10   | ...                | `f`     |
| 11   | ...                | `i`     |
| 12   | ...                | `l`     |
| 13   | ...                | `e`     |
| 14   | ...                | `.`     |
| 15   | ...                | `e`     |
| 16   | ...                | `x`     |
| 17   | ...                | `t`     |

**Returns:**

| Byte | Description                                 | Example       |
| ---- | ------------------------------------------- | ------------- |
| 0    | Length of the message (excluding this byte) | `2`           |
| 1    | Command ID (see commands from ESP)          | `FILE_DELETE` |
| 2    | Result code (see below)                     | `0`           |

**Result codes:**

| Value | Description                           |
| ----- | ------------------------------------- |
| 0     | File successfully deleted             |
| 1     | Error while trying to delete the file |
| 2     | File does not exist                   |
| 3     | Invalid path index and/or file index  |

[Back to command list](#Commands-overview)

---

### FILE_SET_CUR

This command sets the position of the working file cursor.  
If the file is smaller than the passed offset, it'll be filled with 0x00.  

| Byte    | Description                                 | Example        |
| ------- | ------------------------------------------- | -------------- |
| 0       | Length of the message (excluding this byte) | `2 to 5`       |
| 1       | Command ID (see commands to ESP)            | `FILE_SET_CUR` |
| 2       | Offset LSB                                  | `0x00`         |
| 3 (opt) | Offset                                      | `0x00`         |
| 4 (opt) | Offset                                      | `0x10`         |
| 5 (opt) | Offset MSB                                  | `0x00`         |

[Back to command list](#Commands-overview)

---

### FILE_READ

This command reads and sends data from the working file.  
You have to pass the number of bytes you want to read.  
If there is no working file currently open, number of bytes will be 0.

| Byte | Description                                 | Example          |
| ---- | ------------------------------------------- | ---------------- |
| 0    | Length of the message (excluding this byte) | `2`              |
| 1    | Command ID (see commands to ESP)            | `FILE_READ`      |
| 2    | Number of bytes to read                     | `64` (minimum 1) |

**Returns:**

| Byte | Description                                 | Example                                   |
| ---- | ------------------------------------------- | ----------------------------------------- |
| 0    | Length of the message (excluding this byte) | `5` (depends on the number of bytes read) |
| 1    | Command ID (see commands from ESP)          | `FILE_DATA`                               |
| 2    | Number of bytes returned                    | `03`                                      |
| 3    | Data                                        | `0x12`                                    |
| 4    | Data                                        | `0xDA`                                    |
| 5    | Data                                        | `0x4C`                                    |

**Note:** number of bytes returned can be less than the number of bytes requested depending on the file size and the file cursor position.  

[Back to command list](#Commands-overview)

---

### FILE_WRITE

This command writes data to the working file.  

| Byte | Description                                 | Example                                            |
| ---- | ------------------------------------------- | -------------------------------------------------- |
| 0    | Length of the message (excluding this byte) | `66` (depends on how many bytes you want to write) |
| 1    | Command ID (see commands to ESP)            | `FILE_WRITE`                                       |
| 2    | Data                                        | `0x5F`                                             |
| ...  | Data                                        | `...`                                              |
| 66   | Data                                        | `0xAF`                                             |

[Back to command list](#Commands-overview)

---

### FILE_APPEND

This command appends data to the working file.  
The current cursor position is not affected.  

| Byte | Description                                 | Example                                            |
| ---- | ------------------------------------------- | -------------------------------------------------- |
| 0    | Length of the message (excluding this byte) | `66` (depends on how many bytes you want to write) |
| 1    | Command ID (see commands to ESP)            | `FILE_APPEND`                                      |
| 2    | Data                                        | `0x5F`                                             |
| ...  | Data                                        | `...`                                              |
| 66   | Data                                        | `0xAF`                                             |

[Back to command list](#Commands-overview)

---

### FILE_COUNT

This command sends the number of files in a specific path.  
It can be used in auto mode (using predefined path index and filename index) or in manual mode (using path/filename string).  

Message first bytes:  

| Byte | Description                                     | Example      |
| ---- | ----------------------------------------------- | ------------ |
| 0    | Length of the message (excluding this byte)     | `4` or more  |
| 1    | Command ID (see commands to ESP)                | `FILE_COUNT` |
| 2    | Config                                          | `%zzzzzzzm`  |
|      | m: access mode (0: auto / 1: manual)            |              |
|      | z: reserved for future use, must be set to zero |              |

Using **auto mode**:  

| Byte | Description                                | Example            |
| ---- | ------------------------------------------ | ------------------ |
| 3    | Path index (see [FILE_PATHS](#File-paths)) | `FILE_PATHS::SAVE` |

Using **manual mode**:  

| Byte | Description        | Example |
| ---- | ------------------ | ------- |
| 3    | Path string length | `4`     |
| 4    | Path string        | `p`     |
| 5    | ...                | `a`     |
| 6    | ...                | `t`     |
| 7    | ...                | `h`     |

[Back to command list](#Commands-overview)

**Returns:**

| Byte | Description                                 | Example      |
| ---- | ------------------------------------------- | ------------ |
| 0    | Length of the message (excluding this byte) | `2`          |
| 1    | Command ID (see commands from ESP)          | `FILE_COUNT` |
| 2    | Number of files                             | `3`          |

---

### FILE_GET_LIST

Get list of existing files in a specific path.  
It can be used in auto mode (using predefined path index) or in manual mode (using path string).  

Message first bytes:  

| Byte | Description                                     | Example         |
| ---- | ----------------------------------------------- | --------------- |
| 0    | Length of the message (excluding this byte)     | `3` or more     |
| 1    | Command ID (see commands to ESP)                | `FILE_GET_LIST` |
| 2    | Config                                          | `%zzzzzzzm`     |
|      | m: access mode (0: auto / 1: manual)            |                 |
|      | z: reserved for future use, must be set to zero |                 |

Using **auto mode**:  

| Byte | Description                                                          | Example            |
| ---- | -------------------------------------------------------------------- | ------------------ |
| 3    | Path index (see [FILE_PATHS](#File-paths))                           | `FILE_PATHS::SAVE` |
|      | **_next bytes are required if you want to use a pagination system_** |                    |
| 4    | Page size (number of files per page)                                 | `9`                |
| 5    | Current page (0 indexed)                                             | `1`                |

Using **manual mode**:  

| Byte | Description                                                          | Example |
| ---- | -------------------------------------------------------------------- | ------- |
| 3    | Item type(s) to return (0: files / 1: paths / 2: both)               | `2`     |
| 4    | Path string length                                                   | `4`     |
| 5    | Path string                                                          | `p`     |
| 6    | ...                                                                  | `a`     |
| 7    | ...                                                                  | `t`     |
| 8    | ...                                                                  | `h`     |
|      | **_next bytes are required if you want to use a pagination system_** |         |
| 9    | Page size (number of files per page)                                 | `9`     |
| 10   | Current page (0 indexed)                                             | `1`     |
  
**Notes:**
- First *path string* byte can be `/` or empty for root  
- Leading `/` is not required for a folder in root
- Trailing `/` is not mandatory  

**Returns:**

Message first bytes:  

| Byte | Description                                      | Example     |
| ---- | ------------------------------------------------ | ----------- |
| 0    | Length of the message (excluding this byte)      | `2` or more |
| 1    | Command ID (see commands from ESP)               | `FILE_LIST` |
| 2    | Number of files                                  | `3`         |
|      | **_next bytes are returned if files are found_** |             |

Using **auto mode**:  

| Byte | Description | Example |
| ---- | ----------- | ------- |
| 3    | File index  | `1`     |
| 4    | File index  | `5`     |
| 5    | File index  | `10`    |

Using **manual mode**:  

| Byte | Description        | Example      |
| ---- | ------------------ | ------------ |
| 3    | Item string length | `9`          |
| 4    | Item string        | `f`          |
| 5    | ...                | `i`          |
| 6    | ...                | `l`          |
| 7    | ...                | `e`          |
| 8    | ...                | `1`          |
| 9    | ...                | `.`          |
| 10   | ...                | `e`          |
| 11   | ...                | `x`          |
| 12   | ...                | `t`          |
| 13   | Item string length | `135` (0x87) |
| 14   | Item string        | `s`          |
| 15   | ...                | `u`          |
| 16   | ...                | `b`          |
| 17   | ...                | `p`          |
| 18   | ...                | `a`          |
| 19   | ...                | `t`          |
| 20   | ...                | `h`          |

**Notes:**
- If bit 7 of the item string length is set, then it's a folder.  
- The maximum number of returned items is 19 because of the message length limitation.  

[Back to command list](#Commands-overview)

---

### FILE_GET_FREE_ID

Get first free file ID in a specific predefined path.  

| Byte | Description                                 | Example            |
| ---- | ------------------------------------------- | ------------------ |
| 0    | Length of the message (excluding this byte) | `2`                |
| 1    | Command ID (see commands to ESP)            | `FILE_GET_FREE_ID` |
| 2    | Path index (see [FILE_PATHS](#File-paths))  | `FILE_PATHS::SAVE` |

**Returns:**

| Byte | Description                                            | Example    |
| ---- | ------------------------------------------------------ | ---------- |
| 0    | Length of the message (excluding this byte)            | `1` or `2` |
| 1    | Command ID (see commands from ESP)                     | `FILE_ID`  |
|      | **_next byte is returned if a free file ID is found_** |            |
| 2    | File ID                                                | `3`        |

[Back to command list](#Commands-overview)

---

### FILE_GET_INFO

This command returns file info (size in bytes and crc32).  
It can be used in auto mode (using predefined path index and filename index) or in manual mode (using path/filename string).  

Message first bytes:  

| Byte | Description                                     | Example         |
| ---- | ----------------------------------------------- | --------------- |
| 0    | Length of the message (excluding this byte)     | `4` or more     |
| 1    | Command ID (see commands to ESP)                | `FILE_GET_INFO` |
| 2    | Config                                          | `%zzzzzzzm`     |
|      | m: access mode (0: auto / 1: manual)            |                 |
|      | z: reserved for future use, must be set to zero |                 |

Using **auto mode**:  

| Byte | Description                                | Example            |
| ---- | ------------------------------------------ | ------------------ |
| 3    | Path index (see [FILE_PATHS](#File-paths)) | `FILE_PATHS::SAVE` |
| 4    | File index                                 | `5 (0 to 63)`      |

Using **manual mode**:  

| Byte | Description        | Example |
| ---- | ------------------ | ------- |
| 3    | File string length | `15`    |
| 4    | File string        | `f`     |
| 5    | ...                | `o`     |
| 6    | ...                | `l`     |
| 7    | ...                | `d`     |
| 8    | ...                | `e`     |
| 9    | ...                | `r`     |
| 10   | ...                | `/`     |
| 11   | ...                | `f`     |
| 12   | ...                | `i`     |
| 13   | ...                | `l`     |
| 14   | ...                | `e`     |
| 15   | ...                | `.`     |
| 16   | ...                | `e`     |
| 17   | ...                | `x`     |
| 18   | ...                | `t`     |

**Returns:**

| Byte | Description                                    | Example     |
| ---- | ---------------------------------------------- | ----------- |
| 0    | Length of the message (excluding this byte)    | `1` or `9`  |
| 1    | Command ID (see commands from ESP)             | `FILE_INFO` |
|      | **_next bytes are returned if file is found_** |             |
| 2    | CRC32 MSB                                      | `3B`        |
| 3    | CRC32                                          | `84`        |
| 4    | CRC32                                          | `E6`        |
| 5    | CRC32 LSB                                      | `FB`        |
| 6    | Size MSB                                       | `00`        |
| 7    | Size                                           | `00`        |
| 8    | Size                                           | `10`        |
| 9    | Size LSB                                       | `00`        |

[Back to command list](#Commands-overview)

---

### FILE_DOWNLOAD

This command downloads a file from a specific URL to a specific path index / file index.  
It can be used in auto mode (using predefined path index and filename index) or in manual mode (using path/filename string).  
If the destination file exists, it'll be deleted.  
The URL **must** use HTTP or HTTPS protocol.  

Message first bytes:  

| Byte | Description                                     | Example                          |
| ---- | ----------------------------------------------- | -------------------------------- |
| 0    | Length of the message (excluding this byte)     | `28` (depends on message length) |
| 1    | Command ID (see commands to ESP)                | `FILE_DOWNLOAD`                  |
| 2    | Config                                          | `%zzzzzzzm`                      |
|      | m: access mode (0: auto / 1: manual)            |                                  |
|      | z: reserved for future use, must be set to zero |                                  |
| 3    | URL String length                               | `22`                             |
| 4    | URL String (source)                             | `h`                              |
| 5    | ...                                             | `t`                              |
| 6    | ...                                             | `t`                              |
| 7    | ...                                             | `p`                              |
| 8    | ...                                             | `:`                              |
| 9    | ...                                             | `/`                              |
| 10   | ...                                             | `/`                              |
| 11   | ...                                             | `u`                              |
| 12   | ...                                             | `r`                              |
| 13   | ...                                             | `l`                              |
| 14   | ...                                             | `.`                              |
| 15   | ...                                             | `f`                              |
| 16   | ...                                             | `r`                              |
| 17   | ...                                             | `/`                              |
| 18   | ...                                             | `f`                              |
| 19   | ...                                             | `i`                              |
| 20   | ...                                             | `l`                              |
| 21   | ...                                             | `e`                              |
| 22   | ...                                             | `.`                              |
| 23   | ...                                             | `t`                              |
| 24   | ...                                             | `x`                              |
| 25   | ...                                             | `t`                              |

Using **auto mode**:  

| Byte | Description                                | Example            |
| ---- | ------------------------------------------ | ------------------ |
| 26   | Path index (see [FILE_PATHS](#File-paths)) | `FILE_PATHS::SAVE` |
| 27   | File ID                                    | `3`                |

Using **manual mode**:  

| Byte | Description               | Example |
| ---- | ------------------------- | ------- |
| 26   | File string length        | `13`    |
| 27   | File string (destination) | `p`     |
| 28   | ...                       | `a`     |
| 29   | ...                       | `t`     |
| 30   | ...                       | `h`     |
| 31   | ...                       | `/`     |
| 32   | ...                       | `f`     |
| 33   | ...                       | `i`     |
| 34   | ...                       | `l`     |
| 35   | ...                       | `e`     |
| 36   | ...                       | `.`     |
| 37   | ...                       | `e`     |
| 38   | ...                       | `x`     |
| 39   | ...                       | `t`     |

**Returns:**

| Byte | Description                                       | Example         |
| ---- | ------------------------------------------------- | --------------- |
| 0    | Length of the message (excluding this byte)       | `4`             |
| 1    | Command ID (see commands from ESP)                | `FILE_DOWNLOAD` |
| 2    | Result code (see below)                           | `0`             |
| 3    | HTTP status MSB                                   | `0x00`          |
| 4    | HTTP status LSB or network error code (see notes) | `0xC8`          |

**Result codes:**

| Value | Description                                |
| ----- | ------------------------------------------ |
| 0     | Success (HTTP status in 2xx)               |
| 1     | Invalid destination (path/filename)        |
| 2     | Error while deleting existing file         |
| 3     | Unknown / unsupported protocol             |
| 4     | Network error (code in byte 4, see below ) |
| 5     | HTTP status is not in 2xx                  |

**Network error codes:**

| Value | Description         |
| ----- | ------------------- |
| -1    | Connection failed   |
| -2    | Send header failed  |
| -3    | Send payload failed |
| -4    | Not connected       |
| -5    | Connection lost     |
| -6    | No stream           |
| -7    | No HTTP server      |
| -8    | Too less RAM        |
| -9    | Encoding            |
| -10   | Stream write        |
| -11   | Read timeout        |

**Notes:**
- Only HTTP and HTTPS protocols are supported.  
- HTTP status in the returned message is valid only if result code is 0 or 5.  
- If result code is 5, the body of the message is wrote on destination (as if the code was 0).  
- If result code is 4, fourth byte of the returned message contained the network error code.  

[Back to command list](#Commands-overview)

---

### FILE_FORMAT

This command formats the file system.  
Current ESP configuration will be saved afterwards.  

| Byte | Description                                 | Example       |
| ---- | ------------------------------------------- | ------------- |
| 0    | Length of the message (excluding this byte) | `1`           |
| 1    | Command ID (see commands to ESP)            | `FILE_FORMAT` |

[Back to command list](#Commands-overview)

---

## Bootloader

We encourage developers to add a bootloader to their ROM. It could be accessed via a combination of buttons at startup. This could allow the user to perform some low level actions. For Example, if the game allow self-flashing for online updates, the bootloader menu could offer the possibility to backup the current ROM before updating, or even restoring the backed up ROM if the update failed.
Those are basic ideas, but more are to come ...

---

## TODO

- [ ] Add math functions/commands (multiplication, division, cos, sin, ...)
- [ ] Add bootloader source code to github and link it in the Bootloader section
  