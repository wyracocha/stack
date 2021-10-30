variable CLUSTER_NAME {
	description = "digitalocean cluster name"
}
variable REGION {
	description = "digitalocean region"
}
variable K8S_VERSION {
	description = "kubernetes cluster version"
}
variable NODE_COUNT {
	type = number
	description = "total droplets to be created"
}
variable NODE_SIZE {
	description = "droplet size"
}
