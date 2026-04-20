/**
 * @file demo_sign_skeleton.c
 * @brief Axis2 service skeleton for demo_sign (invoke, lifecycle, DLL exports).
 */

#include <axis2_msg_ctx.h>
#include <axis2_op.h>
#include <axis2_svc_skeleton.h>
#include <axutil_array_list.h>
#include <axutil_qname.h>
#include <axiom_element.h>
#include <axiom_node.h>
#include <stdio.h>
#include <string.h>

#include "demo_sign_svc.h"

/** @brief Frees skeleton state (see definition). */
int AXIS2_CALL demo_sign_free(axis2_svc_skeleton_t *svc_skeleton, const axutil_env_t *env);

/** @brief Dispatches SOAP operation (see definition). */
axiom_node_t *AXIS2_CALL demo_sign_invoke(axis2_svc_skeleton_t *svc_skeleton,
                                          const axutil_env_t *env,
                                          axiom_node_t *node,
                                          axis2_msg_ctx_t *msg_ctx);

/** @brief Skeleton init hook (see definition). */
int AXIS2_CALL demo_sign_init(axis2_svc_skeleton_t *svc_skeleton, const axutil_env_t *env);

/** @brief Builds fault OM on service error (see definition). */
axiom_node_t *AXIS2_CALL demo_sign_on_fault(axis2_svc_skeleton_t *svc_skeli,
                                            const axutil_env_t *env,
                                            axiom_node_t *node);

static const axis2_svc_skeleton_ops_t demo_sign_svc_skeleton_ops_var = {
    .invoke = demo_sign_invoke,
    .on_fault = demo_sign_on_fault,
    .free = demo_sign_free,
    .init = demo_sign_init,
};

/**
 * @brief Allocates and wires the demo_sign service skeleton.
 *
 * @param[in] env Axis2 environment (allocator used).
 *
 * @return New skeleton with ops table set, or NULL if allocation fails.
 */
axis2_svc_skeleton_t *
demo_sign_create(const axutil_env_t *env)
{
    axis2_svc_skeleton_t *svc_skeleton = NULL;

    svc_skeleton = AXIS2_MALLOC(env->allocator, sizeof(axis2_svc_skeleton_t));
    svc_skeleton->ops = &demo_sign_svc_skeleton_ops_var;
    svc_skeleton->func_array = NULL;
    return svc_skeleton;
}

/**
 * @brief Axis2 skeleton @c init callback (no-op for this service).
 *
 * @param[in] svc_skeleton Service skeleton instance.
 * @param[in] env          Axis2 environment.
 *
 * @return AXIS2_SUCCESS always.
 */
int AXIS2_CALL
demo_sign_init(axis2_svc_skeleton_t *svc_skeleton, const axutil_env_t *env)
{
    (void)svc_skeleton;
    (void)env;
    return AXIS2_SUCCESS;
}

/**
 * @brief Axis2 skeleton @c free callback; releases func_array and skeleton struct.
 *
 * @param[in] svc_skeleton Service skeleton instance (may be NULL).
 * @param[in] env          Axis2 environment.
 *
 * @return AXIS2_SUCCESS.
 */
int AXIS2_CALL
demo_sign_free(axis2_svc_skeleton_t *svc_skeleton, const axutil_env_t *env)
{
    if (svc_skeleton->func_array) {
        axutil_array_list_free(svc_skeleton->func_array, env);
        svc_skeleton->func_array = NULL;
    }
    if (svc_skeleton) {
        AXIS2_FREE(env->allocator, svc_skeleton);
    }
    return AXIS2_SUCCESS;
}

/**
 * @brief Axis2 skeleton @c on_fault callback; returns a simple error OM tree.
 *
 * @param[in] svc_skeli Unused.
 * @param[in] env       Axis2 environment.
 * @param[in] node      Unused fault node from engine.
 *
 * @return Root node DemoSignServiceError, or NULL on failure.
 */
