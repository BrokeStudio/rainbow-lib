; ################################################################################
; RAINBOW CONSTANTS

; commands to ESP

; ESP CMDS
TOESP_GET_ESP_STATUS                  = 0   ; Get ESP status
TOESP_DEBUG_GET_LEVEL                 = 1   ; Get debug level
TOESP_DEBUG_SET_LEVEL                 = 2   ; Set debug level
TOESP_DEBUG_LOG                       = 3   ; Debug / Log data
TOESP_CLEAR_BUFFERS                   = 4   ; Clear RX/TX buffers
TOESP_FROMESP_BUFFER_DROP_FROM_ESP    = 5   ; Drop messages from ESP buffer (TX)
TOESP_GET_WIFI_STATUS                 = 6   ; Get WiFi connection status
TOESP_ESP_RESTART                     = 7   ; Restart ESP

; RND CMDS
TOESP_RND_GET_BYTE                    = 8   ; Get random byte
TOESP_RND_GET_BYTE_RANGE              = 9   ; Get random byte between custom min/max
TOESP_RND_GET_WORD                    = 10  ; Get random word
TOESP_RND_GET_WORD_RANGE              = 11  ; Get random word between custom min/max

; SERVER CMDS
TOESP_SERVER_GET_STATUS               = 12  ; Get server connection status
TOESP_SERVER_PING                     = 13  ; Get ping between ESP and server
TOESP_SERVER_SET_PROTOCOL             = 14  ; Set protocol to be used to communicate (WS/UDP/TCP)
TOESP_SERVER_GET_SETTINGS             = 15  ; Get current server host name and port
TOESP_SERVER_GET_CONFIG_SETTINGS      = 16  ; Get server host name and port defined in the Rainbow config file
TOESP_SERVER_SET_SETTINGS             = 17  ; Set current server host name and port
TOESP_SERVER_RESTORE_SETTINGS         = 18  ; Restore server host name and port to values defined in the Rainbow config
TOESP_SERVER_CONNECT                  = 19  ; Connect to server
TOESP_SERVER_DISCONNECT               = 20  ; Disconnect from server
TOESP_SERVER_SEND_MSG                 = 21  ; Send message to rainbow server

; NETWORK CMDS
TOESP_NETWORK_SCAN                    = 22  ; Scan networks around and return count
TOESP_NETWORK_GET_SCANNED_DETAILS     = 23  ; Get scanned network details
TOESP_NETWORK_GET_REGISTERED          = 24  ; Get registered networks status
TOESP_NETWORK_GET_REGISTERED_DETAILS  = 25  ; Get registered network SSID
TOESP_NETWORK_REGISTER                = 26  ; Register network
TOESP_NETWORK_UNREGISTER              = 27  ; Unregister network

; FILE COMMANDS
TOESP_FILE_OPEN                       = 28  ; Open working file
TOESP_FILE_CLOSE                      = 29  ; Close working file
TOESP_FILE_STATUS                     = 30  ; Get working file status
TOESP_FILE_EXISTS                     = 31  ; Check if file exists
TOESP_FILE_DELETE                     = 32  ; Delete a file
TOESP_FILE_SET_CUR                    = 33  ; Set working file cursor position a file
TOESP_FILE_READ                       = 34  ; Read working file (at specific position)
TOESP_FILE_WRITE                      = 35  ; Write working file (at specific position)
TOESP_FILE_APPEND                     = 36  ; Append data to working file
TOESP_FILE_COUNT                      = 37  ; Count files in a specific path
TOESP_FILE_GET_LIST                   = 38  ; Get list of existing files in a path
TOESP_FILE_GET_FREE_ID                = 39  ; Get an unexisting file ID in a specific path
TOESP_FILE_GET_INFO                   = 40  ; Get file info (size + crc32)
TOESP_FILE_DOWNLOAD                   = 41  ; Download a file
TOESP_FILE_FORMAT                     = 42  ; Format file system and save current config

; commands from ESP

; ESP CMDS
FROMESP_READY                         = 0   ; ESP is ready
FROMESP_DEBUG_LEVEL                   = 1   ; Returns debug configuration
FROMESP_WIFI_STATUS                   = 2   ; Returns WiFi connection status

; RND CMDS
FROMESP_RND_BYTE                      = 3   ; Returns random byte value
FROMESP_RND_WORD                      = 4   ; Returns random word value

; SERVER CMDS
FROMESP_SERVER_STATUS                 = 5   ; Returns server connection status
FROMESP_SERVER_PING                   = 6   ; Returns min, max and average round-trip time and number of lost packets
FROMESP_SERVER_SETTINGS               = 7   ; Returns server settings (host name + port)
FROMESP_MESSAGE_FROM_SERVER           = 8   ; Message from server

; NETWORK CMDS
FROMESP_NETWORK_COUNT                 = 9   ; Returns number of networks found
FROMESP_NETWORK_SCANNED_DETAILS       = 10  ; Returns details for a scanned network
FROMESP_NETWORK_REGISTERED_DETAILS    = 11  ; Returns SSID for a registered network
FROMESP_NETWORK_REGISTERED            = 12  ; Returns registered networks status

