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
 * Define _WINSOCKAPI_ before including windows.h so that windows.h does
 * not pull in winsock.h, which would conflict with any later winsock2.h
 * inclusion (e.g. from libusb.h or ftdi.h headers). */
#ifndef usleep
#ifndef _WINSOCKAPI_
#define _WINSOCKAPI_
#endif
#include <windows.h>
static __inline int usleep(unsigned long us)
{
    Sleep(us / 1000);
    return 0;
}
#endif
#endif
