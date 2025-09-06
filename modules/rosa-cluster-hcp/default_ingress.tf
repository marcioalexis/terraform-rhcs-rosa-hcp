resource "rhcs_hcp_default_ingress" "default_ingress" {
  depends_on = [rhcs_cluster_rosa_hcp.rosa_hcp_cluster]

  cluster = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.id

  listening_method = var.default_ingress_listening_method != "" ? (
    var.default_ingress_listening_method
  ) : (
    var.private ? "internal" : "external"
  )
}
