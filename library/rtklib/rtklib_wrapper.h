// rtklib_wrapper.h
#ifndef RTKLIB_WRAPPER_H
#define RTKLIB_WRAPPER_H

#include "rtklib.h"

#ifdef __cplusplus
extern "C"
{
#endif

    // NTRIP client functions
    int ntrip_init();
    int ntrip_connect(const char *url, const char *user, const char *passwd);
    int ntrip_disconnect(int stream);
    int ntrip_read(int stream, unsigned char *buff, int n);
    int ntrip_get_error(char *buff, int n);

    // RTK calculation related functions
    void *rtk_create();
    void rtk_destroy(void *rtk_ptr);
    int rtk_init_options(void *rtk_ptr, int mode, int soltype);
    int rtk_input_obs(void *rtk_ptr, const unsigned char *data, int length, int format);
    int rtk_input_nav(void *rtk_ptr, const unsigned char *data, int length, int format);
    int rtk_update(void *rtk_ptr);
    int rtk_get_solution(void *rtk_ptr, double *pos, float *qr, int *stat);

#ifdef __cplusplus
}
#endif

#endif /* RTKLIB_WRAPPER_H */