; ################################################################################
; RAINBOW CONSTANTS

; commands to ESP
.enum TO_ESP

; ESP CMDS
  ESP_GET_STATUS                  ; Get ESP status
  DEBUG_GET_LEVEL                 ; Get debug level
  DEBUG_SET_LEVEL                 ; Set debug level
  DEBUG_LOG                       ; Debug / Log data
  BUFFER_CLEAR_RX_TX              ; Clear RX/TX buffers
  BUFFER_DROP_FROM_ESP            ; Drop messages from ESP buffer (TX)
  WIFI_GET_STATUS                 ; Get WiFi connection status
  ESP_RESTART                     ; Restart ESP

; RND CMDS
  RND_GET_BYTE                    ; Get random byte
  RND_GET_BYTE_RANGE              ; Get random byte between custom min/max
  RND_GET_WORD                    ; Get random word
  RND_GET_WORD_RANGE              ; Get random word between custom min/max

; SERVER CMDS
  SERVER_GET_STATUS               ; Get server connection status
  SERVER_PING                     ; Get ping between ESP and server
  SERVER_SET_PROTOCOL             ; Set protocol to be used to communicate (WS/UDP/TCP)
  SERVER_GET_SETTINGS             ; Get current server host name and port
  SERVER_GET_CONFIG_SETTINGS      ; Get server host name and port defined in the Rainbow config file
  SERVER_SET_SETTINGS             ; Set current server host name and port
  SERVER_RESTORE_SETTINGS         ; Restore server host name and port to values defined in the Rainbow config
  SERVER_CONNECT                  ; Connect to server
  SERVER_DISCONNECT               ; Disconnect from server
  SERVER_SEND_MESSAGE             ; Send message to server

; NETWORK CMDS
  NETWORK_SCAN                    ; Scan networks around and return count
  NETWORK_GET_SCANNED_DETAILS     ; Get scanned network details
  NETWORK_GET_REGISTERED          ; Get registered networks status
  NETWORK_GET_REGISTERED_DETAILS  ; Get registered network SSID
  NETWORK_REGISTER                ; Register network
  NETWORK_UNREGISTER              ; Unregister network

; FILE COMMANDS
  FILE_OPEN                       ; Open working file
  FILE_CLOSE                      ; Close working file
  FILE_EXISTS                     ; Check if file exists
  FILE_DELETE                     ; Delete a file
  FILE_SET_CUR                    ; Set working file cursor position a file
  FILE_READ                       ; Read working file (at specific position)
  FILE_WRITE                      ; Write working file (at specific position)
  FILE_APPEND                     ; Append data to working file
  FILE_COUNT                      ; Count files in a specific path
  FILE_GET_LIST                   ; Get list of existing files in a path
  FILE_GET_FREE_ID                ; Get an unexisting file ID in a specific path
  FILE_GET_INFO                   ; Get file info (size + crc32)
  FILE_DOWNLOAD                   ; Download a file
  FILE_FORMAT                     ; Format file system and save current config

.endenum

; commands from ESP
.enum FROM_ESP

; ESP CMDS
  READY                           ; ESP is ready
  DEBUG_LEVEL                     ; Returns debug configuration
  WIFI_STATUS                     ; Returns WiFi connection status

; RND CMDS
  RND_BYTE                        ; Returns random byte value
  RND_WORD                        ; Returns random word value

; SERVER CMDS
  SERVER_STATUS                   ; Returns server connection status
  SERVER_PING                     ; Returns min, max and average round-trip time and number of lost packets
  SERVER_SETTINGS                 ; Returns server settings (host name + port)
  MESSAGE_FROM_SERVER             ; Message from server

; NETWORK CMDS
  NETWORK_COUNT                   ; Returns number of networks found
  NETWORK_SCANNED_DETAILS         ; Returns details for a scanned network
  NETWORK_REGISTERED_DETAILS      ; Returns SSID for a registered network
  NETWORK_REGISTERED              ; Returns registered networks status

; FILE CMDS
  FILE_EXISTS                     ; Returns if file exists or not
  FILE_DELETE                     ; See FILE_DELETE_RES enum for details on returned value
  FILE_LIST                       ; Returns path file list (FILE_GET_LIST)
  FILE_DATA                       ; Returns file data (FILE_READ)
  FILE_COUNT                      ; Returns file count in a specific path
  FILE_ID                         ; Returns a free file ID (FILE_GET_FREE_ID)
  FILE_INFO                       ; Returns file info (size + CRC32) (FILE_GET_INFO)
  FILE_DOWNLOAD                   ; See FILE_DOWNLOAD_RES enum for details on returned value

.endenum

; WiFi status
.enum WIFI_STATUS
  NO_SHIELD = 255
  IDLE_STATUS = 0
  NO_SSID_AVAIL
  SCAN_COMPLETED
  CONNECTED
  CONNECT_FAILED
  CONNECTION_LOST
  DISCONNECTED
.endenum

; Server protocols
.enum SERVER_PROTOCOLS
  WS
  WS_S
  TCP
  TCP_S
  UDP
.endenum

; Server status
.enum SERVER_STATUS
  DISCONNECTED
  CONNECTED
.endenum

; File paths
.enum FILE_PATHS
  SAVE
  ROMS
  USER
.endenum

; File constants
NUM_PATHS = 3
NUM_FILES = 64

; Network encryption types
.enum NETWORK_ENCRYPTION_TYPES
  WEP = 5
  WPA_PSK = 2
  WPA2_PSK = 4
  OPEN_NETWORK = 7
  WPA_WPA2_PSK = 8
.endenum

; FILE_DELETE return values
.enum FILE_DELETE_RES
  SUCCESS
  ERROR_WHILE_DELETING_FILE
  FILE_NOT_FOUND
  INVALID_PATH_OR_FILE
.endenum

; FILE_DOWNLOAD return values
.enum FILE_DOWNLOAD_RES
  SUCCESS
  ERROR_WHILE_DELETING_FILE
  DOWNLOAD_FAILED
  INVALID_PATH_OR_FILE
.endenum

; Rainbow registers
RNBW_DATA = $5000
RNBW_FLAGS = $5001