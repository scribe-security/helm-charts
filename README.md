title: Helm
author: mikey strauss - Scribe
date: Jun 14, 2022
geometry: margin=2cm
---

# Scribe Helm Charts
Scribe-provided charts allow you to manage and verifing the integrity of your supply chain.

## Supported charts
* [Attestation](./charts/attstore/README.md): Scribe attestation helm chart, Attest the integrity of your supply chain.

* [Integrity admission](./charts/admission-controller/README.md): Scribe admissions helm chart, Validate the integrity of your supply chain.

## Installing Charts
```
helm repo add scribe https://scribe-security.github.io/helm-charts
helm repo update
helm search repo scribe
```


### Installing admission
```
kubectl create namespace scribe
helm install scribe/admission-controller -n scribe \
    	--set scribe.auth.client_id=$(SCRIBE_CLIENT_ID) \
		--set scribe.auth.client_secret=$(SCRIBE_CLIENT_SECRET)
```