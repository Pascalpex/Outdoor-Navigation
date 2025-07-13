#include "rtklib_wrapper.h"
#include "rtklib.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <android/log.h>
#include <unistd.h>
#include <stdarg.h>

#define APPNAME "RTKLIB_WRAPPER"
#define LOG_TAG "RTKLIB_WRAPPER"

// --- Global server instance ---
static rtksvr_t svr;

// --- Helper Functions ---
static int androidToRtklibSys(int constellationType)
{
    switch (constellationType)
    {
    case 1:
        return SYS_GPS;
    case 3:
        return SYS_GAL;
    case 6:
        return SYS_GLO;
    default:
        return SYS_NONE;
    }
}

// --- Server Management Functions ---
void stop_rtk_server(void)
{
    __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "Attempting to stop server. Current svr.state: %d", svr.state);
    if (svr.state)
    {
        const char *stop_cmds[MAXSTRRTK] = {NULL};
        rtksvrstop(&svr, stop_cmds);
    }
}
int init_rtk_server(void)
{
    __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "Initializing RTK server struct...");
    if (!rtksvrinit(&svr))
    {
        __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, "RTK server initialization failed");
        return 0;
    }
    return 1;
}

int start_rtk_server(void)
{
    char *ntrip_correction_base = "";
    char *ntrip_ephemeris = "";
    double lat = 0.0;
    double lon = 0.0;
    double alt = 0.0;
    char errmsg[MAXERRMSG] = "";

    int strtype[MAXSTRRTK] = {0};
    strtype[0] = STR_MEMBUF;   // Rover
    strtype[1] = STR_NTRIPCLI; // Base
    strtype[2] = STR_NTRIPCLI; // Correction ephemeris

    const char *paths[MAXSTRRTK];
    char paths_data[MAXSTRRTK][MAXSTRPATH] = {0};

    snprintf(paths_data[1], MAXSTRPATH, "%s", ntrip_correction_base);
    snprintf(paths_data[2], MAXSTRPATH, "%s", ntrip_ephemeris);
    for (int i = 0; i < MAXSTRRTK; i++)
    {
        paths[i] = paths_data[i];
    }

    int strfmt[MAXSTRRTK] = {0};
    strfmt[0] = STRFMT_RTCM3;
    strfmt[1] = STRFMT_RTCM3;
    strfmt[2] = STRFMT_RTCM3;

    prcopt_t prcopt = prcopt_default;
    solopt_t solopt[2] = {solopt_default, solopt_default};

    // --- Configure prcopt ---
    prcopt.mode = PMODE_KINEMA;
    prcopt.navsys = SYS_GPS | SYS_GLO;
    prcopt.nf = 1;
    prcopt.modear = ARMODE_FIXHOLD;
    prcopt.glomodear = GLO_ARMODE_ON;
    prcopt.elmaskar = 15.0 * D2R;
    prcopt.sateph = EPHOPT_BRDC;
    prcopt.ionoopt = IONOOPT_BRDC;
    prcopt.tropopt = TROPOPT_SAAS;
    prcopt.posopt[0] = 0;
    prcopt.posopt[1] = 0;
    prcopt.posopt[2] = 0;
    prcopt.posopt[3] = 0;
    prcopt.posopt[4] = 0;
    prcopt.posopt[5] = 0;
    prcopt.thresar[1] = 1;
    prcopt.thresar[2] = 0.03;
    prcopt.thresar[3] = 1e-07;
    prcopt.thresar[4] = 0.001;
    prcopt.minfix = 10;
    prcopt.elmaskhold = 15 * D2R;
    prcopt.thresslip = 0.2;
    const int svrcycle = 5;
    const int nmeacycle = 5000;
    const int buffsize = 32768;
    const int navsel = 0;

    const char *cmds[MAXSTRRTK] = {"", "", "", "", "", "", "", ""};
    const char *cmds_periodic[MAXSTRRTK] = {"", "", "", "", "", "", "", ""};
    const char *ropts[MAXSTRRTK] = {"", "", "", "", "", "", "", ""};

    const int nmeareq = 1;
    double nmeapos_val[3] = {lat * D2R, lon * D2R, alt};
    double npos[3];
    pos2ecef(nmeapos_val, npos);
    pos2ecef(nmeapos_val, prcopt.ru);

    stream_t monitor_streams[16] = {{0}};

    if (!rtksvrstart(&svr, svrcycle, buffsize, strtype, paths, strfmt, navsel,
                     cmds, cmds_periodic, ropts, nmeacycle, nmeareq, npos, &prcopt, solopt,
                     monitor_streams, errmsg))
    {
        __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, "RTK server start error (%s)", errmsg);
        return 0;
    }
    __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "Correcting NAV data counters post-initialization.");

    __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "RTK server started successfully.");
    return 1;
}

