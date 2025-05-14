cmake_minimum_required(VERSION 3.4.1)
project(rtklib_android)

# Define the include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/../library/rtklib
    
)

# Source files from RTKLIB - just the ones needed for NTRIP and RTK
set(RTKLIB_SOURCES
    # Core functionality
    ${CMAKE_CURRENT_SOURCE_DIR}/../library/rtklib/rtkcmn.c
    ${CMAKE_CURRENT_SOURCE_DIR}/../library/rtklib/rtkpos.c
    
    # NTRIP and streaming support
    ${CMAKE_CURRENT_SOURCE_DIR}/../library/rtklib/stream.c
    ${CMAKE_CURRENT_SOURCE_DIR}/../library/rtklib/rtcm.c
    ${CMAKE_CURRENT_SOURCE_DIR}/../library/rtklib/rtcm2.c
    ${CMAKE_CURRENT_SOURCE_DIR}/../library/rtklib/rtcm3.c
    
    # Required for positioning calculations
    ${CMAKE_CURRENT_SOURCE_DIR}/../library/rtklib/ephemeris.c
    ${CMAKE_CURRENT_SOURCE_DIR}/../library/rtklib/ionex.c
    ${CMAKE_CURRENT_SOURCE_DIR}/../library/rtklib/pntpos.c
    ${CMAKE_CURRENT_SOURCE_DIR}/../library/rtklib/preceph.c
    ${CMAKE_CURRENT_SOURCE_DIR}/../library/rtklib/solution.c
    
    # Your custom wrapper
    ${CMAKE_CURRENT_SOURCE_DIR}/../library/rtklib_wrapper.c
)

# Define the library
add_library(
    rtklib_wrapper
    SHARED
    ${RTKLIB_SOURCES}
)

# Find and link against Android log library for debugging
find_library(log-lib log)

# Link the required libraries
target_link_libraries(
    rtklib_wrapper
    ${log-lib}
    # Add other Android system libraries if needed
    android
    m  # math library
)

# Compiler definitions for RTKLIB
target_compile_definitions(rtklib_wrapper PRIVATE
    ENAGLO
    ENAQZS
    ENAGAL
    ENACMP
    NFREQ=3
    TRACE
    ANDROID
)

# Add any additional compiler flags
target_compile_options(rtklib_wrapper PRIVATE
    -Wall
    -O3
    -fPIC
)