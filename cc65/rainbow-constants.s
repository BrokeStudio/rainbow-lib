; ################################################################################
; RAINBOW CONSTANTS

NUM_PATHS     = 3
NUM_FILES     = 64

; NES to ESP opcodes
.enum N2E

; ESP CMDS
  GET_ESP_STATUS
  DEBUG_LOG
  CLEAR_BUFFERS
  E2N_BUFFER_DROP
  GET_WIFI_STATUS
  GET_RND_BYTE
  GET_RND_BYTE_RANGE ; min / max
  GET_RND_WORD
  GET_RND_WORD_RANGE ; min / max

; SERVER CMDS
  GET_SERVER_STATUS
  GET_SERVER_PING
  SET_SERVER_PROTOCOL
  GET_SERVER_SETTINGS
  SET_SERVER_SETTINGS
  CONNECT_SERVER
  DISCONNECT_SERVER
  SEND_MSG_TO_SERVER

; FILE COMMANDS
  FILE_OPEN
  FILE_CLOSE
  FILE_EXISTS
  FILE_DELETE
  FILE_SET_CUR
  FILE_READ
  FILE_WRITE
  FILE_APPEND
  FILE_COUNT
  FILE_GET_LIST
  FILE_GET_FREE_ID
  FILE_GET_INFO

.endenum

; ESP to NES opcodes
.enum E2N
  READY

  FILE_EXISTS
  FILE_DELETE
  FILE_LIST
  FILE_DATA
  FILE_COUNT
  FILE_ID
  FILE_INFO

  WIFI_STATUS
  SERVER_STATUS
  SERVER_PING
  HOST_SETTINGS

  RND_BYTE
  RND_WORD
  
  MESSAGE_FROM_SERVER
.endenum

; WiFi status
.enum WIFI_STATUS
  NO_SHIELD       = 255
  IDLE_STATUS     = 0
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
