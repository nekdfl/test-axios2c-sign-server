/**
 * @file demosign.c
 * @brief Implementation of demo document pseudo-signature (POSIX only).
 */

#define _POSIX_C_SOURCE 200809L

#include <demosign.h>

#include <inttypes.h>
#include <stdio.h>
#include <string.h>

/**
 * @brief 64-bit FNV-1a hash over a byte buffer.
 *
 * @param[in] p Start of buffer (must be valid for @p n bytes if n > 0).
 * @param[in] n Number of bytes.
 *
 * @return FNV-1a digest.
 */
static uint64_t
fnv1a64(const unsigned char *p, size_t n)
{
    uint64_t h = UINT64_C(1469598103934665603);
    size_t i;

    for (i = 0; i < n; i++) {
        h ^= (uint64_t)p[i];
        h *= UINT64_C(1099511628211);
    }
    return h;
}

/**
 * @brief Length in bytes of a #DEMO_SIGN_STRING_VIEW.
 *
 * @param[in] v View pointer (may be NULL).
 *
 * @return Effective length: 0 if NULL or empty; else Length if non-zero, else strlen(Data).
 */
static size_t
view_length_bytes(const DEMO_SIGN_STRING_VIEW *v)
{
    if (!v || !v->Data) {
        return 0;
    }
    if (v->Length != 0u) {
        return (size_t)v->Length;
    }
    return strlen(v->Data);
}

/**
 * @copydoc DemoSign_ComputeDocumentSignature
 */
BOOL WINAPI
DemoSign_ComputeDocumentSignature(
    const DEMO_SIGN_DOCUMENT_REQUEST *request,
    DEMO_SIGN_SIGNATURE_BUFFER *signature,
    DWORD *errorCode)
{
    size_t key_len;
    size_t doc_len;
    uint64_t h1;
    uint64_t h2;
    uint64_t h3;
    uint64_t h4;
    int n;

    if (!errorCode) {
        return FALSE;
    }
    *errorCode = DS_S_OK;

    if (!request || !signature) {
        *errorCode = DS_E_INVALID_PARAMETER;
        return FALSE;
    }

    key_len = view_length_bytes(&request->KeyId);
    doc_len = view_length_bytes(&request->Document);
    if (key_len == 0 || doc_len == 0) {
        *errorCode = DS_E_INVALID_PARAMETER;
        return FALSE;
    }

    h1 = fnv1a64((const unsigned char *)request->KeyId.Data, key_len);
    h2 = fnv1a64((const unsigned char *)request->Document.Data, doc_len);
    h3 = h1 ^ (h2 + UINT64_C(0x9e3779b97f4a7c15));
    h4 = (h2 << 1) ^ (h1 >> 1);

    n = snprintf(signature->Buffer,
                 sizeof signature->Buffer,
                 "%016" PRIx64 "%016" PRIx64 "%016" PRIx64 "%016" PRIx64,
                 (uint64_t)h1,
                 (uint64_t)h2,
                 (uint64_t)h3,
                 (uint64_t)h4);
    if (n < 0 || (size_t)n != DEMO_SIGN_SIGNATURE_HEX_CHARS) {
        *errorCode = DS_E_INTERNAL;
        return FALSE;
    }
    signature->Buffer[DEMO_SIGN_SIGNATURE_HEX_CHARS] = '\0';
    return TRUE;
}
