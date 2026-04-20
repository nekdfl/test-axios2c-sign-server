/**
 * @file demoposix.h
 * @brief Thin POSIX.1-2008 wrappers (sigaction, etc.) with WinAPI-like names.
 */
#ifndef DEMOPOSIX_H
#define DEMOPOSIX_H

#include <signal.h>

#ifndef WINAPI
#define WINAPI
#endif
#ifndef CALLBACK
#define CALLBACK
#endif

#ifndef BOOL
typedef int BOOL;
#endif
#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif

typedef void (CALLBACK *DEMO_POSIX_SIGHANDLER)(int);

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Installs a handler for @p signum via sigaction(2).
 *
 * @p extraSaFlags is OR'd into sa_flags (for example 0 or SA_RESTART).
 * The previous disposition is not returned.
 *
 * @param[in] signum       Signal number (must be non-negative).
 * @param[in] handler      Non-NULL handler installed as sa_handler.
 * @param[in] extraSaFlags Additional flags merged into sa_flags.
 *
 * @retval TRUE  sigaction succeeded.
 * @retval FALSE Invalid arguments or sigaction failed.
 */
BOOL WINAPI DemoPosix_Sigaction(
    int signum,
    DEMO_POSIX_SIGHANDLER handler,
    int extraSaFlags);

/**
 * @brief Sets disposition for @p signum to SIG_IGN via sigaction(2).
 *
 * @param[in] signum Signal number (must be non-negative).
 *
 * @retval TRUE  sigaction succeeded.
 * @retval FALSE Invalid argument or sigaction failed.
 */
BOOL WINAPI DemoPosix_SignalIgnore(int signum);

#ifdef __cplusplus
}
#endif

#endif /* DEMOPOSIX_H */
