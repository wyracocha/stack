output k8s_raw_config {
	value = digitalocean_kubernetes_cluster.cluster.kube_config[0].raw_config
	sensitive = true
}

output k8s_ca_cert { 
	sensitive = true
        value = digitalocean_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate
}

output k8s_client_cert {
	sensitive = true 
        value = digitalocean_kubernetes_cluster.cluster.kube_config[0].client_certificate
}


