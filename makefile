PWD=$(shell pwd)

CLUSTER_NAME ?= "my-cluster"
REGION ?= "nyc1"
K8S_VERSION ?= "1.20.11-do.0"
NODE_COUNT ?= 2
NODE_SIZE ?= "s-1vcpu-2gb"
deploy-helm-package:
	podman run -w /helm-package \
		-v $PWD/helm-package:/helm-package \
		-v ~/.kube:/root/.kube \
		alpine/helm install --atomic --create-namespace -o json --wait -n $(namespace) \
		--set url=$(url),rampage=$(rampage),timeout=$(timeout),users=$(users) /helm-package
init:
	podman run -v $(PWD)/infra:/infra -w /infra hashicorp/terraform:light init
plan:
	podman run -v $(PWD)/infra:/infra -w /infra \
		-e DIGITALOCEAN_TOKEN=$(DIGITALOCEAN_TOKEN) \
		-e TF_VAR_CLUSTER_NAME=$(CLUSTER_NAME) \
		-e TF_VAR_REGION=$(REGION) \
		-e TF_VAR_K8S_VERSION=$(K8S_VERSION) \
		-e TF_VAR_NODE_COUNT=$(NODE_COUNT) \
		-e TF_VAR_NODE_SIZE=$(NODE_SIZE) \
	hashicorp/terraform:light plan
apply: checkToken
	podman run -v $(PWD)/infra:/infra -w /infra \
		-e DIGITALOCEAN_TOKEN=$(DIGITALOCEAN_TOKEN) \
		-e TF_VAR_CLUSTER_NAME=$(CLUSTER_NAME) \
		-e TF_VAR_REGION=$(REGION) \
		-e TF_VAR_K8S_VERSION=$(K8S_VERSION) \
		-e TF_VAR_NODE_COUNT=$(NODE_COUNT) \
		-e TF_VAR_NODE_SIZE=$(NODE_SIZE) \
	hashicorp/terraform:light apply -auto-approve
output:
	podman run -v $(PWD)/infra:/infra -w /infra \
	hashicorp/terraform:light output -json > out.json
create-kubeconfig: output
	mkdir -p ~/.kube
	cat out.json | jq .k8s_raw_config.value | sed 's/\\n/\n/g' > ~/.kube/$(CLUSTER_NAME)
destroy: checkToken
	podman run -v $(PWD)/infra:/infra -w /infra \
		-e DIGITALOCEAN_TOKEN=$(DIGITALOCEAN_TOKEN) \
		-e TF_VAR_CLUSTER_NAME=$(CLUSTER_NAME) \
		-e TF_VAR_REGION=$(REGION) \
		-e TF_VAR_K8S_VERSION=$(K8S_VERSION) \
		-e TF_VAR_NODE_COUNT=$(NODE_COUNT) \
		-e TF_VAR_NODE_SIZE=$(NODE_SIZE) \
	hashicorp/terraform:light destroy -auto-approve
	rm out.json ~/.kube/$(CLUSTER_NAME)
checkToken:
ifdef DIGITALOCEAN_TOKEN
	echo "Token set success!"
else
	echo "Token not set :("
	exit 1
endif
