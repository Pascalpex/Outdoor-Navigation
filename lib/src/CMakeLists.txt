# Minimum CMake version.
cmake_minimum_required(VERSION 3.18)

# Project definition.
project(gnss_rtklib
        VERSION 1.0
        LANGUAGES C)

# --- Fetch RTKLIB source code ---
# Manages the RTKLIB dependency using FetchContent.

set(FETCHCONTENT_QUIET OFF) # Verbose FetchContent output.
include(FetchContent)

# Declare RTKLIB Git repository: specifies URL and exact commit (GIT_TAG) for reproducibility.
# EXCLUDE_FROM_ALL prevents building RTKLIB as a separate project.
FetchContent_Declare(
        rtklib_sources
        GIT_REPOSITORY https://github.com/rtklibexplorer/RTKLIB.git
        GIT_TAG        1ac2604de30171334ef05b00b81da16858fe5460
        EXCLUDE_FROM_ALL
)

# Make rtklib_sources_SOURCE_DIR (path to sources) available.
FetchContent_GetProperties(rtklib_sources)

# Download and extract RTKLIB sources if not already done.
if(NOT rtklib_sources_POPULATED)
    FetchContent_Populate(rtklib_sources)
endif()

# --- Library Target: gnss_rtklib ---
# Defines the main shared library, compiling the custom interface and selected RTKLIB sources directly.
add_library(gnss_rtklib SHARED
        # Custom C interface/wrapper.
        ./library/my_interface/rtklib_wrapper.c

        # Core RTKLIB source files. Add more as needed based on usage.
        ${rtklib_sources_SOURCE_DIR}/src/solution.c
        ${rtklib_sources_SOURCE_DIR}/src/trace.c
        ${rtklib_sources_SOURCE_DIR}/src/rtkcmn.c
        ${rtklib_sources_SOURCE_DIR}/src/geoid.c
        ${rtklib_sources_SOURCE_DIR}/src/rtksvr.c
        ${rtklib_sources_SOURCE_DIR}/src/rtkpos.c
        ${rtklib_sources_SOURCE_DIR}/src/stream.c
        ${rtklib_sources_SOURCE_DIR}/src/rcvraw.c
        ${rtklib_sources_SOURCE_DIR}/src/rtcm.c
        ${rtklib_sources_SOURCE_DIR}/src/preceph.c
        ${rtklib_sources_SOURCE_DIR}/src/sbas.c
        ${rtklib_sources_SOURCE_DIR}/src/rinex.c
        ${rtklib_sources_SOURCE_DIR}/src/pntpos.c
        ${rtklib_sources_SOURCE_DIR}/src/ppp.c
        ${rtklib_sources_SOURCE_DIR}/src/ionex.c
        ${rtklib_sources_SOURCE_DIR}/src/ephemeris.c
        ${rtklib_sources_SOURCE_DIR}/src/tides.c
        ${rtklib_sources_SOURCE_DIR}/src/rcv/rt17.c
        ${rtklib_sources_SOURCE_DIR}/src/rcv/septentrio.c
        ${rtklib_sources_SOURCE_DIR}/src/rcv/binex.c
        ${rtklib_sources_SOURCE_DIR}/src/rcv/skytraq.c
        ${rtklib_sources_SOURCE_DIR}/src/rcv/unicore.c
        ${rtklib_sources_SOURCE_DIR}/src/rcv/novatel.c
        ${rtklib_sources_SOURCE_DIR}/src/rcv/ublox.c
        ${rtklib_sources_SOURCE_DIR}/src/rcv/nvs.c
        ${rtklib_sources_SOURCE_DIR}/src/ppp_ar.c
        ${rtklib_sources_SOURCE_DIR}/src/rtcm2.c
        ${rtklib_sources_SOURCE_DIR}/src/rtcm3.c
        ${rtklib_sources_SOURCE_DIR}/src/rtcm3e.c
        ${rtklib_sources_SOURCE_DIR}/src/rcv/crescent.c
        ${rtklib_sources_SOURCE_DIR}/src/rcv/javad.c
        ${rtklib_sources_SOURCE_DIR}/src/rcv/swiftnav.c
        ${rtklib_sources_SOURCE_DIR}/src/lambda.c
        ${rtklib_sources_SOURCE_DIR}/src/options.c
)

# --- Compiler Configuration ---

# Base compiler options for all build types.
set(COMMON_COMPILE_OPTIONS
        -std=c99        # C99 standard.
        -Wall           # All standard warnings.
        -pedantic       # Strict ISO C warnings.
        # RTKLIB specific definitions:
        -DENAGLO        # Enable GLONASS.
        -DENAGAL        # Enable Galileo.
        -DNFREQ=3       # Max carrier frequencies.
        -DNEXOBS=3      # Max extended observation types.
        -DSVR_REUSEADD  # Enable SO_REUSEADDR for server.
)

# Debug build specific options.
set(DEBUG_COMPILE_OPTIONS
        -Og             # Optimize for debugging.
        -g              # Generate debug info.
        -DTRACE         # Enable RTKLIB trace output.
)

# Release build specific options.
set(RELEASE_COMPILE_OPTIONS
        -O3             # High optimization level.
)

# Apply compiler options (common + build-type specific) to the target.
target_compile_options(gnss_rtklib PRIVATE
        ${COMMON_COMPILE_OPTIONS}
        $<$<CONFIG:Debug>:${DEBUG_COMPILE_OPTIONS}>
        $<$<CONFIG:Release>:${RELEASE_COMPILE_OPTIONS}>
)

# --- Include Directories ---
# Specifies header search paths for the 'gnss_rtklib' target.
target_include_directories(gnss_rtklib PRIVATE
    "${rtklib_sources_SOURCE_DIR}/src"     # RTKLIB public headers.
    "lib/src/library/my_interface"         # Project's local interface headers.
)

# --- Linker Configuration ---
# Links 'gnss_rtklib' against necessary system libraries (e.g., for Android NDK).
target_link_libraries(gnss_rtklib
        PRIVATE # Linkage is not propagated.
           android # Android native functionalities.
           log     # Android logging system.
           m       # Standard C math library.
)
