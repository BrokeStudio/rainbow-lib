# Rainbow WiFi documentation

> **Disclaimer**  
>  
> This document and the project are still WIP and are subject to modifications.  
> &nbsp;  

## Credits

The Rainbow project is developed by Antoine Gohin / Broke Studio.  

Thanks to :

- [Paul](https://twitter.com/InfiniteNesLive) / [InfiniteNesLives](http://www.infiniteneslives.com)  for taking time to explain me lots of hardware stuff
- Christian Gohin, my father, who helped me designing the board
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
    - [NES to ESP commands](#nes-to-esp-commands)
    - [ESP to NES commands](#esp-to-nes-commands)
  - [Commands details](#commands-details)
    - [GET_ESP_STATUS](#get_esp_status)
    - [DEBUG_GET_CONFIG](#debug_get_config)
    - [DEBUG_SET_CONFIG](#debug_set_config)
    - [DEBUG_LOG](#debug_log)
    - [CLEAR_BUFFERS](#clear_buffers)
    - [E2N_BUFFER_DROP](#e2n_buffer_drop)
    - [GET_WIFI_STATUS](#get_wifi_status)
    - [GET_RND_BYTE](#get_rnd_byte)
    - [GET_RND_BYTE_RANGE](#get_rnd_byte_range)
    - [GET_RND_WORD](#get_rnd_word)
    - [GET_RND_WORD_RANGE](#get_rnd_word_range)
    - [GET_SERVER_STATUS](#get_server_status)
    - [GET_SERVER_PING](#get_server_ping)
    - [SET_SERVER_PROTOCOL](#set_server_protocol)
    - [GET_SERVER_SETTINGS](#get_server_settings)
    - [SET_SERVER_SETTINGS](#set_server_settings)
    - [CONNECT_SERVER](#connect_server)
    - [DISCONNECT_SERVER](#disconnect_server)
    - [SEND_MSG_TO_SERVER](#send_msg_to_server)
    - [FILE_OPEN](#file_open)
    - [FILE_CLOSE](#file_close)
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

**Note:** Because of the mapper buffer, the first read of a new message will always return the last read of the previous message. So a dummy read is required in this case. (*this is subject to change*)

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
  lda #N2E::FILE_DELETE       ; command
  sta $5000
  lda #FILE_PATHS::ROMS       ; paramater (path id)
  sta $5000
  lda #0                      ; parameter (file id)
  sta $5000

  ; this is possible too

  lda #2
  ldx #N2E::FILE_GET_LIST
  ldy #FILE_PATHS::ROMS
  sta $5000
  stx $5000
  sty $5000
```

**Note:** After you send the first byte of a new message, you have one second to send the rest of the message before the RX buffer is reset. This is to prevent the ESP to be stuck, waiting for a message that could never come. (*this is subject to change*)

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

- **TX**: data from the ESP to the NES buffer  
- **RX**: data from the NES to the ESP buffer  

Both buffers can store up to 20 messages.

## Messages format

A message always have the same format and follows these rules:  

- First byte is the message length (number of bytes following this first byte, can't be 0, minimum is 1).
- Second byte is the command (see NES to ESP commands).
- Following bytes are the parameters/data for the command.

## Commands overview

### NES to ESP commands

| Value | N2E commands                                | Description                                      |
| ----- | ------------------------------------------- | ------------------------------------------------ |
| 0     | [GET_ESP_STATUS](#GET_ESP_STATUS)           | Get ESP status                                   |
| 1     | [DEBUG_GET_CONFIG](#DEBUG_GET_CONFIG)       | Get debug configuration                          |
| 2     | [DEBUG_SET_CONFIG](#DEBUG_SET_CONFIG)       | Set debug configuration                          |
| 3     | [DEBUG_LOG](#DEBUG_LOG)                     | Debug / Log data                                 |
| 4     | [CLEAR_BUFFERS](#CLEAR_BUFFERS)             | Clear RX/TX buffers                              |
| 5     | [E2N_BUFFER_DROP](#E2N_BUFFER_DROP)         | Drop messages from TX (ESP->NES) buffer          |
| 6     | [GET_WIFI_STATUS](#GET_WIFI_STATUS)         | Get WiFi connection status                       |
| 7     | [GET_RND_BYTE](#GET_RND_BYTE)               | Get random byte                                  |
| 8     | [GET_RND_BYTE_RANGE](#GET_RND_BYTE_RANGE)   | Get random byte between custom min/max           |
| 9     | [GET_RND_WORD](#GET_RND_WORD)               | Get random word                                  |
| 10    | [GET_RND_WORD_RANGE](#GET_RND_WORD_RANGE)   | Get random word between custom min/max           |
| 11    | [GET_SERVER_STATUS](#GET_SERVER_STATUS)     | Get server connection status                     |
| 12    | [GET_SERVER_PING](#GET_SERVER_PING)         | Get ping between ESP and server                  |
| 13    | [SET_SERVER_PROTOCOL](#SET_SERVER_PROTOCOL) | Set protocol to be used to communicate (WS/UDP)  |
| 14    | [GET_SERVER_SETTINGS](#GET_SERVER_SETTINGS) | Get host name and port defined in the ESP config |
| 15    | [SET_SERVER_SETTINGS](#SET_SERVER_SETTINGS) | Set host name and port                           |
| 16    | [CONNECT_SERVER](#CONNECT_SERVER)           | Connect to server                                |
| 17    | [DISCONNECT_SERVER](#DISCONNECT_SERVER)     | Disconnect from server                           |
| 18    | [SEND_MSG_TO_SERVER](#SEND_MSG_TO_SERVER)   | Send message to rainbow server                   |
| 19    | [FILE_OPEN](#FILE_OPEN)                     | Open working file                                |
| 20    | [FILE_CLOSE](#FILE_CLOSE)                   | Close working file                               |
| 21    | [FILE_EXISTS](#FILE_EXISTS)                 | Check if file exists                             |
| 22    | [FILE_DELETE](#FILE_DELETE)                 | Delete a file                                    |
| 23    | [FILE_SET_CUR](#FILE_SET_CUR)               | Set working file cursor position a file          |
| 24    | [FILE_READ](#FILE_READ)                     | Read working file (at specific position)         |
| 25    | [FILE_WRITE](#FILE_WRITE)                   | Write working file (at specific position)        |
| 26    | [FILE_APPEND](#FILE_APPEND)                 | Append data to working file                      |
| 27    | [FILE_COUNT](#FILE_COUNT)                   | Get number of tiles in a specific path           |
| 28    | [FILE_GET_LIST](#FILE_GET_LIST)             | Get list of existing files in a specific path    |
| 29    | [FILE_GET_FREE_ID](#FILE_GET_FREE_ID)       | Get an unexisting file ID in a specific path.    |
| 30    | [FILE_GET_INFO](#FILE_GET_INFO)             | Get file info (size + crc32)                     |

### ESP to NES commands

| Value | E2N commands                               | Description |
| ----- | ------------------------------------------ | ----------- |
| 0     | [READY](#GET_ESP_STATUS)                   |             |
| 1     | [DEBUG_CONFIG](#DEBUG_GET_CONFIG)          |             |
| 2     | [FILE_EXISTS](#FILE_EXISTS)                |             |
| 3     | [FILE_DELETE](#FILE_DELETE)                |             |
| 4     | [FILE_LIST](#FILE_GET_LIST)                |             |
| 4     | [FILE_DATA](#FILE_READ)                    |             |
| 6     | [FILE_COUNT](#FILE_COUNT)                  |             |
| 7     | [FILE_ID](#FILE_GET_FREE_ID)               |             |
| 8     | [FILE_INFO](#FILE_GET_INFO)                |             |
| 9     | [WIFI_STATUS](#GET_WIFI_STATUS)            |             |
| 10    | [SERVER_STATUS](#GET_SERVER_STATUS)        |             |
| 11    | [SERVER_PING](#GET_SERVER_PING)            |             |
| 12    | [HOST_SETTINGS](#GET_SERVER_SETTINGS)      |             |
| 12    | [RND_BYTE](#GET_RND_BYTE)                  |             |
| 14    | [RND_WORD](#GET_RND_WORD)                  |             |
| 15    | [MESSAGE_FROM_SERVER](#SEND_MSG_TO_SERVER) |             |

## Commands details

### GET_ESP_STATUS

This command asks the WiFi module if it's ready.  
The ESP will only answer when ready, so once you sent the message, just wait for the answer.  

| Byte | Description                                 | Example               |
| ---- | ------------------------------------------- | --------------------- |
| 0    | Length of the message (excluding this byte) | `1`                   |
| 1    | Command ID (see NES to ESP commands list)   | `N2E::GET_ESP_STATUS` |

**Returns:**

| Byte | Description                                 | Example      |
| ---- | ------------------------------------------- | ------------ |
| 0    | Length of the message (excluding this byte) | `1`          |
| 1    | Command ID (see ESP to NES commands list)   | `E2N::READY` |

[Back to command list](#Commands-overview)

---

### DEBUG_GET_CONFIG

This command returns the debug configuration. 

| Byte | Description                                 | Example                 |
| ---- | ------------------------------------------- | ----------------------- |
| 0    | Length of the message (excluding this byte) | `1`                     |
| 1    | Command ID (see NES 2 ESP commands list)    | `N2E::DEBUG_GET_CONFIG` |

**Returns:**

| Byte | Description                                 | Example             |
| ---- | ------------------------------------------- | ------------------- |
| 0    | Length of the message (excluding this byte) | `2`                 |
| 1    | Command ID (see ESP to NES commands list)   | `E2N::DEBUG_CONFIG` |
| 2    | Debug configuration value                   | `0`                 |

See [DEBUG_SET_CONFIG](#DEBUG_SET_CONFIG) command for debug configuration value details

[Back to command list](#Commands-overview)

---

### DEBUG_SET_CONFIG

This command sets the debug configuration. 

| Byte | Description                                 | Example                 |
| ---- | ------------------------------------------- | ----------------------- |
| 0    | Length of the message (excluding this byte) | `2`                     |
| 1    | Command ID (see NES 2 ESP commands list)    | `N2E::DEBUG_SET_CONFIG` |
| 2    | Debug configuration value                   | `1`                     |

**The configuration value uses bits like this:**

```
7  bit  0
---- ----
.... ..sl
       ||
       |+-  enable/disable log output 
       +--  enable/disable serial output log
            outputs what was sent to the NES
            NOTE: this is not recommended when lots of messages
                  are exchanged (ex: during real-time game),
                  the ESP can't keep up
```

[Back to command list](#Commands-overview)

---

### DEBUG_LOG

This command logs data on the serial port of the ESP.  
Can be read using a UART/USB adapter, RX to pin 5 of the ESP board edge connector, GND to pin 6.  

| Byte | Description                                 | Example          |
| ---- | ------------------------------------------- | ---------------- |
| 0    | Length of the message (excluding this byte) | `4`              |
| 1    | Command ID (see NES 2 ESP commands list)    | `N2E::DEBUG_LOG` |
| 2    | Data length                                 | `2`              |
| 3    | Data                                        | `0x41`           |
| 4    | Data                                        | `0xAC`           |

[Back to command list](#Commands-overview)

---

### CLEAR_BUFFERS

This command clears TX/RX buffers.  
Can be use on startup to make sure that we start with a clean setup.

| Byte | Description                                 | Example              |
| ---- | ------------------------------------------- | -------------------- |
| 0    | Length of the message (excluding this byte) | `1`                  |
| 1    | Command ID (see NES 2 ESP commands list)    | `N2E::CLEAR_BUFFERS` |

[Back to command list](#Commands-overview)

---

### E2N_BUFFER_DROP

This command drops messages of a given type from TX (ESP->NES) buffer.  
You can keep the most recent messages using the second parameter.  

| Byte | Description                                     | Example                    |
| ---- | ----------------------------------------------- | -------------------------- |
| 0    | Length of the message (excluding this byte)     | `3`                        |
| 1    | Command ID (see NES 2 ESP commands list)        | `N2E::E2N_BUFFER_DROP`     |
| 2    | Message type / ID (see ESP 2 NES commands list) | `E2N::MESSAGE_FROM_SERVER` |
| 3    | Number of most recent messages to keep          | `1`                        |

[Back to command list](#Commands-overview)

---

### GET_WIFI_STATUS

This command asks the WiFi status.

| Byte | Description                                 | Example                |
| ---- | ------------------------------------------- | ---------------------- |
| 0    | Length of the message (excluding this byte) | `1`                    |
| 1    | Command ID (see NES 2 ESP commands list)    | `N2E::GET_WIFI_STATUS` |

**Returns:**

| Byte | Description                                 | Example                  |
| ---- | ------------------------------------------- | ------------------------ |
| 0    | Length of the message (excluding this byte) | `2`                      |
| 1    | Command ID (see ESP to NES commands list)   | `E2N::WIFI_STATUS`       |
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

### GET_RND_BYTE

This command returns a random byte between 0 and 255.

| Byte | Description                                 | Example             |
| ---- | ------------------------------------------- | ------------------- |
| 0    | Length of the message (excluding this byte) | `1`                 |
| 1    | Command ID (see NES 2 ESP commands list)    | `N2E::GET_RND_BYTE` |

**Returns:**

| Byte | Description                                 | Example         |
| ---- | ------------------------------------------- | --------------- |
| 0    | Length of the message (excluding this byte) | `2`             |
| 1    | Command ID (see ESP to NES commands list)   | `E2N::RND_BYTE` |
| 2    | Random value between 0 and 255              | `0xAA`          |

[Back to command list](#Commands-overview)

---

### GET_RND_BYTE_RANGE

This command returns a random byte between custom min and max values.  

| Byte | Description                                 | Example                   |
| ---- | ------------------------------------------- | ------------------------- |
| 0    | Length of the message (excluding this byte) | `3`                       |
| 1    | Command ID (see NES 2 ESP commands list)    | `N2E::GET_RND_BYTE_RANGE` |
| 2    | Custom min value (0 to 254)                 | `0x00`                    |
| 3    | Custom max value (1 to 255)                 | `0x80`                    |

**Returns:**

| Byte | Description                                 | Example         |
| ---- | ------------------------------------------- | --------------- |
| 0    | Length of the message (excluding this byte) | `2`             |
| 1    | Command ID (see ESP to NES commands list)   | `E2N::RND_BYTE` |
| 2    | Random value between 0 and 255              | `0x14`          |

[Back to command list](#Commands-overview)

---

### GET_RND_WORD

This command returns a random word between 0 and 65535.

| Byte | Description                                 | Example             |
| ---- | ------------------------------------------- | ------------------- |
| 0    | Length of the message (excluding this byte) | `1`                 |
| 1    | Command ID (see NES 2 ESP commands list)    | `N2E::GET_RND_WORD` |

**Returns:**

| Byte | Description                                 | Example         |
| ---- | ------------------------------------------- | --------------- |
| 0    | Length of the message (excluding this byte) | `3`             |
| 1    | Command ID (see ESP to NES commands list)   | `E2N::RND_WORD` |
| 2    | Random value HI byte                        | `0xA7`          |
| 3    | Random value LO byte                        | `0xEF`          |

[Back to command list](#Commands-overview)

---

### GET_RND_WORD_RANGE

This command returns a random word between custom min and max values.

| Byte | Description                                 | Example                   |
| ---- | ------------------------------------------- | ------------------------- |
| 0    | Length of the message (excluding this byte) | `5`                       |
| 1    | Command ID (see NES 2 ESP commands list)    | `N2E::GET_RND_WORD_RANGE` |
| 2    | Custom min value (0 to 65534) HI byte       | `0x00`                    |
| 3    | Custom min value (0 to 65534) LO byte       | `0x00`                    |
| 4    | Custom max value (1 to 65535) HI byte       | `0x20`                    |
| 5    | Custom max value (1 to 65535) LO byte       | `0x00`                    |

**Returns:**

| Byte | Description                                 | Example         |
| ---- | ------------------------------------------- | --------------- |
| 0    | Length of the message (excluding this byte) | `3`             |
| 1    | Command ID (see ESP to NES commands list)   | `E2N::RND_WORD` |
| 2    | Random value HI byte                        | `0x06`          |
| 3    | Random value LO byte                        | `0x82`          |

[Back to command list](#Commands-overview)

---

### GET_SERVER_STATUS

This command asks the server status.

| Byte | Description                                 | Example                  |
| ---- | ------------------------------------------- | ------------------------ |
| 0    | Length of the message (excluding this byte) | `1`                      |
| 1    | Command ID (see NES 2 ESP commands list)    | `N2E::GET_SERVER_STATUS` |

**Returns:**

| Byte | Description                                 | Example                    |
| ---- | ------------------------------------------- | -------------------------- |
| 0    | Length of the message (excluding this byte) | `2`                        |
| 1    | Command ID (see ESP to NES commands list)   | `E2N::SERVER_STATUS`       |
| 2    | Server status (see below)                   | `SERVER_STATUS::CONNECTED` |

**Server status:**

| Value | SERVER_STATUS | Description  |
| ----- | ------------- | ------------ |
| 0     | DISCONNECTED  | Disconnected |
| 1     | CONNECTED     | Connected    |

[Back to command list](#Commands-overview)

---

### GET_SERVER_PING

This command pings the server and returns the min, max and average round-trip time and number of lost packets.  
If another ping is already in progress, the command will be ignored.  
Returned round-trip time is divided by 4 to fit in only 1 byte, so time precision is 4ms.  
If no number of pings is passed, the default value will be 4.  

| Byte | Description                                                            | Example                |
| ---- | ---------------------------------------------------------------------- | ---------------------- |
| 0    | Length of the message (excluding this byte)                            | `1` or `2`             |
| 1    | Command ID (see NES 2 ESP commands list)                               | `N2E::GET_SERVER_PING` |
|      | *the next byte is required if you want to specify the number of pings* |                        |
| 2    | Number of pings                                                        | `4`                    |
|      | *if 0 is passed, this will perform 4 pings by default*                 |                        |

**Returns:**

Following message will be sent if server hostname couldn't be resolved or is empty:

| Byte | Description                                 | Example            |
| ---- | ------------------------------------------- | ------------------ |
| 0    | Length of the message (excluding this byte) | `1`                |
| 1    | Command ID (see ESP to NES commands list)   | `E2N::SERVER_PING` |

Following message will be sent after ping:

| Byte | Description                                  | Example            |
| ---- | -------------------------------------------- | ------------------ |
| 0    | Length of the message (excluding this byte)  | `5`                |
| 1    | Command ID (see ESP to NES commands list)    | `E2N::SERVER_PING` |
| 2    | Minimum ping round-trip time (4ms precision) | `0x2D`             |
| 3    | Maximum ping round-trip time (4ms precision) | `0x42`             |
| 4    | Average ping round-trip time (4ms precision) | `0x37`             |
| 5    | Number of lost packets                       | `0x01`             |

[Back to command list](#Commands-overview)

---

### SET_SERVER_PROTOCOL

This command sets the protocol to be use when talking to game server.

| Byte | Description                                 | Example                    |
| ---- | ------------------------------------------- | -------------------------- |
| 0    | Length of the message (excluding this byte) | `2`                        |
| 1    | Command ID (see NES 2 ESP commands list)    | `N2E::SET_SERVER_PROTOCOL` |
| 2    | Protocol value (see below)                  | `PROTOCOL::WS`             |

**Protocol values:**

| Value | PROTOCOL | Description |
| ----- | -------- | ----------- |
| 0     | WS       | WebSocket   |
| 1     | UDP      | UDP         |

[Back to command list](#Commands-overview)

---

### GET_SERVER_SETTINGS

This command gets the server settings (IP address and port).

| Byte | Description                                 | Example                    |
| ---- | ------------------------------------------- | -------------------------- |
| 0    | Length of the message (excluding this byte) | `1`                        |
| 1    | Command ID (see NES 2 ESP commands list)    | `N2E::GET_SERVER_SETTINGS` |

**Returns:**

| Byte | Description                                                                   | Example              |
| ---- | ----------------------------------------------------------------------------- | -------------------- |
| 0    | Length of the message (excluding this byte)                                   | `1` or more          |
| 1    | Command ID (see ESP to NES commands list)                                     | `E2N::HOST_SETTINGS` |
|      | *next bytes are returned if a server host AND port are set in the ESP config* |                      |
| 2    | Port MSB                                                                      | `0x0B`               |
| 3    | Port LSB                                                                      | `0xB8`               |
| 4    | Hostname string                                                               | `G`                  |
| 5    | ...                                                                           | `A`                  |
| 6    | ...                                                                           | `M`                  |
| 7    | ...                                                                           | `E`                  |
| 8    | ...                                                                           | `.`                  |
| 9    | ...                                                                           | `S`                  |
| 10   | ...                                                                           | `E`                  |
| 11   | ...                                                                           | `R`                  |
| 12   | ...                                                                           | `V`                  |
| 13   | ...                                                                           | `E`                  |
| 14   | ...                                                                           | `R`                  |
| 15   | ...                                                                           | `.`                  |
| 16   | ...                                                                           | `N`                  |
| 17   | ...                                                                           | `E`                  |
| 18   | ...                                                                           | `T`                  |

[Back to command list](#Commands-overview)

---

### SET_SERVER_SETTINGS

This command sets the server settings (IP address and port).  
It doesn't overwrite values set via the ESP web interface.  

| Byte | Description                                 | Example                          |
| ---- | ------------------------------------------- | -------------------------------- |
| 0    | Length of the message (excluding this byte) | `18` (depends on message length) |
| 1    | Command ID (see NES 2 ESP commands list)    | `N2E::SET_SERVER_SETTINGS`       |
| 2    | Port MSB                                    | `0x0B`                           |
| 3    | Port LSB                                    | `0xB8`                           |
| 4    | Hostname string                             | `S`                              |
| 5    | Hostname string                             | `E`                              |
| 6    | Hostname string                             | `R`                              |
| 7    | Hostname string                             | `V`                              |
| 8    | Hostname string                             | `E`                              |
| 9    | Hostname string                             | `R`                              |
| 10   | Hostname string                             | `.`                              |
| 11   | Hostname string                             | `N`                              |
| 12   | Hostname string                             | `E`                              |
| 13   | Hostname string                             | `T`                              |

[Back to command list](#Commands-overview)

---

### CONNECT_SERVER

When using WS protocol, this command connects to server.  
When using UDP protocol, this command starts the UDP server on the ESP side using a random port between 49152 and 65535.  

| Byte | Description                                 | Example               |
| ---- | ------------------------------------------- | --------------------- |
| 0    | Length of the message (excluding this byte) | `1`                   |
| 1    | Command ID (see NES 2 ESP commands list)    | `N2E::CONNECT_SERVER` |

[Back to command list](#Commands-overview)

---

### DISCONNECT_SERVER

When using WS protocol, this command disconnects from server.  
When using UDP protocol, this command stops the UDP server on the ESP side.  

| Byte | Description                                 | Example                  |
| ---- | ------------------------------------------- | ------------------------ |
| 0    | Length of the message (excluding this byte) | `1`                      |
| 1    | Command ID (see NES 2 ESP commands list)    | `N2E::DISCONNECT_SERVER` |

[Back to command list](#Commands-overview)

---

### SEND_MSG_TO_SERVER

This command sends a message to the server.  

| Byte | Description                                 | Example                          |
| ---- | ------------------------------------------- | -------------------------------- |
| 0    | Length of the message (excluding this byte) | `30` (depends on message length) |
| 1    | Command ID (see NES 2 ESP commands list)    | `N2E::SEND_MSG_TO_SERVER`        |
| 2    | Data                                        | `0xAA`                           |
| ...  | Data                                        | `0x12`                           |
| 30   | Data                                        | `0xE9`                           |

[Back to command list](#Commands-overview)

---

### FILE_OPEN

This command opens the working file.  
If the file does not exists, an empty one will be created.  
If the same file is already open, then the file cursor will be reset to 0.  
If another file is already open, it will be closed.  

| Byte | Description                                 | Example            |
| ---- | ------------------------------------------- | ------------------ |
| 0    | Length of the message (excluding this byte) | `3`                |
| 1    | Command ID (see NES to ESP commands list)   | `N2E::FILE_OPEN`   |
| 2    | File path (see FILE_PATHS)                  | `FILE_PATHS::SAVE` |
| 3    | File index                                  | `5 (0 to 63)`      |

**File paths:**

| Value | FILE_PATHS | Description                                     |
| ----- | ---------- | ----------------------------------------------- |
| 0     | SAVE       | Use this folder to load/save game data          |
| 1     | ROMS       | Use this folder to dump/flash ROMS, patches     |
| 2     | USER       | Use this folder to read/write data for the user |

[Back to command list](#Commands-overview)

---

### FILE_CLOSE

This command closes the working file.  

| Byte | Description                                 | Example           |
| ---- | ------------------------------------------- | ----------------- |
| 0    | Length of the message (excluding this byte) | `1`               |
| 1    | Command ID (see NES to ESP commands list)   | `N2E::FILE_CLOSE` |

[Back to command list](#Commands-overview)

---

### FILE_EXISTS

This command checks if a file exists.  
This command returns 1 if the file exists, or 0 if it doesn't.  

| Byte | Description                                 | Example            |
| ---- | ------------------------------------------- | ------------------ |
| 0    | Length of the message (excluding this byte) | `3`                |
| 1    | Command ID (see NES to ESP commands list)   | `N2E::FILE_EXISTS` |
| 2    | File path (see FILE_PATHS)                  | `FILE_PATHS::SAVE` |
| 3    | File index                                  | `5 (0 to 63)`      |

**File paths:**

| Value | FILE_PATHS | Description                                     |
| ----- | ---------- | ----------------------------------------------- |
| 0     | SAVE       | Use this folder to load/save game data          |
| 1     | ROMS       | Use this folder to dump/flash ROMS, patches     |
| 2     | USER       | Use this folder to read/write data for the user |

**Returns:**

| Byte | Description                                 | Example            |
| ---- | ------------------------------------------- | ------------------ |
| 0    | Length of the message (excluding this byte) | `2`                |
| 1    | Command ID (see ESP to NES commands list)   | `E2N::FILE_EXISTS` |
| 2    | Returns 1 if file exists, 0 otherwise       | `0` or `1`         |

[Back to command list](#Commands-overview)

---

### FILE_DELETE

This command deletes (if exists) the file corresponding of the passed index.  

| Byte | Description                                 | Example            |
| ---- | ------------------------------------------- | ------------------ |
| 0    | Length of the message (excluding this byte) | `3`                |
| 1    | Command ID (see NES to ESP commands list)   | `N2E::FILE_DELETE` |
| 2    | File path (see FILE_PATHS)                  | `FILE_PATHS::SAVE` |
| 3    | File index                                  | `5 (0 to 63)`      |

**File paths:**

| Value | FILE_PATHS | Description                                     |
| ----- | ---------- | ----------------------------------------------- |
| 0     | SAVE       | Use this folder to load/save game data          |
| 1     | ROMS       | Use this folder to dump/flash ROMS, patches     |
| 2     | USER       | Use this folder to read/write data for the user |

**Returns:**

| Byte | Description                                 | Example            |
| ---- | ------------------------------------------- | ------------------ |
| 0    | Length of the message (excluding this byte) | `2`                |
| 1    | Command ID (see ESP to NES commands list)   | `E2N::FILE_DELETE` |
| 2    | Result code                                 | `0` or `1` or `2`  |

**Result codes:**

| Value | Description                           |
| ----- | ------------------------------------- |
| 0     | File successfully deleted             |
| 1     | Error while trying to delete the file |
| 2     | File does not exist                   |

[Back to command list](#Commands-overview)

---

### FILE_SET_CUR

This command sets the position of the working file cursor.  
If the file is smaller than the passed offset, it'll be filled with 0x00.  

| Byte    | Description                                 | Example             |
| ------- | ------------------------------------------- | ------------------- |
| 0       | Length of the message (excluding this byte) | `2 to 5`            |
| 1       | Command ID (see NES to ESP commands list)   | `N2E::FILE_SET_CUR` |
| 2       | Offset LSB                                  | `0x00`              |
| 3 (opt) | Offset                                      | `0x00`              |
| 4 (opt) | Offset                                      | `0x10`              |
| 5 (opt) | Offset MSB                                  | `0x00`              |

[Back to command list](#Commands-overview)

---

### FILE_READ

This command reads and sends data from the working file.  
You have to pass the number of bytes you want to read.  
If there is working file currently open, number of bytes will be 0.

| Byte | Description                                 | Example          |
| ---- | ------------------------------------------- | ---------------- |
| 0    | Length of the message (excluding this byte) | `2`              |
| 1    | Command ID (see NES to ESP commands list)   | `N2E::FILE_READ` |
| 2    | Number of bytes to read                     | `64` (minimum 1) |

**Returns:**

| Byte | Description                                 | Example                                   |
| ---- | ------------------------------------------- | ----------------------------------------- |
| 0    | Length of the message (excluding this byte) | `5` (depends on the number of bytes read) |
| 1    | Command ID (see ESP to NES commands list)   | `E2N::FILE_DATA`                          |
| 2    | Number of bytes returned                    | `03`                                      |
| 3    | Data                                        | `0x12`                                    |
| 4    | Data                                        | `0xDA`                                    |
| 5    | Data                                        | `0x4C`                                    |

**Note:** Number of bytes returned can be less than the number of bytes requested depending on the file size and the file cursor position.  

[Back to command list](#Commands-overview)

---

### FILE_WRITE

This command writes data to the working file.  

| Byte | Description                                 | Example                                             |
| ---- | ------------------------------------------- | --------------------------------------------------- |
| 0    | Length of the message (excluding this byte) | `66`  (depends on how many bytes you want to write) |
| 1    | Command ID (see NES to ESP commands list)   | `N2E::FILE_WRITE`                                   |
| 2    | Data                                        | `0x5F`                                              |
| ...  | Data                                        | `...`                                               |
| 66   | Data                                        | `0xAF`                                              |

[Back to command list](#Commands-overview)

---

### FILE_APPEND

This command appends data to the working file.  
The current cursor position is not affected.  

| Byte | Description                                 | Example                                            |
| ---- | ------------------------------------------- | -------------------------------------------------- |
| 0    | Length of the message (excluding this byte) | `66` (depends on how many bytes you want to write) |
| 1    | Command ID (see NES to ESP commands list)   | `N2E::FILE_APPEND`                                 |
| 2    | Data                                        | `0x5F`                                             |
| ...  | Data                                        | `...`                                              |
| 66   | Data                                        | `0xAF`                                             |

[Back to command list](#Commands-overview)

---

### FILE_COUNT

This command sends the number of files in a specific path.  

| Byte | Description                                 | Example           |
| ---- | ------------------------------------------- | ----------------- |
| 0    | Length of the message (excluding this byte) | `1`               |
| 1    | Command ID (see NES to ESP commands list)   | `N2E::FILE_COUNT` |

**File paths:**

| Value | FILE_PATHS | Description                                     |
| ----- | ---------- | ----------------------------------------------- |
| 0     | SAVE       | Use this folder to load/save game data          |
| 1     | ROMS       | Use this folder to dump/flash ROMS, patches     |
| 2     | USER       | Use this folder to read/write data for the user |
[Back to command list](#Commands-overview)

**Returns:**

| Byte | Description                                 | Example           |
| ---- | ------------------------------------------- | ----------------- |
| 0    | Length of the message (excluding this byte) | `2`               |
| 1    | Command ID (see ESP to NES commands list)   | `E2N::FILE_COUNT` |
| 2    | Number of files                             | `3`               |

---

### FILE_GET_LIST

Get list of existing files in a specific path.  

| Byte | Description                                                          | Example              |
| ---- | -------------------------------------------------------------------- | -------------------- |
| 0    | Length of the message (excluding this byte)                          | `2` or more          |
| 1    | Command ID (see NES to ESP commands list)                            | `N2E::FILE_GET_LIST` |
| 2    | File path (see FILE_PATHS)                                           | `FILE_PATHS::SAVE`   |
|      | *the next bytes are required if you want to use a pagination system* |                      |
| 3    | Page size (number of files per page)                                 | `9`                  |
| 4    | Current page (0 indexed)                                             | `1`                  |

**File paths:**

| Value | FILE_PATHS | Description                                     |
| ----- | ---------- | ----------------------------------------------- |
| 0     | SAVE       | Use this folder to load/save game data          |
| 1     | ROMS       | Use this folder to dump/flash ROMS, patches     |
| 2     | USER       | Use this folder to read/write data for the user |

**Returns:**

| Byte | Description                                  | Example          |
| ---- | -------------------------------------------- | ---------------- |
| 0    | Length of the message (excluding this byte)  | `2` or more      |
| 1    | Command ID (see ESP to NES commands list)    | `E2N::FILE_LIST` |
| 2    | Number of files                              | `3`              |
|      | *next bytes are returned if files are found* |                  |
| 3    | File index                                   | `1`              |
| 4    | File index                                   | `5`              |
| 5    | File index                                   | `10`             |

[Back to command list](#Commands-overview)

---

### FILE_GET_FREE_ID

Get an unexisting file ID in a specific path.

| Byte | Description                                 | Example                 |
| ---- | ------------------------------------------- | ----------------------- |
| 0    | Length of the message (excluding this byte) | `2`                     |
| 1    | Command ID (see NES to ESP commands list)   | `N2E::FILE_GET_FREE_ID` |
| 2    | File path (see FILE_PATHS)                  | `FILE_PATHS::SAVE`      |

**File paths:**

| Value | FILE_PATHS | Description                                     |
| ----- | ---------- | ----------------------------------------------- |
| 0     | SAVE       | Use this folder to load/save game data          |
| 1     | ROMS       | Use this folder to dump/flash ROMS, patches     |
| 2     | USER       | Use this folder to read/write data for the user |

**Returns:**

| Byte | Description                                        | Example        |
| ---- | -------------------------------------------------- | -------------- |
| 0    | Length of the message (excluding this byte)        | `1` or more    |
| 1    | Command ID (see ESP to NES commands list)          | `E2N::FILE_ID` |
|      | *next byte is returned if a free file ID is found* |                |
| 2    | File ID                                            | `3`            |

[Back to command list](#Commands-overview)

---

### FILE_GET_INFO

This command returns file info (size in bytes and crc32).  

| Byte | Description                                 | Example              |
| ---- | ------------------------------------------- | -------------------- |
| 0    | Length of the message (excluding this byte) | `3`                  |
| 1    | Command ID (see NES to ESP commands list)   | `N2E::FILE_GET_INFO` |
| 2    | File path (see FILE_PATHS)                  | `FILE_PATHS::SAVE`   |
| 3    | File index                                  | `5 (0 to 63)`        |

**File paths:**

| Value | FILE_PATHS | Description                                     |
| ----- | ---------- | ----------------------------------------------- |
| 0     | SAVE       | Use this folder to load/save game data          |
| 1     | ROMS       | Use this folder to dump/flash ROMS, patches     |
| 2     | USER       | Use this folder to read/write data for the user |

**Returns:**

| Byte | Description                                 | Example          |
| ---- | ------------------------------------------- | ---------------- |
| 0    | Length of the message (excluding this byte) | `1` or `9`       |
| 1    | Command ID (see ESP to NES commands list)   | `E2N::FILE_INFO` |
|      | *next bytes are returned if file is  found* |                  |
| 2    | CRC32 MSB                                   | `3B`             |
| 3    | CRC32                                       | `84`             |
| 4    | CRC32                                       | `E6`             |
| 5    | CRC32 LSB                                   | `FB`             |
| 6    | Size MSB                                    | `00`             |
| 7    | Size                                        | `00`             |
| 8    | Size                                        | `10`             |
| 9    | Size LSB                                    | `00`             |

[Back to command list](#Commands-overview)

---

## Bootloader

We encourage developers to add a bootloader to their ROM. It could be accessed via a combination of buttons at startup. This could allow the user to perform some low level actions. For Example, if the game allow self-flashing for online updates, the bootloader menu could offer the possibility to backup the current ROM before updating, or even restoring the backed up ROM if the update failed.
Those are basic ideas, but more are to come ...

---

## TODO

- [ ] Add math functions/commands (multiplication, division, cos, sin, ...)
- [ ] Add bootloader source code to github and link it in the Bootloader section
  