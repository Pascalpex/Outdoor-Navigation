#ifndef MY_RTKLIB_API_H
#define MY_RTKLIB_API_H

#include "rtklib.h" // Provides core RTKLIB data structures and function declarations.

#ifdef __cplusplus
extern "C"
{
#endif
    /**
     * Initializes the RTK server.
     * @return 1 on success, 0 on failure.
     */
    int init_rtk_server(void);

    /**
     * stops the RTK server
     */
    void stop_rtk_server(void);

    /**
     * Starts the RTK server with predefined NTRIP streams and processing options.
     * @return 1 on success, 0 on failure.
     */
    int start_rtk_server(void);
    /**
     * Inputs rover observation data into the RTK server.
     * @param gpsTimeNanos GPS time in nanoseconds.
     * @param svids Array of satellite IDs.
     * @param constellationTypes Array of constellation types (e.g., GPS, GLONASS).
     * @param cn0DbHzs Array of carrier-to-noise density values in dB-Hz.
     * @param carrierFrequenciesHz Array of carrier frequencies in Hz.
     * @param adrMeters Array of accumulated delta range values in meters.
     * @param adrStates Array of ADR states.
     * @param pratesMps Array of pseudorange rates in meters per second.
     * @param pseudoranges Array of pseudorange values.
     * @param count Number of observations to input.
     * @return Number of bytes written to the stream, or 0 on failure.
     */
    int input_rover_observation(
        long long gpsTimeNanos,
        const int *svids,
        const int *constellationTypes,
        const double *cn0DbHzs,
        const double *carrierFrequenciesHz,
        const double *adrMeters,
        const int *adrStates,
        const double *pratesMps,
        const double *pseudoranges,
        int count);

    /**
     * Retrieves the latest RTK solution as a string.
     * @param buffer Pointer to a buffer where the solution will be written.
     * @param buffer_size Size of the buffer.
     * @return Length of the string written to the buffer, or 0 on failure.
     * */
    int get_rtk_solution(char *buffer, int buffer_size);

    /**
     * Prints the current status of the RTK server for debugging purposes.
     */
    void print_rtk_server_status_debug(void);

#ifdef __cplusplus
}
#endif

#endif // MY_RTKLIB_API_H
