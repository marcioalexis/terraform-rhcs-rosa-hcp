locals {
  path           = coalesce(var.path, "/")
  aws_account_id = var.aws_account_id == null ? data.aws_caller_identity.current[0].account_id : var.aws_account_id
  sts_roles = {
    role_arn = var.installer_role_arn != null ? (
      var.installer_role_arn
      ) : (
      "arn:aws:iam::${local.aws_account_id}:role${local.path}${var.account_role_prefix}-HCP-ROSA-Installer-Role"
    ),
    support_role_arn = var.support_role_arn != null ? (
      var.support_role_arn
      ) : (
      "arn:aws:iam::${local.aws_account_id}:role${local.path}${var.account_role_prefix}-HCP-ROSA-Support-Role"
    ),
    instance_iam_roles = {
      worker_role_arn = var.worker_role_arn != null ? (
        var.worker_role_arn
        ) : (
        "arn:aws:iam::${local.aws_account_id}:role${local.path}${var.account_role_prefix}-HCP-ROSA-Worker-Role"
      ),
    },
    operator_role_prefix = var.operator_role_prefix,
    oidc_config_id       = var.oidc_config_id
  }
  aws_account_arn   = var.aws_account_arn == null ? data.aws_caller_identity.current[0].arn : var.aws_account_arn
  create_admin_user = var.create_admin_user
  admin_credentials = var.admin_credentials_username == null && var.admin_credentials_password == null ? (
    null
    ) : (
    { username = var.admin_credentials_username, password = var.admin_credentials_password }
  )
}


resource "rhcs_hcp_cluster_autoscaler" "cluster_autoscaler" {
  count = var.cluster_autoscaler_enabled ? 1 : 0

  cluster                 = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.id
  max_pod_grace_period    = var.autoscaler_max_pod_grace_period
  pod_priority_threshold  = var.autoscaler_pod_priority_threshold
  max_node_provision_time = var.autoscaler_max_node_provision_time

  resource_limits = {
    max_nodes_total = var.autoscaler_max_nodes_total
  }
}

resource "rhcs_hcp_default_ingress" "default_ingress" {
  depends_on = [rhcs_cluster_rosa_hcp.rosa_hcp_cluster]
  count   = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.id != "" ? 1 : 0
  cluster = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.id
  listening_method = var.default_ingress_listening_method != "" ? (
    var.default_ingress_listening_method) : (
    var.private ? "internal" : "external"
  )
}


data "aws_caller_identity" "current" {
  count = var.aws_account_id == null || var.aws_account_arn == null ? 1 : 0
}

data "aws_region" "current" {
  count = var.aws_region == null ? 1 : 0
}

data "aws_availability_zones" "available" {
  count = length(var.aws_availability_zones) > 0 ? 0 : 1
  state = "available"

  # New configuration to exclude Local Zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_subnet" "provided_subnet" {
  count = length(var.aws_subnet_ids)

  id = var.aws_subnet_ids[count.index]
}
