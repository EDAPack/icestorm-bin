# Helper script: generate a timings-<chip>.cc file by running timings.py
# and capturing its stdout.
# Called with:
#   cmake -DPython3_EXECUTABLE=... -DTIMINGS_PY=... -DCHIP=... -DOUTPUT_FILE=... -P gen_timings.cmake

execute_process(
    COMMAND "${Python3_EXECUTABLE}" "${TIMINGS_PY}" "${CHIP}"
    WORKING_DIRECTORY "${ICETIME_DIR}"
    OUTPUT_FILE "${OUTPUT_FILE}"
    RESULT_VARIABLE result
    ERROR_VARIABLE err_output
)
if(result)
    message(FATAL_ERROR "timings.py failed for chip ${CHIP}:\n${err_output}")
endif()
