cmake_minimum_required(VERSION 3.16)
project(icestorm VERSION 1.1 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_C_STANDARD 99)

# ── Windows compat ───────────────────────────────────────────────────────────
if(WIN32)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS -DNOMINMAX)
    # Prepend compat/ so POSIX stub headers are found before SDK headers
    include_directories(BEFORE "${COMPAT_DIR}")
    set(GETOPT_SRC "${COMPAT_DIR}/getopt.c")
else()
    set(GETOPT_SRC "")
endif()

# ── Helpers ───────────────────────────────────────────────────────────────────
function(add_ice_exe target)
    add_executable(${target} ${ARGN} ${GETOPT_SRC})
    if(MSVC)
        target_compile_options(${target} PRIVATE /W2 /wd4996)
    else()
        target_compile_options(${target} PRIVATE -Wall -Wno-unused-result)
    endif()
    install(TARGETS ${target} RUNTIME DESTINATION bin)
endfunction()

# ── icepack / iceunpack ───────────────────────────────────────────────────────
add_ice_exe(icepack icepack/icepack.cc)
if(WIN32)
    install(CODE "
        execute_process(COMMAND \"${CMAKE_COMMAND}\" -E copy
            \"\${CMAKE_INSTALL_PREFIX}/bin/icepack.exe\"
            \"\${CMAKE_INSTALL_PREFIX}/bin/iceunpack.exe\")
    ")
else()
    install(CODE "
        execute_process(COMMAND \"${CMAKE_COMMAND}\" -E create_symlink
            icepack \"\${CMAKE_INSTALL_PREFIX}/bin/iceunpack\")
    ")
endif()

# ── icemulti ──────────────────────────────────────────────────────────────────
add_ice_exe(icemulti icemulti/icemulti.cc)

# ── icepll ────────────────────────────────────────────────────────────────────
add_ice_exe(icepll icepll/icepll.cc)
if(NOT WIN32)
    target_link_libraries(icepll m)
endif()

# ── icebram ───────────────────────────────────────────────────────────────────
add_ice_exe(icebram icebram/icebram.cc)

# ── icetime ───────────────────────────────────────────────────────────────────
find_package(Python3 REQUIRED COMPONENTS Interpreter)

set(CHIPS lp384 lp1k lp8k hx1k hx8k up5k u4k)
set(TIMINGS_SOURCES "")
foreach(CHIP ${CHIPS})
    set(TIMING_SRC "${CMAKE_CURRENT_BINARY_DIR}/timings-${CHIP}.cc")
    add_custom_command(
        OUTPUT  "${TIMING_SRC}"
        COMMAND "${CMAKE_COMMAND}"
            "-DPython3_EXECUTABLE=${Python3_EXECUTABLE}"
            "-DTIMINGS_PY=${CMAKE_CURRENT_SOURCE_DIR}/icetime/timings.py"
            "-DICETIME_DIR=${CMAKE_CURRENT_SOURCE_DIR}/icetime"
            "-DCHIP=${CHIP}"
            "-DOUTPUT_FILE=${TIMING_SRC}"
            -P "${GEN_TIMINGS_SCRIPT}"
        DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/icetime/timings.py"
                "${CMAKE_CURRENT_SOURCE_DIR}/icefuzz/timings_${CHIP}.txt"
        COMMENT "Generating timings-${CHIP}.cc"
    )
    list(APPEND TIMINGS_SOURCES "${TIMING_SRC}")
endforeach()

add_executable(icetime
    icetime/icetime.cc
    icetime/iceutil.cc
    ${TIMINGS_SOURCES}
    ${GETOPT_SRC}
)
if(MSVC)
    target_compile_options(icetime PRIVATE /W2 /wd4996)
else()
    target_compile_options(icetime PRIVATE -Wall -Wno-unused-result)
endif()
target_include_directories(icetime PRIVATE "${CMAKE_CURRENT_BINARY_DIR}")
target_compile_definitions(icetime PRIVATE
    PREFIX="${CMAKE_INSTALL_PREFIX}"
    CHIPDB_SUBDIR="icebox"
)
install(TARGETS icetime RUNTIME DESTINATION bin)

# ── Data files ────────────────────────────────────────────────────────────────
# icebox chip databases (for icepack, icetime)
install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/icebox/"
    DESTINATION "share/icebox"
    FILES_MATCHING PATTERN "chipdb-*.txt"
)

# icefuzz timing tables (used by icetime at runtime via relative path)
foreach(CHIP ${CHIPS})
    install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/icefuzz/timings_${CHIP}.txt"
        DESTINATION "share/icebox"
    )
endforeach()
