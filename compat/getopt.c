/* Public domain getopt / getopt_long for Windows.
 * Based on the classic BSD / musl implementation; no copyright claimed. */

#ifdef _WIN32

#include "getopt.h"
#include <stdio.h>
#include <string.h>

char *optarg = NULL;
int   optind = 1;
int   opterr = 1;
int   optopt = '?';

/* Internal state */
static const char *_optcursor = NULL;

int getopt(int argc, char * const argv[], const char *optstring)
{
    if (optind >= argc || !argv[optind])
        return -1;

    if (!_optcursor || *_optcursor == '\0') {
        const char *arg = argv[optind];
        if (arg[0] != '-' || arg[1] == '\0')
            return -1;
        if (arg[1] == '-' && arg[2] == '\0') {
            optind++;
            return -1;
        }
        _optcursor = arg + 1;
    }

    int c = (unsigned char)*_optcursor++;
    const char *p = strchr(optstring, c);

    if (!p) {
        optopt = c;
        if (opterr && optstring[0] != ':')
            fprintf(stderr, "%s: invalid option -- '%c'\n", argv[0], c);
        if (*_optcursor == '\0') optind++;
        return '?';
    }

    if (p[1] == ':') {
        optarg = NULL;
        if (*_optcursor != '\0') {
            optarg = (char *)_optcursor;
            _optcursor = NULL;
            optind++;
        } else if (p[2] == ':') {
            /* optional argument not present */
            optind++;
        } else if (optind + 1 < argc) {
            optind++;
            optarg = argv[optind];
            optind++;
        } else {
            optopt = c;
            if (opterr && optstring[0] != ':')
                fprintf(stderr, "%s: option requires an argument -- '%c'\n", argv[0], c);
            if (*_optcursor == '\0') optind++;
            return (optstring[0] == ':') ? ':' : '?';
        }
    } else {
        if (*_optcursor == '\0') optind++;
    }

    return c;
}

int getopt_long(int argc, char * const argv[], const char *optstring,
                const struct option *longopts, int *longindex)
{
    if (optind >= argc || !argv[optind])
        return -1;

    const char *arg = argv[optind];

    /* Long option: starts with "--" followed by at least one char */
    if (arg[0] == '-' && arg[1] == '-' && arg[2] != '\0') {
        /* end-of-options "--" is handled below via short-option path */
        const char *name = arg + 2;
        size_t namelen = strlen(name);
        const char *eq = strchr(name, '=');
        if (eq) namelen = (size_t)(eq - name);

        for (int i = 0; longopts[i].name; i++) {
            if (strncmp(name, longopts[i].name, namelen) != 0 ||
                strlen(longopts[i].name) != namelen)
                continue;

            if (longindex) *longindex = i;
            optind++;

            if (longopts[i].has_arg == required_argument ||
                longopts[i].has_arg == optional_argument) {
                if (eq) {
                    optarg = (char *)(eq + 1);
                } else if (longopts[i].has_arg == required_argument) {
                    if (optind < argc) {
                        optarg = argv[optind++];
                    } else {
                        optopt = longopts[i].val;
                        if (opterr)
                            fprintf(stderr, "%s: option '--%s' requires an argument\n",
                                    argv[0], longopts[i].name);
                        return (optstring[0] == ':') ? ':' : '?';
                    }
                } else {
                    optarg = NULL;
                }
            } else {
                optarg = NULL;
            }

            if (longopts[i].flag) {
                *longopts[i].flag = longopts[i].val;
                return 0;
            }
            return longopts[i].val;
        }

        optopt = 0;
        if (opterr)
            fprintf(stderr, "%s: unrecognized option '--%.*s'\n",
                    argv[0], (int)namelen, name);
        optind++;
        return '?';
    }

    /* Fall through to short option handling */
    return getopt(argc, argv, optstring);
}

#endif /* _WIN32 */
