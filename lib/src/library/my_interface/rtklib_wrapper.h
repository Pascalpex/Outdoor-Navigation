#ifndef MY_RTKLIB_API_H
#define MY_RTKLIB_API_H

#include "rtklib.h" // Provides core RTKLIB data structures and function declarations.

#ifdef __cplusplus
extern "C"
{
#endif

    /**
     * stops the RTK server
     */
    void stop_rtk_server(void);

#ifdef __cplusplus
}
#endif

#endif // MY_RTKLIB_API_H
