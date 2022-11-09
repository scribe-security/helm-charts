BOLD := $(shell tput -T linux bold)
PURPLE := $(shell tput -T linux setaf 5)
GREEN := $(shell tput -T linux setaf 2)
CYAN := $(shell tput -T linux setaf 6)
RED := $(shell tput -T linux setaf 1)
RESET := $(shell tput -T linux sgr0)
TITLE := $(BOLD)$(PURPLE)
SUCCESS := $(BOLD)$(GREEN)
NAMESPACE=scribe
NAME=admission-controller
ADMISSION_IMAGE=scribesecuriy.jfrog.io/scribe-docker-public-local/valint
ADMISSION_PRE_RELASE=$(ADMISSION_IMAGE):dev-latest-admission
## Build variables

ifeq "$(strip $(VERSION))" ""
 override VERSION = $(shell git describe --always --tags --dirty)
endif

# used to generate the changelog from the second to last tag to the current tag (used in the release pipeline when the release tag is in place)
LAST_TAG := $(shell git describe --always --abbrev=0 --tags $(shell git rev-list --tags --max-count=1))
SECOND_TO_LAST_TAG := $(shell git describe --always --abbrev=0 --tags $(shell git rev-list --tags --skip=1 --max-count=1))

## Variable assertions

define title
    @printf '$(TITLE)$(1)$(RESET)\n'
endef

## Tasks
.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(BOLD)$(CYAN)%-25s$(RESET)%s\n", $$1, $$2}'

.PHONY: namespace
install_namespace:  ## Create admission namespace
	@kubectl create namespace $(NAMESPACE)

.PHONY: install
install: ## Install admission (release helm)
	@helm install --debug  \
		--set scribe.auth.client_id=$(SCRIBE_CLIENT_ID) \
		--set scribe.auth.client_secret=$(SCRIBE_CLIENT_SECRET) \
		$(NAME) -n $(NAMESPACE) scribe/$(NAME)

.PHONY: install_local
install_local: ## Install admission
	@helm install --debug  \
		--set scribe.auth.client_id=$(SCRIBE_CLIENT_ID) \
		--set scribe.auth.client_secret=$(SCRIBE_CLIENT_SECRET) \
		$(NAME) -n $(NAMESPACE) ./charts/$(NAME) --devel

.PHONY: bootstrap
bootstrap:
	@helm plugin install https://github.com/karuppiah7890/helm-schema-gen.git
	@GO111MODULE=on go get github.com/norwoodj/helm-docs/cmd/helm-docs

.PHONY: gen_schema
gen_docs:
	@helm schema-gen charts/$(NAME)/values.yaml > charts/$(NAME)/values.schema.json 
	@helm-docs -g charts/admission-controller -t charts/admission-controller/README.md.gotmp

.PHONY: minikube_start
minikube_start: ## Install admission on minikube
	@minikube start  --container-runtime=docker --cpus 8 --memory 4gb --disk-size=40g --kubernetes-version=1.24.0

.PHONY: minikube_load
minikube_load: ## Load admission to minikube
	@minikube image load scribesecuriy.jfrog.io/scribe-docker-public-local/valint:latest

.PHONY: minikube_docker
minikube_docker: ## Map local daemon to minikube
	$(eval $(shell minikube -p minikube docker-env 1>&2))

.PHONY: minikube_install_local
minikube_install_local: clean install_local ## Install admission on minikube (Local helm)

.PHONY: minikube_install
minikube_install: clean install ## Install admission on minikube (release helm)

.PHONY: minikube_dashboard
minikube_dashboard: ## Minikube dashboard
	@minikube dashboard

.PHONY: logs
logs: ## Read admission logs
	@kubectl logs --all-containers=true --tail=-1 -l app.kubernetes.io/name=$(NAME) -n  $(NAMESPACE)  | grep '^{' | jq -C -r '.' | sed 's/\\n/\n/g; s/\\t/\t/g'

.PHONY: clean_namespace
clean_namespace: clean ## Delete admission namespace
	@kubectl delete namespace $(NAMESPACE)  || true

.PHONY: clean
clean: ## Uninstall admission
	@helm uninstall $(NAME) --debug -n $(NAMESPACE) || true
	$(shell kubectl --namespace $(NAMESPACE) delete "$$(kubectl api-resources --namespaced=true --verbs=delete -o name | tr '\n' ',' | sed -e 's/,$$//')" --all)  || true

.PHONY: test
accept_test: ## Test admission
	@kubectl create namespace test || true
	@kubectl label namespace test admission.scribe.dev/include=true
	@kubectl apply -f charts/admission-controller/examples/accept_deployment.yaml -n test

.PHONY: test
deny_test: ## Test admission
	@kubectl create namespace test || true
	@kubectl label namespace test admission.scribe.dev/include=true
	@kubectl apply -f charts/admission-controller/examples/deny_deployment.yaml -n test


.PHONY: clean_test
clean_test: ## Clean test admission
	@kubectl delete -f charts/admission-controller/examples/accept_deployment.yaml -n test || true
	@kubectl delete -f charts/admission-controller/examples/deny_deployment.yaml -n test || true


.PHONY: sync_pre_release
sync_pre_release:
	$(shell bash ./scripts/sync_pre_relase.sh $(ADMISSION_PRE_RELASE)) || true


list_vesrsions:
	helm search repo scribe/admission-controller --devel --versions