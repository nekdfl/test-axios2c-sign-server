/**
 * @file demosign.h
 * @brief Demo document pseudo-signature API (WinAPI-like C surface, POSIX implementation).
 */
#ifndef DEMOSIGN_H
#define DEMOSIGN_H

#include <stddef.h>
#include <stdint.h>

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

typedef uint32_t DWORD;
typedef const char *LPCSTR;

typedef struct DEMO_SIGN_STRING_VIEW {
    LPCSTR Data;
    DWORD Length;
} DEMO_SIGN_STRING_VIEW;

typedef struct DEMO_SIGN_DOCUMENT_REQUEST {
    DEMO_SIGN_STRING_VIEW KeyId;
    DEMO_SIGN_STRING_VIEW Document;
} DEMO_SIGN_DOCUMENT_REQUEST;

#define DEMO_SIGN_SIGNATURE_HEX_CHARS 64u

typedef struct DEMO_SIGN_SIGNATURE_BUFFER {
    char Buffer[DEMO_SIGN_SIGNATURE_HEX_CHARS + 1u];
} DEMO_SIGN_SIGNATURE_BUFFER;

#define DS_S_OK 0u
#define DS_E_INVALID_PARAMETER 0x80070057u
#define DS_E_INTERNAL 0x80004005u

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Computes a deterministic pseudo-signature from key id and document text.
 *
 * If @p request->KeyId.Length or @p request->Document.Length is 0 and Data is non-NULL,
 * the segment length is strlen(Data). If Data is NULL, the view is empty (length 0).
 *
 * @param[in] request   Key id and document views; both must be non-empty for success.
 * @param[out] signature Receives hex string of length #DEMO_SIGN_SIGNATURE_HEX_CHARS plus NUL.
 * @param[out] errorCode Receives #DS_S_OK or a failure code (#DS_E_INVALID_PARAMETER, #DS_E_INTERNAL).
 *
 * @retval TRUE  Signature written and @p *errorCode is #DS_S_OK.
 * @retval FALSE See @p *errorCode.
 */
BOOL WINAPI DemoSign_ComputeDocumentSignature(
    const DEMO_SIGN_DOCUMENT_REQUEST *request,
    DEMO_SIGN_SIGNATURE_BUFFER *signature,
    DWORD *errorCode);

#ifdef __cplusplus
}
#endif

#endif /* DEMOSIGN_H */
