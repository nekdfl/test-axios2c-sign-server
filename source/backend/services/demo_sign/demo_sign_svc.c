/**
 * @file demo_sign_svc.c
 * @brief SOAP/OM handlers for demo_sign (getHealth, signDocument).
 */

#include "demo_sign_svc.h"

#include <demosign.h>

#include <axutil_error_default.h>
#include <axutil_string.h>
#include <axiom_element.h>
#include <axiom_node.h>
#include <axiom_text.h>
#include <string.h>

/**
 * @copydoc demo_sign_svc_set_error
 */
void
demo_sign_svc_set_error(const axutil_env_t *env, const char *message)
{
    axutil_error_set_error_message(env->error, (axis2_char_t *)(void *)message);
    AXIS2_ERROR_SET(env->error, AXIS2_ERROR_LAST + 1, AXIS2_FAILURE);
}

/**
 * @brief Returns text of the first direct child element matching @p localname.
 *
 * @param[in] env       Axis2 environment.
 * @param[in] parent    Parent OM element node.
 * @param[in] localname Child element local name to match (e.g. key_id).
 *
 * @return Pointer to text owned by Axiom, or NULL if not found.
 */
static axis2_char_t *
read_child_text(const axutil_env_t *env, axiom_node_t *parent, const axis2_char_t *localname)
{
    axiom_node_t *child = axiom_node_get_first_element(parent, env);

    while (child) {
        if (axiom_node_get_node_type(child, env) == AXIOM_ELEMENT) {
            axiom_element_t *ce = (axiom_element_t *)axiom_node_get_data_element(child, env);
            if (ce) {
                axis2_char_t *ln = axiom_element_get_localname(ce, env);
                if (ln && axutil_strcmp(ln, localname) == 0) {
                    axiom_node_t *tn = axiom_node_get_first_child(child, env);
                    if (tn && axiom_node_get_node_type(tn, env) == AXIOM_TEXT) {
                        axiom_text_t *txt =
                            (axiom_text_t *)axiom_node_get_data_element(tn, env);
                        if (txt && axiom_text_get_value(txt, env)) {
                            return (axis2_char_t *)axiom_text_get_value(txt, env);
                        }
                    }
                }
            }
        }
        do {
            child = axiom_node_get_next_sibling(child, env);
        } while (child && axiom_node_get_node_type(child, env) != AXIOM_ELEMENT);
    }
    return NULL;
}

/**
 * @copydoc demo_sign_handle_get_health
 */
axiom_node_t *
demo_sign_handle_get_health(const axutil_env_t *env)
{
    axiom_node_t *out = NULL;
    axiom_element_t *root_ele =
        axiom_element_create(env, NULL, "getHealthResponse", NULL, &out);
    axiom_node_t *ok_node = NULL;
    axiom_element_t *ok_ele = axiom_element_create(env, out, "ok", NULL, &ok_node);

    (void)root_ele;
    axiom_element_set_text(ok_ele, env, "true", ok_node);
    return out;
}

/**
 * @copydoc demo_sign_handle_sign_document
 */
axiom_node_t *
demo_sign_handle_sign_document(const axutil_env_t *env, axiom_node_t *node)
{
    axis2_char_t *key_id = NULL;
    axis2_char_t *document = NULL;
    DEMO_SIGN_DOCUMENT_REQUEST req;
    DEMO_SIGN_SIGNATURE_BUFFER sig;
    DWORD err = DS_S_OK;

    if (!node) {
        demo_sign_svc_set_error(env, "signDocument: empty request");
        return NULL;
    }

    key_id = read_child_text(env, node, "key_id");
    document = read_child_text(env, node, "document");
    if (!key_id || !document) {
        demo_sign_svc_set_error(env, "signDocument: expected child elements <key_id> and <document>");
        return NULL;
    }

    (void)memset(&req, 0, sizeof(req));
    req.KeyId.Data = (LPCSTR)key_id;
    req.KeyId.Length = 0u;
    req.Document.Data = (LPCSTR)document;
    req.Document.Length = 0u;

    if (!DemoSign_ComputeDocumentSignature(&req, &sig, &err) || err != DS_S_OK) {
        demo_sign_svc_set_error(env, "signDocument: signing failed");
        return NULL;
    }

    {
        axiom_node_t *out = NULL;
        axiom_element_t *root_ele =
            axiom_element_create(env, NULL, "signDocumentResponse", NULL, &out);
        axiom_node_t *kid_node = NULL;
        axiom_element_t *kid_ele = axiom_element_create(env, out, "key_id", NULL, &kid_node);
        axiom_node_t *sig_node = NULL;
        axiom_element_t *sig_ele = axiom_element_create(env, out, "signature", NULL, &sig_node);

        (void)root_ele;
        axiom_element_set_text(kid_ele, env, key_id, kid_node);
        axiom_element_set_text(sig_ele, env, sig.Buffer, sig_node);
        return out;
    }
}
