/**
 * @file demoposix.c
 * @brief POSIX sigaction wrappers with WinAPI-like naming.
 */

#define _POSIX_C_SOURCE 200809L

#include <demoposix.h>

#include <errno.h>
#include <string.h>

/**
 * @copydoc DemoPosix_Sigaction
 */
BOOL WINAPI
DemoPosix_Sigaction(int signum, DEMO_POSIX_SIGHANDLER handler, int extraSaFlags)
{
    struct sigaction sa;

    if (signum < 0 || !handler) {
        return FALSE;
    }

    (void)memset(&sa, 0, sizeof(sa));
    sa.sa_handler = handler;
    if (sigemptyset(&sa.sa_mask) != 0) {
        return FALSE;
    }
    sa.sa_flags = extraSaFlags;
    if (sigaction(signum, &sa, NULL) != 0) {
        (void)errno;
        return FALSE;
    }
    return TRUE;
}

/**
 * @copydoc DemoPosix_SignalIgnore
 */
BOOL WINAPI
DemoPosix_SignalIgnore(int signum)
{
    struct sigaction sa;

    if (signum < 0) {
        return FALSE;
    }

    (void)memset(&sa, 0, sizeof(sa));
    sa.sa_handler = SIG_IGN;
    if (sigemptyset(&sa.sa_mask) != 0) {
        return FALSE;
    }
    sa.sa_flags = 0;
    if (sigaction(signum, &sa, NULL) != 0) {
        (void)errno;
        return FALSE;
    }
    return TRUE;
}
