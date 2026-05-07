/* Windows compat stub for <unistd.h>.
 * Provides getopt/getopt_long (from getopt.h), getpid (via process.h),
 * and usleep() (via Sleep()). */
#pragma once
#ifdef _WIN32
#include "getopt.h"
#include <process.h>
/* POSIX getpid() → Windows _getpid() */
#ifndef getpid
#define getpid _getpid
#endif
/* POSIX usleep(microseconds) → Windows Sleep(milliseconds).
 * winsock2.h must precede windows.h to avoid redefinition conflicts. */
#ifndef usleep
#include <winsock2.h>
#include <windows.h>
static __inline int usleep(unsigned long us)
{
    Sleep(us / 1000);
    return 0;
}
#endif
#endif
