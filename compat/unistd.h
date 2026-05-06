/* Windows compat stub for <unistd.h>.
 * On Windows only getopt / getopt_long are pulled in from this header
 * by the icestorm sources; everything else is provided natively. */
#pragma once
#ifdef _WIN32
#include "getopt.h"
#endif
