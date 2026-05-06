/* Windows compat stub for <sys/time.h>.
 * Include winsock2.h first (which defines struct timeval) then windows.h,
 * then provide gettimeofday() via GetSystemTimeAsFileTime. */
#pragma once
#ifdef _WIN32

/* winsock2.h must come before windows.h to avoid winsock/winsock2 conflicts
 * and to get the authoritative definition of struct timeval. */
#include <winsock2.h>
#include <windows.h>

static inline int gettimeofday(struct timeval *tv, void *tz)
{
    FILETIME ft;
    unsigned long long tmp;
    GetSystemTimeAsFileTime(&ft);
    tmp  = (unsigned long long)ft.dwHighDateTime << 32;
    tmp |= ft.dwLowDateTime;
    /* Windows FILETIME: 100-ns ticks since 1601-01-01.
     * Unix epoch offset: 116444736000000000 * 100 ns */
    tmp -= 116444736000000000ULL;
    tmp /= 10; /* microseconds */
    tv->tv_sec  = (long)(tmp / 1000000UL);
    tv->tv_usec = (long)(tmp % 1000000UL);
    (void)tz;
    return 0;
}

#endif /* _WIN32 */
