PWD=$(shell pwd)

CLUSTER_NAME ?= "my-cluster"
REGION ?= "nyc1"
K8S_VERSION ?= "1.20.11-do.0"
NODE_COUNT ?= 2
NODE_SIZE ?= "s-1vcpu-2gb"
# terraform commands to create k8s cluster in do
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
	@podman run -v $(PWD)/infra:/infra -w /infra \
	hashicorp/terraform:light output -json > out.json
create-kubeconfig: output
	@mkdir -p ~/.kube
	@cat out.json | jq .k8s_raw_config.value | sed 's/\\n/\n/g' | sed 's/"//g' > ~/.kube/$(CLUSTER_NAME)
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
# generate ssh key and upload to github
generate-ssh-key:
	ssh-keygen -t rsa -b 2048 -N "" -f ~/.ssh/$(SSH-KEY-NAME)
# install k8s tools
install-metrics-server: create-kubeconfig
        @podman run -v ~/.kube/$(CLUSTER_NAME):/.kube/config \
        bitnami/kubectl:latest apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# deploy locust cluster in k8s
create-configmap: create-kubeconfig
	@podman run -v ~/.kube/$(CLUSTER_NAME):/.kube/config \
		-v $(PWD):/files \
	bitnami/kubectl:latest create configmap locust-file --from-file=/files/locustfile.py

install-locust-helm-package:
	podman run \
		-v ~/.kube:/root/.kube \
		-v ~/.helm:/root/.helm \
		-v ~/.config/helm:/root/.config/helm \
		-v ~/.cache/helm:/root/.cache/helm \
		alpine/helm repo add deliveryhero https://charts.deliveryhero.io/

deploy-locust: install-locust-helm-package
	podman run \
		-v ~/.kube:/root/.kube \
		-v ~/.helm:/root/.helm \
		-v ~/.config/helm:/root/.config/helm \
		-v ~/.cache/helm:/root/.cache/helm \
		alpine/helm upgrade locust deliveryhero/locust \
		--atomic --force --install \
		--kubeconfig /root/.kube/$(CLUSTER_NAME) \
		--set loadtest.name=my-loadtest \
		--set loadtest.locust_locustfile_configmap=my-loadtest-locustfile \
		--set loadtest.locust_lib_configmap=my-loadtest-lib \
		--set worker.replicas=10
