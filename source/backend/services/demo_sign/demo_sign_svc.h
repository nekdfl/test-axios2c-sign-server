/**
 * @file demo_sign_svc.h
 * @brief Internal helpers for the demo_sign Axis2 service (OM helpers).
 */
#pragma once

#include <axiom_node.h>
#include <axis2_msg_ctx.h>

/**
 * @brief Sets a human-readable fault message on the Axis2 error object.
 *
 * @param[in] env     Axis2 environment (non-NULL error slot used).
 * @param[in] message Failure description (caller lifetime must outlive use).
 */
void demo_sign_svc_set_error(const axutil_env_t *env, const char *message);

/**
 * @brief Builds a minimal OM tree for the getHealth SOAP response.
 *
 * @param[in] env Axis2 environment.
 *
 * @return New root node, or NULL on allocation failure.
 */
axiom_node_t *demo_sign_handle_get_health(const axutil_env_t *env);

/**
 * @brief Parses signDocument request OM, signs via demosign API, returns response OM.
 *
 * @param[in] env  Axis2 environment.
 * @param[in] node Request payload element (expects child elements key_id and document).
 *
 * @return Response root node, or NULL on parse/sign errors (error set via demo_sign_svc_set_error).
 */
axiom_node_t *demo_sign_handle_sign_document(const axutil_env_t *env, axiom_node_t *node);
