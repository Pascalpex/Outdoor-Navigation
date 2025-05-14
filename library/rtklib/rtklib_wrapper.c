// rtklib_wrapper.c
#include "rtklib_wrapper.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Global variables to maintain state
static stream_t stream_ntrip = {0};
static char errmsg[1024] = "";
static int initialized = 0;

// Initialize RTKLIB
int ntrip_init()
{
    if (!initialized)
    {
        strinitcom();
        initialized = 1;
    }
    return initialized;
}

// Connect to NTRIP caster
int ntrip_connect(const char *url, const char *user, const char *passwd)
{
    // Make sure we're initialized
    if (!initialized)
        ntrip_init();

    int ret;
    char path[1024];

    // Parse URL into components
    if (!url)
    {
        sprintf(errmsg, "Invalid URL");
        return 0;
    }

    // Format: ntrip://user:pass@host:port/mountpoint
    // We'll assume the URL is properly formatted for simplicity
    sprintf(path, "%s", url);

    // Open stream connection
    ret = stropen(&stream_ntrip, STR_NTRIPCLI, STR_MODE_R, path);
    if (!ret)
    {
        sprintf(errmsg, "Failed to connect to NTRIP caster");
        return 0;
    }

    // If authentication information provided separately
    if (user && passwd && *user)
    {
        strcpy(stream_ntrip.user, user);
        strcpy(stream_ntrip.passwd, passwd);
    }

    return 1;
}

// Disconnect from NTRIP caster
int ntrip_disconnect(int stream)
{
    strclose(&stream_ntrip);
    return 1;
}

// Read data from NTRIP stream
int ntrip_read(int stream, unsigned char *buff, int n)
{
    if (!buff || n <= 0)
    {
        sprintf(errmsg, "Invalid buffer or size");
        return -1;
    }

    return strread(&stream_ntrip, buff, n);
}

// Get last error message
int ntrip_get_error(char *buff, int n)
{
    if (!buff || n <= 0)
        return 0;
    strncpy(buff, errmsg, n - 1);
    buff[n - 1] = '\0';
    return strlen(buff);
}

// RTK processing related functions
void *rtk_create()
{
    rtk_t *rtk = (rtk_t *)malloc(sizeof(rtk_t));
    if (rtk)
    {
        rtkinit(rtk, &prcopt_default);
    }
    return rtk;
}

void rtk_destroy(void *rtk_ptr)
{
    if (rtk_ptr)
    {
        rtk_t *rtk = (rtk_t *)rtk_ptr;
        rtkfree(rtk);
        free(rtk);
    }
}

int rtk_init_options(void *rtk_ptr, int mode, int soltype)
{
    if (!rtk_ptr)
        return 0;

    rtk_t *rtk = (rtk_t *)rtk_ptr;
    prcopt_t opt = prcopt_default;

    // Set positioning mode
    opt.mode = mode;       // 0:single, 1:DGPS, 2:kinematic, 3:static, etc.
    opt.soltype = soltype; // 0:forward, 1:backward, 2:combined

    rtkinit(rtk, &opt);
    return 1;
}

int rtk_input_obs(void *rtk_ptr, const unsigned char *data, int length, int format)
{
    if (!rtk_ptr || !data || length <= 0)
        return 0;

    rtk_t *rtk = (rtk_t *)rtk_ptr;
    obs_t obs = {0};
    nav_t nav = {0};
    sta_t sta = {0};
    int stat = 0;

    // Format: 1=RTCM2, 2=RTCM3
    if (format == 1)
    {
        stat = input_rtcm2(data, length, &obs, &nav, &sta);
    }
    else if (format == 2)
    {
        stat = input_rtcm3(data, length, &obs, &nav, &sta);
    }

    if (stat > 0 && obs.n > 0)
    {
        // Process observations
        rtkpos(rtk, obs.data, obs.n, &nav);
    }

    return stat;
}

int rtk_input_nav(void *rtk_ptr, const unsigned char *data, int length, int format)
{
    if (!rtk_ptr || !data || length <= 0)
        return 0;

    obs_t obs = {0};
    nav_t nav = {0};
    sta_t sta = {0};
    int stat = 0;

    // Format: 1=RTCM2, 2=RTCM3
    if (format == 1)
    {
        stat = input_rtcm2(data, length, &obs, &nav, &sta);
    }
    else if (format == 2)
    {
        stat = input_rtcm3(data, length, &obs, &nav, &sta);
    }

    if (stat > 0 && nav.n > 0 || nav.ng > 0 || nav.ns > 0)
    {
        // Copy nav data to RTK
        rtk_t *rtk = (rtk_t *)rtk_ptr;
        rtk->nav = nav;
    }

    return stat;
}

int rtk_update(void *rtk_ptr)
{
    if (!rtk_ptr)
        return 0;

    // This is a placeholder - in a real implementation,
    // you might trigger RTK processing or update state
    return 1;
}

int rtk_get_solution(void *rtk_ptr, double *pos, float *qr, int *stat)
{
    if (!rtk_ptr || !pos || !stat)
        return 0;

    rtk_t *rtk = (rtk_t *)rtk_ptr;

    // Copy solution data
    for (int i = 0; i < 3; i++)
    {
        pos[i] = rtk->sol.rr[i];
    }

    if (qr)
    {
        for (int i = 0; i < 6; i++)
        {
            qr[i] = (float)rtk->sol.qr[i];
        }
    }

    *stat = rtk->sol.stat;
    return 1;
}