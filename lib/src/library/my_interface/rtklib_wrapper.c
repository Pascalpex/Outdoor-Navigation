#include "rtklib_wrapper.h" // Include your header file for the API
#include <stdio.h>          // For snprintf or other utilities if needed
#include <string.h>         // For memset or memcpy if needed
#include <android/log.h>

#define APPNAME "RTKLIB_WRAPPER"

static rtksvr_t svr;

void stop_rtk_server(void)
{
    __android_log_print(ANDROID_LOG_INFO, "GNSS", "Attempting to stop server. Current svr.state: %d", svr.state);
    if (svr.state)
    {
        const char *stop_cmds[MAXSTRRTK];
        for (int i = 0; i < MAXSTRRTK; ++i)
        {
            stop_cmds[i] = NULL;
        }

        rtksvrstop(&svr, stop_cmds);
    }
}

int init_rtk_server(void)
{
    __android_log_print(ANDROID_LOG_ERROR, "MyTestTag", "THIS IS AN ERROR LEVEL TEST LOG");
    if (!rtksvrinit(&svr))
    {
        fprintf(stderr, "RTK server initialization failed\n");
        return 0;
    }

    return 1;
}

int start_rtk_server(void)
{

    __android_log_print(ANDROID_LOG_ERROR, "MyTestTag", "START: Entered start_rtk_server. Current svr.state: %d", svr.state);
    int stream_types[MAXSTRRTK];
    for (int i = 0; i < MAXSTRRTK; ++i)
        stream_types[i] = STR_NONE;
    stream_types[0] = STR_MEMBUF;

    char paths_data[MAXSTRRTK][MAXSTRPATH];
    for (int i = 0; i < MAXSTRRTK; ++i)
    {
        paths_data[i][0] = '\0';
    }

    const char *paths[MAXSTRRTK];
    for (int i = 0; i < MAXSTRRTK; ++i)
    {
        paths[i] = paths_data[i];
    }

    int input_formats[3];
    input_formats[0] = STRFMT_RINEX;
    input_formats[1] = STRFMT_RTCM3;
    input_formats[2] = STRFMT_RTCM3;

    const char *start_commands[MAXSTRRTK];
    const char *periodic_commands[MAXSTRRTK];
    const char *receiver_options[MAXSTRRTK];

    for (int i = 0; i < MAXSTRRTK; ++i)
    {
        start_commands[i] = "";
        periodic_commands[i] = "";
        receiver_options[i] = "";
    }

    prcopt_t prcopt = prcopt_default;
    solopt_t solopt[2] = {solopt_default, solopt_default};

    resetsysopts();
    getsysopts(&prcopt, solopt, NULL);

    prcopt.mode = PMODE_SINGLE;
    prcopt.maxinno[0] = 30;
    prcopt.maxinno[1] = 30;
    prcopt.navsys = SYS_GPS | SYS_GLO | SYS_GAL;
    prcopt.thresar[0] = 3;
    prcopt.thresar[5] = 1.5;
    prcopt.thresar[6] = 10;
    prcopt.nf = 2;
    prcopt.rovpos = POSOPT_POS_LLH;

    prcopt.modear = ARMODE_FIXHOLD;
    prcopt.glomodear = GLO_ARMODE_ON;
    prcopt.dynamics = 1;
    prcopt.tidecorr = 0;
    prcopt.ionoopt = IONOOPT_BRDC;
    prcopt.tropopt = TROPOPT_SAAS;
    prcopt.sateph = EPHOPT_BRDC;
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
    prcopt.elmaskar = 15.0 * PI / 180.0;
    prcopt.elmaskhold = 15.0 * PI / 180.0;
    prcopt.thresslip = 0.2;

    __android_log_print(ANDROID_LOG_DEBUG, "MyTestTag", "START: stream_types[0]=%d, paths[0]='%s', input_formats[0]=%d",
                        stream_types[0], paths[0] ? paths[0] : "NULL", input_formats[0]);
    __android_log_print(ANDROID_LOG_DEBUG, "MyTestTag", "START: start_commands[0]='%s'",
                        start_commands[0] ? start_commands[0] : "NULL");
    __android_log_print(ANDROID_LOG_DEBUG, "MyTestTag", "START: prcopt.mode=%d, prcopt.navsys=0x%X",
                        prcopt.mode, prcopt.navsys);

    char error_message[1024] = {0};
    __android_log_print(ANDROID_LOG_ERROR, "MyTestTag", "START: About to call rtksvrstart().");

    int navsel = 0;
    int nmeacycle = 0;
    int nmeareq = 0;
    double nmeapos_val[3] = {0.0, 0.0, 0.0};

    int result = rtksvrstart(&svr, 100, 32768, stream_types, paths, input_formats,
                             navsel, start_commands, periodic_commands, receiver_options,
                             nmeacycle, nmeareq, nmeapos_val, &prcopt, solopt, NULL, error_message);
    if (!result)
    {
        __android_log_print(ANDROID_LOG_ERROR, "MyTestTag", "START: rtksvrstart() FAILED. Error: %s. svr.state: %d",
                            error_message, svr.state);

        return 0;
    }

    __android_log_print(ANDROID_LOG_ERROR, "MyTestTag", "START: rtksvrstart() SUCCEEDED. svr.state: %d", svr.state);

    return 1;
}