; FILE CMDS
FROMESP_FILE_STATUS                   = 13  ; Returns working file status
FROMESP_FILE_EXISTS                   = 14  ; Returns if file exists or not
FROMESP_FILE_DELETE                   = 15  ; See RNBW_FILE_DELETE_xxx constants for details on returned value
FROMESP_FILE_LIST                     = 16  ; Returns path file list (FILE_GET_LIST)
FROMESP_FILE_DATA                     = 17  ; Returns file data (FILE_READ)
FROMESP_FILE_COUNT                    = 18  ; Returns file count in a specific path
FROMESP_FILE_ID                       = 19  ; Returns a free file ID (FILE_GET_FREE_ID)
FROMESP_FILE_INFO                     = 20  ; Returns file info (size + CRC32) (FILE_GET_INFO)
FROMESP_FILE_DOWNLOAD                 = 21  ; See RNBW_FILE_DOWNLOAD_xxx constants for details on returned value

; WiFi status
RNBW_WIFI_NO_SHIELD = 255
RNBW_WIFI_IDLE_STATUS = 0
RNBW_WIFI_NO_SSID_AVAIL = 1
RNBW_WIFI_SCAN_COMPLETED = 2
RNBW_WIFI_CONNECTED = 3
RNBW_WIFI_CONNECT_FAILED = 4
RNBW_WIFI_CONNECTION_LOST = 5
RNBW_WIFI_DISCONNECTED = 6

; Server protocols
RNBW_PROTOCOL_WEBSOCKET = 0
RNBW_PROTOCOL_WEBSOCKET_SECURED = 1
RNBW_PROTOCOL_TCP = 2
RNBW_PROTOCOL_TCP_SECURED = 3
RNBW_PROTOCOL_UDP = 4

; Server status
RNBW_SERVER_DISCONNECTED = 0
RNBW_SERVER_CONNECTED = 1

; File paths
RNBW_FILE_PATH_SAVE = 0
RNBW_FILE_PATH_ROMS = 1
RNBW_FILE_PATH_USER = 2

; File constants
RNBW_NUM_PATHS = 3
RNBW_NUM_FILES = 64

; Network encryption types
RNBW_NETWORK_ENCTYPE_WEP = 5
RNBW_NETWORK_ENCTYPE_WPA_PSK = 2
RNBW_NETWORK_ENCTYPE_WPA2_PSK = 4
RNBW_NETWORK_ENCTYPE_OPEN_NETWORK = 7
RNBW_NETWORK_ENCTYPE_WPA_WPA2_PSK = 8

; File config masks/flags
RNBW_FILE_CONFIG_FLAGS_ACCESS_MODE_MASK = %00000001
RNBW_FILE_CONFIG_FLAGS_AUTO_ACCESS_MODE = 0
RNBW_FILE_CONFIG_FLAGS_MANUAL_ACCESS_MODE = 1

; FILE_DELETE result codes
RNBW_FILE_DELETE_SUCCESS = 0
RNBW_FILE_DELETE_ERROR_WHILE_DELETING_FILE = 1
RNBW_FILE_DELETE_FILE_NOT_FOUND = 2
RNBW_FILE_DELETE_INVALID_PATH_OR_FILE = 3

; FILE_DOWNLOAD result codes
RNBW_FILE_DOWNLOAD_SUCCESS = 0
RNBW_FILE_DOWNLOAD_INVALID_DESTINATION = 1
RNBW_FILE_DOWNLOAD_ERROR_WHILE_DELETING_FILE = 2
RNBW_FILE_DOWNLOAD_UNKNOWN_OR_UNSUPPORTED_PROTOCOL = 3
RNBW_FILE_DOWNLOAD_NETWORK_ERROR = 4
RNBW_FILE_DOWNLOAD_HTTP_STATUS_NOT_IN_2XX = 5

; FILE_DOWNLOAD network error codes
RNBW_FILE_DOWNLOAD_NETWORK_ERR_CONNECTION_FAILED = -1
RNBW_FILE_DOWNLOAD_NETWORK_ERR_SEND_HEADER_FAILED = -2
RNBW_FILE_DOWNLOAD_NETWORK_ERR_SEND_PAYLOAD_FAILED = -3
RNBW_FILE_DOWNLOAD_NETWORK_ERR_NOT_CONNECTED = -4
RNBW_FILE_DOWNLOAD_NETWORK_ERR_CONNECTION_LOST = -5
RNBW_FILE_DOWNLOAD_NETWORK_ERR_NO_STREAM = -6
RNBW_FILE_DOWNLOAD_NETWORK_ERR_NO_HTTP_SERVER = -7
RNBW_FILE_DOWNLOAD_NETWORK_ERR_TOO_LESS_RAM = -8
RNBW_FILE_DOWNLOAD_NETWORK_ERR_ENCODING = -9
RNBW_FILE_DOWNLOAD_NETWORK_ERR_STREAM_WRITE = -10
RNBW_FILE_DOWNLOAD_NETWORK_ERR_READ_TIMEOUT = -11

; Rainbow registers
RNBW_DATA = $5000
RNBW_FLAGS = $5001