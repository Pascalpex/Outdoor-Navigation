#include "rtklib_wrapper.h" // Include your header file for the API
#include <stdio.h>          // For snprintf or other utilities if needed
#include <string.h>         // For memset or memcpy if needed
#include <android/log.h>
#include <unistd.h> // For usleep

#define APPNAME "RTKLIB_WRAPPER"

static rtksvr_t svr;

void get_rtk_ntrip_debug_info(RtkNtripDebugInfo *debug_info)
{
    if (!debug_info)
    {
        return;
    }

    // Initialize the struct
    memset(debug_info, 0, sizeof(RtkNtripDebugInfo));
    debug_info->stream_state = -99; // Default to an unlikely state

    // Indices for your NTRIP stream
    int ntrip_stream_object_idx = 1; // Corresponds to stream_types[1] in your setup
    int rtksvr_input_buffer_idx = 1; // Corresponds to svr.buff[1], svr.nb[1]

    rtksvrlock(&svr); // LOCK RTK server structure

    debug_info->rtk_server_state = svr.state;
    debug_info->stream_state = svr.stream[ntrip_stream_object_idx].state;
    strncpy(debug_info->stream_msg, svr.stream[ntrip_stream_object_idx].msg, MAXSTRMSG - 1);
    debug_info->stream_msg[MAXSTRMSG - 1] = '\0'; // Ensure null termination

    debug_info->bytes_in_server_buffer = svr.nb[rtksvr_input_buffer_idx];

    if (svr.nb[rtksvr_input_buffer_idx] > 0)
    {
        int bytes_to_copy = svr.nb[rtksvr_input_buffer_idx];
        if (bytes_to_copy > NTRIP_DATA_PEEK_SIZE)
        {
            bytes_to_copy = NTRIP_DATA_PEEK_SIZE;
        }
        memcpy(debug_info->data_peek_buffer, svr.buff[rtksvr_input_buffer_idx], bytes_to_copy);
        debug_info->bytes_peeked = bytes_to_copy;
    }
    else
    {
        debug_info->bytes_peeked = 0;
    }

    rtksvrunlock(&svr); // UNLOCK RTK server structure
}

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
    stream_types[1] = STR_NTRIPCLI;
    // stream_types[2] = STR_NTRIPCLI;

    char paths_data[MAXSTRRTK][MAXSTRPATH];
    const char *paths[MAXSTRRTK];
    for (int i = 0; i < MAXSTRRTK; ++i)
    {
        paths_data[i][0] = '\0';
        paths[i] = paths_data[i];
    }

    snprintf(paths_data[1], MAXSTRPATH, "username:password@www.sapos-bw-ntrip.de:2101/VRS_3_2G_BW");
    __android_log_print(ANDROID_LOG_INFO, "MyTestTag", "NTRIP Path used: %s", paths[1]);

    int input_formats[3];
    input_formats[0] = STRFMT_RINEX;
    input_formats[1] = STRFMT_RTCM3;
    // input_formats[2] = STRFMT_RTCM3;

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

    prcopt.mode = PMODE_KINEMA;
    prcopt.maxinno[0] = 30;
    prcopt.maxinno[1] = 30;
    prcopt.navsys = SYS_GPS | SYS_GLO | SYS_GAL;
    prcopt.thresar[0] = 3;
    prcopt.thresar[5] = 1.5;
    prcopt.thresar[6] = 10;
    prcopt.nf = 2;
    prcopt.rovpos = POSOPT_POS_XYZ;

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
    int nmeacycle = 5000;                                           // 5 seconds in milliseconds
    int nmeareq = 1;                                                // only use the starting position for NMEA output
    double nmeapos_val[3] = {49.06806 * D2R, 9.14258 * D2R, 193.0}; // Example position in meters for NMEA pos ///TODO: Replace with actual position
    double lla_pos[3] = {
        49.14249870198528 * D2R, // Latitude in RADIANS
        9.207847822934626 * D2R, // Longitude in RADIANS
        200.0                    // Ellipsoidal Height in METERS ???
    };
    double ecef_pos[3]; // To store ECEF coordinates
    pos2ecef(lla_pos, ecef_pos);
    ,

        __android_log_print(ANDROID_LOG_INFO, "MyTestTag",
                            "NMEA for Caster (LLH input): cycle=%dms, req_type=%d, lla_in=(%.6f, %.6f, %.1f deg/m)",
                            nmeacycle, nmeareq, lla_pos[0] * R2D, lla_pos[1] * R2D, lla_pos[2]);
    __android_log_print(ANDROID_LOG_INFO, "MyTestTag",
                        "NMEA for Caster (ECEF sent to rtksvrstart): ecef_out=(%.3f, %.3f, %.3f m)",
                        ecef_pos[0], ecef_pos[1], ecef_pos[2]);

    __android_log_print(ANDROID_LOG_INFO, "MyTestTag", "NMEA for Caster: cycle=%dms, req_type=%d, pos=lla(%.6f, %.6f, %.1f deg/m)",
                        nmeacycle, nmeareq, nmeapos_val[0] * R2D, nmeapos_val[1] * R2D, nmeapos_val[2]);
    if (nmeareq == 0)
    {
        __android_log_print(ANDROID_LOG_WARN, "MyTestTag", "NMEA GGA to caster is DISABLED (nmeareq=0). VRS may not work!");
    }
    int result = rtksvrstart(&svr, 100, 32768, stream_types, paths, input_formats,
                             navsel, start_commands, periodic_commands, receiver_options,
                             nmeacycle, nmeareq, ecef_pos, &prcopt, solopt, NULL, error_message);
    if (!result)
    {
        __android_log_print(ANDROID_LOG_ERROR, "MyTestTag", "START: rtksvrstart() FAILED. Error: %s. svr.state: %d",
                            error_message, svr.state);

        return 0;
    }
    __android_log_print(ANDROID_LOG_INFO, "MyTestTag", "START: rtksvrstart() SUCCEEDED. Initial svr.state: %d", svr.state);

    return 1;
}
