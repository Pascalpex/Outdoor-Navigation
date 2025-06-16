#ifndef MY_RTKLIB_API_H
#define MY_RTKLIB_API_H

#include "rtklib.h" // Provides core RTKLIB data structures and function declarations.

#define NTRIP_DATA_PEEK_SIZE 128

typedef struct
{
    int32_t stream_state; // Use fixed-width for clarity with Dart's Int32
    char stream_msg[MAXSTRMSG];
    int32_t bytes_in_server_buffer;
    int32_t bytes_peeked;
    uint8_t data_peek_buffer[NTRIP_DATA_PEEK_SIZE];
    int32_t rtk_server_state;
} RtkNtripDebugInfo;

#ifdef __cplusplus
extern "C"
{
#endif

    /**
     * stops the RTK server
     */
    void stop_rtk_server(void);

    void get_rtk_ntrip_debug_info(RtkNtripDebugInfo *debug_info);

#ifdef __cplusplus
}
#endif

#endif // MY_RTKLIB_API_H
