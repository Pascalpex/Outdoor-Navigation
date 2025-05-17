#include "rtklib_wrapper.h" // Include your header file for the API
#include <stdio.h>          // For snprintf or other utilities if needed
#include <string.h>         // For memset or memcpy if needed

// Sample code to stop the RTK server
static rtksvr_t svr;

void stop_rtk_server(void)
{
    const char *stop_cmds[] = {NULL, NULL, NULL};
    rtksvrstop(&svr, stop_cmds);
}
