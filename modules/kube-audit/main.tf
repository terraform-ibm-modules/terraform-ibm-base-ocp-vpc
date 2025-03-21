
data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = var.cluster_id
  admin             = true # workaround for https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/issues/374
  resource_group_id = var.cluster_resource_group_id
  endpoint_type     = var.cluster_config_endpoint_type != "default" ? var.cluster_config_endpoint_type : null # null value represents default
}

data "ibm_container_vpc_cluster" "cluster" {
  name              = var.cluster_id
  resource_group_id = var.cluster_resource_group_id
  wait_till         = var.wait_till
  wait_till_timeout = var.wait_till_timeout
}

locals {
  # tflint-ignore: terraform_unused_declarations
  validate_existing_vpc_id = tonumber(regex("^([0-9]+\\.[0-9]+)", data.ibm_container_vpc_cluster.cluster.kube_version)[0]) > "4.14" ? true : tobool("Kubernetes API server audit logs forwarding is only supported in ocp versions 4.15 and later.")
}

resource "null_resource" "set_audit_log_policy" {
  count = var.audit_log_policy != "default" ? 1 : 0

  provisioner "local-exec" {
    command     = "${path.module}/scripts/set_audit_log_policy.sh ${var.audit_log_policy}"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}

#########################################################################################################################
# Creates a log collection service and container
########################################################################################################################

locals {
  kube_audit_chart_location = "${path.module}/helm-charts/kube-audit"
}

resource "helm_release" "kube_audit" {
  depends_on    = [null_resource.set_audit_log_policy]
  name          = var.audit_deployment_name
  chart         = local.kube_audit_chart_location
  timeout       = 1200
  wait          = true
  recreate_pods = true
  force_update  = true

  set {
    name  = "metadata.name"
    type  = "string"
    value = var.audit_deployment_name
  }

  set {
    name  = "metadata.namespace"
    type  = "string"
    value = var.audit_namespace
  }
  set {
    name  = "image.name"
    type  = "string"
    value = var.audit_webhook_listener_image
  }

  set {
    name  = "image.tag"
    type  = "string"
    value = var.audit_webhook_listener_image_version
  }

  provisioner "local-exec" {
    command     = "${path.module}/scripts/confirm-rollout-status.sh ${var.audit_deployment_name} ${var.audit_namespace}"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}

locals {
  audit_server = "https://127.0.0.1:2040/api/v1/namespaces/${var.audit_namespace}/services/${var.audit_deployment_name}-service/proxy/post"
}

data "ibm_iam_auth_token" "reset_api_key_tokendata" {
}

data "ibm_iam_account_settings" "iam_account_settings" {
}

resource "null_resource" "set_audit_webhook" {
  depends_on = [helm_release.kube_audit]
  provisioner "local-exec" {
    command     = "${path.module}/scripts/set_audit_webhook.sh ${var.region} ${var.use_private_endpoint} ${var.cluster_config_endpoint_type} ${var.cluster_id} ${var.cluster_resource_group_id} ${var.cluster_config_endpoint_type != "default" ? "verbose" : "default"}"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      IAM_TOKEN    = data.ibm_iam_auth_token.reset_api_key_tokendata.iam_access_token
      ACCOUNT_ID   = data.ibm_iam_account_settings.iam_account_settings.account_id
      AUDIT_SERVER = local.audit_server
      CLIENT_CERT  = data.ibm_container_cluster_config.cluster_config.admin_certificate
      CLIENT_KEY   = data.ibm_container_cluster_config.cluster_config.admin_key
    }
  }
}
