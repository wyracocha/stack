resource "digitalocean_kubernetes_cluster" "cluster" {
	name = var.CLUSTER_NAME
	region = var.REGION
	version = var.K8S_VERSION
	
	node_pool {
		name = "worker-pool"
		size = var.NODE_SIZE
		node_count = var.NODE_COUNT
	}

	auto_upgrade = false
}