int input_rover_observation(
    long long gpsTimeNanos,
    const int *svids, const int *constellationTypes, const double *cn0DbHzs,
    const double *carrierFrequenciesHz, const double *adrMeters,
    const int *adrStates, const double *pratesMps, const double *pseudoranges,
    int count)
{
    if (!svr.state || count <= 0)
        return 0;

    double total_seconds = (double)gpsTimeNanos * 1e-9;
    double ep_gps_start[] = {1980, 1, 6, 0, 0, 0};
    gtime_t time_gps_start = epoch2time(ep_gps_start);
    gtime_t obs_time = timeadd(time_gps_start, total_seconds);

    obs_t rover_obs = {0};
    rover_obs.data = (obsd_t *)calloc(count, sizeof(obsd_t));
    if (!rover_obs.data)
        return 0;

    for (int i = 0; i < count; ++i)
    {
        int sys = androidToRtklibSys(constellationTypes[i]);
        if (sys == SYS_NONE)
            continue;

        int sat = satno(sys, svids[i]);
        if (sat == 0)
            continue;

        int freq_idx = -1;
        uint8_t signal_code = CODE_NONE;

        if (fabs(carrierFrequenciesHz[i] - FREQL1) < 1e6)
        {
            freq_idx = 0;
            signal_code = CODE_L1C;
        }

        if (freq_idx < 0)
            continue;

        int k;
        for (k = 0; k < rover_obs.n; k++)
        {
            if (rover_obs.data[k].sat == sat)
                break;
        }

        if (k == rover_obs.n)
        {
            if (rover_obs.n >= count)
                continue;
            rover_obs.data[k].time = obs_time;
            rover_obs.data[k].sat = sat;
            rover_obs.data[k].rcv = 1;
            rover_obs.n++;
        }

        double lam = CLIGHT / carrierFrequenciesHz[i];
        if (lam == 0.0)
            continue;

        rover_obs.data[k].P[freq_idx] = pseudoranges[i];
        rover_obs.data[k].L[freq_idx] = adrMeters[i] / lam;
        rover_obs.data[k].D[freq_idx] = (float)(-pratesMps[i] / lam);
        rover_obs.data[k].SNR[freq_idx] = (uint16_t)(cn0DbHzs[i] * 4.0 + 0.5);
        rover_obs.data[k].code[freq_idx] = signal_code;

        if (adrStates[i] & 4)
        {
            rover_obs.data[k].LLI[freq_idx] |= LLI_SLIP;
        }
    }

    if (rover_obs.n == 0)
    {
        free(rover_obs.data);
        return 0;
    }

    rtcm_t rtcm_gen = {0};
    init_rtcm(&rtcm_gen);
    rtcm_gen.time = obs_time;
    rtcm_gen.staid = 1;
    rtcm_gen.obs = rover_obs;

    int total_bytes = 0;
    if (gen_rtcm3(&rtcm_gen, 1077, 0, 0) > 0)
        total_bytes += strwrite(&svr.stream[0], rtcm_gen.buff, rtcm_gen.nbyte);
    if (gen_rtcm3(&rtcm_gen, 1087, 0, 0) > 0)
        total_bytes += strwrite(&svr.stream[0], rtcm_gen.buff, rtcm_gen.nbyte);
    if (gen_rtcm3(&rtcm_gen, 1097, 0, 0) > 0)
        total_bytes += strwrite(&svr.stream[0], rtcm_gen.buff, rtcm_gen.nbyte);

    rtcm_gen.obs.data = NULL;
    free_rtcm(&rtcm_gen);
    free(rover_obs.data);

    if (total_bytes > 0)
    {
        __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "Wrote %d total RTCM bytes for rover.", total_bytes);
    }
    return total_bytes > 0;
}

