########################################################################################################################
# Addon
########################################################################################################################

locals {
  odf_version      = replace(data.ibm_container_vpc_cluster.cluster.kube_version, "/(\\d+\\.\\d+)\\.\\d+.*/", "$1.0")
  vpc_file_version = "2.0"
  addons = var.provision_odf_addon && var.provision_vpc_file_addon ? {
    "openshift-data-foundation" = local.odf_version,
    "vpc-file-csi-driver"       = local.vpc_file_version
    } : var.provision_odf_addon ? {
    "openshift-data-foundation" = local.odf_version,
    } : var.provision_vpc_file_addon ? {
    "vpc-file-csi-driver" = local.vpc_file_version
  } : {}
}

resource "ibm_container_addons" "addons" {
  count             = var.provision_odf_addon || var.provision_vpc_file_addon ? 1 : 0
  cluster           = var.cluster_id
  resource_group_id = var.cluster_resource_group_id

  # setting to false means we do not want Terraform to manage addons that are managed elsewhere
  manage_all_addons = false

  dynamic "addons" {
    for_each = local.addons
    content {
      name            = addons.key
      version         = addons.value
      parameters_json = addons.key != "openshift-data-foundation" ? null : <<PARAMETERS_JSON
        {
            "osdStorageClassName":"localblock",
            "odfDeploy":"true",
            "autoDiscoverDevices":"true"
        }
        PARAMETERS_JSON
    }
  }

  timeouts {
    create = "1h"
  }
}

resource "kubernetes_config_map_v1_data" "disable_default_storageclass" {
  metadata {
    name      = "addon-vpc-block-csi-driver-configmap"
    namespace = "kube-system"
  }

  data = {
    "IsStorageClassDefault" = "false"
  }

  force = true
}

resource "null_resource" "config_map_status" {
  count      = var.provision_vpc_file_addon ? 1 : 0
  depends_on = [ibm_container_addons.addons]

  provisioner "local-exec" {
    command     = "${path.module}/scripts/get_config_map_status.sh"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}

resource "kubernetes_config_map_v1_data" "set_vpc_file_default_storage_class" {
  count      = var.provision_vpc_file_addon ? 1 : 0
  depends_on = [null_resource.config_map_status]
  metadata {
    name      = "addon-vpc-file-csi-driver-configmap"
    namespace = "kube-system"
  }

  data = {
    "SET_DEFAULT_STORAGE_CLASS" = var.vpc_file_default_storage_class
  }

  force = true
}

# Wait a few minutes for the above changes to take effect.
resource "time_sleep" "wait_for_default_storage" {
  depends_on = [kubernetes_config_map_v1_data.set_vpc_file_default_storage_class]

  create_duration = "240s"
}

resource "null_resource" "enable_catalog_source" {
  depends_on = [time_sleep.wait_for_default_storage]

  provisioner "local-exec" {
    command     = "${path.module}/scripts/enable_catalog_source.sh"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}

########################################################################################################################
# Subscribing to the OpenShift Virtualization catalog
########################################################################################################################

locals {
  subscription_version        = "v4.17.4"
  subscription_chart_location = "${path.module}/chart/subscription"
  namespace                   = "openshift-cnv" # This is hard-coded because using any other namespace will break the virtualization.
}

resource "helm_release" "subscription" {
  depends_on       = [null_resource.enable_catalog_source]
  name             = "${data.ibm_container_vpc_cluster.cluster.name}-subscription"
  chart            = local.subscription_chart_location
  namespace        = local.namespace
  create_namespace = true
  timeout          = 1200
  wait             = true
  recreate_pods    = true
  force_update     = true

  set {
    name  = "subscription.version"
    type  = "string"
    value = local.subscription_version
  }

  provisioner "local-exec" {
    command     = "${path.module}/scripts/confirm-rollout-status.sh hco-operator ${local.namespace}"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}

#########################################################################################################################
# Deploying the OpenShift Virtualization Operator
########################################################################################################################

locals {
  operator_chart_location = "${path.module}/chart/operator"
}

resource "time_sleep" "wait_for_subscription" {
  depends_on = [helm_release.subscription]

  create_duration = "60s"
}

resource "helm_release" "operator" {
  depends_on       = [time_sleep.wait_for_subscription]
  name             = "${data.ibm_container_vpc_cluster.cluster.name}-operator"
  chart            = local.operator_chart_location
  namespace        = local.namespace
  create_namespace = false
  timeout          = 1200
  wait             = true
  recreate_pods    = true
  force_update     = true
}

# Wait until StorageProfile resources are created for each StorageClass.
resource "time_sleep" "wait_for_storage_profile" {
  depends_on = [helm_release.operator]

  create_duration = "240s"
}

resource "null_resource" "update_storage_profile" {
  depends_on = [time_sleep.wait_for_storage_profile]
  provisioner "local-exec" {
    command     = "${path.module}/scripts/update_storage_profile.sh ${var.vpc_file_default_storage_class}"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}
