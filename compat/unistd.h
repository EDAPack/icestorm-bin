/* Windows compat stub for <unistd.h>.
 * Provides getopt/getopt_long (from getopt.h) and getpid (via process.h). */
#pragma once
#ifdef _WIN32
#include "getopt.h"
#include <process.h>
/* POSIX getpid() → Windows _getpid() */
#ifndef getpid
#define getpid _getpid
#endif
#endif