int get_rtk_solution(char *buffer, int buffer_size)
{
    if (!buffer || buffer_size <= 0)
    {
        return 0;
    }

    rtksvrlock(&svr);

    if (!svr.state || svr.rtk.sol.stat == SOLQ_NONE)
    {
        rtksvrunlock(&svr);
        buffer[0] = '\0';
        return 0;
    }

    sol_t *sol = &svr.rtk.sol;
    char time_str_sol[64];
    time2str(sol->time, time_str_sol, 3);

    int len = snprintf(buffer, buffer_size,
                       "{\"time\":\"%s\", \"status\":%d, \"num_sats\":%d, \"ratio\":%.2f, "
                       "\"latitude\":%.9f, \"longitude\":%.9f, \"height\":%.4f, "
                       "\"age\":%.2f}",
                       time_str_sol, sol->stat, sol->ns, sol->ratio,
                       sol->rr[0] * R2D, sol->rr[1] * R2D, sol->rr[2],
                       sol->age);

    rtksvrunlock(&svr);

    if (len < 0 || len >= buffer_size)
    {
        __android_log_print(ANDROID_LOG_WARN, LOG_TAG, "Solution buffer too small. Needed: %d, Have: %d", len, buffer_size);
        buffer[0] = '\0';
        return -1;
    }

    return len;
}

void print_rtk_server_status_debug(void)
{
    rtksvrlock(&svr);
    if (!svr.state)
    {
        __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "Server not active.");
        rtksvrunlock(&svr);
        return;
    }
    __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "Server active (state = %d)", svr.state);
    __android_log_print(ANDROID_LOG_INFO, LOG_TAG,
                        "NTRIP Stream (Base): state=%d, in_bytes=%lu, out_bytes=%lu, msg='%s'",
                        svr.stream[1].state, (unsigned long)svr.stream[1].inb, (unsigned long)svr.stream[1].outb, svr.stream[1].msg);
    char time_str_sol[64];
    time2str(svr.rtk.sol.time, time_str_sol, 3);
    __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "Solution: time=%s, status=%d, #sats=%d, ratio=%.1f",
                        time_str_sol, svr.rtk.sol.stat, svr.rtk.sol.ns, svr.rtk.sol.ratio);
    if (svr.rtk.sol.stat > 0)
    {
        __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "Solution Pos (LLH): %.8f, %.8f, %.3f",
                            svr.rtk.sol.rr[0] * R2D, svr.rtk.sol.rr[1] * R2D, svr.rtk.sol.rr[2]);
    }
    __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "Rover Obs Buffer: n=%d", svr.obs[0][0].n);
    __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "Base Obs Buffer: n=%d", svr.obs[1][0].n);
    int common_sats = 0;
    obs_t *rover_obs = &svr.obs[0][0];
    obs_t *base_obs = &svr.obs[1][0];

    if (rover_obs->n > 0 && base_obs->n > 0)
    {
        for (int i = 0; i < rover_obs->n; i++)
        {
            for (int j = 0; j < base_obs->n; j++)
            {
                if (rover_obs->data[i].sat == base_obs->data[j].sat)
                {
                    common_sats++;
                    break;
                }
            }
        }
    }
    __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "Common Satellites (Rover/Base): %d", common_sats);
    __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "Nav Data: n=%d, ng=%d, ns=%d, nc=%d, ne=%d",
                        svr.nav.n, svr.nav.ng, svr.nav.ns, svr.nav.nc, svr.nav.ne);
    rtksvrunlock(&svr);
}