axiom_node_t *AXIS2_CALL
demo_sign_on_fault(axis2_svc_skeleton_t *svc_skeli, const axutil_env_t *env, axiom_node_t *node)
{
    axiom_node_t *error_node = NULL;
    axiom_element_t *error_ele = NULL;

    (void)svc_skeli;
    (void)node;
    error_ele = axiom_element_create(env, NULL, "DemoSignServiceError", NULL, &error_node);
    axiom_element_set_text(error_ele, env, "demo_sign service failed", error_node);
    return error_node;
}

/**
 * @brief Reads SOAP operation local part from the message context (WSDL dispatch path).
 *
 * @param[in] env     Axis2 environment.
 * @param[in] msg_ctx Current message context.
 *
 * @return Local part string owned by Axis2, or NULL if unavailable.
 */
static axis2_char_t *
op_localpart_from_msg_ctx(const axutil_env_t *env, axis2_msg_ctx_t *msg_ctx)
{
    axis2_op_t *op = axis2_msg_ctx_get_op(msg_ctx, env);
    const axutil_qname_t *qn;

    if (!op) {
        return NULL;
    }
    qn = axis2_op_get_qname(op, env);
    if (!qn) {
        return NULL;
    }
    return axutil_qname_get_localpart((axutil_qname_t *)(void *)qn, env);
}

/**
 * @brief Axis2 skeleton @c invoke callback; routes getHealth and signDocument.
 *
 * Dispatches by OM root localname first, then by operation qname from @p msg_ctx.
 *
 * @param[in] svc_skeleton Unused.
 * @param[in] env          Axis2 environment.
 * @param[in] node         SOAP body element (may be NULL).
 * @param[in] msg_ctx      Message context for operation name fallback.
 *
 * @return Response OM root, or NULL with error set if unknown or invalid.
 */
axiom_node_t *AXIS2_CALL
demo_sign_invoke(axis2_svc_skeleton_t *svc_skeleton,
                 const axutil_env_t *env,
                 axiom_node_t *node,
                 axis2_msg_ctx_t *msg_ctx)
{
    axis2_char_t *op = NULL;

    (void)svc_skeleton;

    if (node && axiom_node_get_node_type(node, env) == AXIOM_ELEMENT) {
        axiom_element_t *element = (axiom_element_t *)axiom_node_get_data_element(node, env);
        if (element) {
            axis2_char_t *op_name = axiom_element_get_localname(element, env);
            if (op_name) {
                if (axutil_strcmp(op_name, "signDocument") == 0) {
                    return demo_sign_handle_sign_document(env, node);
                }
                if (axutil_strcmp(op_name, "getHealth") == 0) {
                    return demo_sign_handle_get_health(env);
                }
            }
        }
    }

    op = op_localpart_from_msg_ctx(env, msg_ctx);
    if (op) {
        if (axutil_strcmp(op, "getHealth") == 0) {
            return demo_sign_handle_get_health(env);
        }
        if (axutil_strcmp(op, "signDocument") == 0) {
            return demo_sign_handle_sign_document(env, node);
        }
    }

    demo_sign_svc_set_error(env, "demo_sign: unknown operation or invalid payload");
    return NULL;
}

/**
 * @brief Axis2 DLL entry: allocates the demo_sign service skeleton instance.
 *
 * @param[out] inst Receives new skeleton pointer.
 * @param[in]  env  Axis2 environment.
 *
 * @return AXIS2_SUCCESS or AXIS2_FAILURE.
 */
AXIS2_EXPORT int
axis2_get_instance(axis2_svc_skeleton_t **inst, const axutil_env_t *env)
{
    *inst = demo_sign_create(env);
    if (!(*inst)) {
        return AXIS2_FAILURE;
    }
    return AXIS2_SUCCESS;
}

/**
 * @brief Axis2 DLL entry: destroys a skeleton created by axis2_get_instance().
 *
 * @param[in] inst Skeleton instance (may be NULL).
 * @param[in] env  Axis2 environment.
 *
 * @return Status from AXIS2_SVC_SKELETON_FREE, or AXIS2_FAILURE if @p inst is NULL.
 */
AXIS2_EXPORT int
axis2_remove_instance(axis2_svc_skeleton_t *inst, const axutil_env_t *env)
{
    axis2_status_t status = AXIS2_FAILURE;
    if (inst) {
        status = AXIS2_SVC_SKELETON_FREE(inst, env);
    }
    return status;
}
