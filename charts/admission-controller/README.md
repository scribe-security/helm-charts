---
title: Admission Controller
sidebar_position: 4
---

# admission-controller

![Version: 0.1.4-1](https://img.shields.io/badge/Version-0.1.4--1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.4-1](https://img.shields.io/badge/AppVersion-0.1.4--1-informational?style=flat-square)

Scribe admissions helm chart, Validate the integrity of your supply chain.

**Homepage:** <https://scribesecurity.com>

## Before you begin
Integrating Scribe Hub with Jenkins requires the following credentials that are found in the product setup dialog (In your **[Scribe Hub](https://prod.hub.scribesecurity.com/ "Scribe Hub Link")** go to Home>Products>[$product]>Setup)

* **product key**
* **client id**
* **client secret**

>Note that the product key is unique per product, while the client id and secret are unique for your account.

## Procedure

### Installing `admission-controller`
* The following commands can be used to add the chart repository to dedicated namespace:

```bash
helm repo add scribe https://scribe-security.github.io/helm-charts
helm repo update
kubectl create namespace scribe
```

* To install the helm chart with default values run the following command. \
Credentials will be stored as a secret named `admission-controller-scribe-cred`.
```bash
helm install scribe -n scribe scribe/admission-controller \
		--set scribe.auth.client_id=$(CLIENT_ID) \
		--set scribe.auth.client_secret=$(CLIENT_SECRET) \
		--set context.name=$(PRODUCT_KEY)
		
```
The [Values](#Values) section describes the configuration options for this chart.

### Enabling Scribe Admission - `admission.scribe.dev/include`

In order to enable admission on a namespace you must add `admission.scribe.dev/include` label to it.
Namespaces will trigger Scribe admission logic on all its resources.

> Note: Resources can further limited by image `glob` selector flag.

Command:
```bash
kubectl label namespace my-namespace admission.scribe.dev/include=true
```

Configuration:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  labels:
    admission.scribe.dev/include: "true"
  name: my-namespace
```

## Uninstall `admission-controller`
Uninstall the chart by running

```bash
helm uninstall -n scribe admission-controller
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| commonNodeSelector | object | `{}` |  |
| commonTolerations | list | `[]` |  |
| config.admission.glob | list | `[]` | Select admitted images by regex |
| config.attest.cocosign.storer.OCI.enable | bool | `true` |  |
| config.attest.default | string | `"sigstore"` |  |
| config.context.name | string | `""` | Scribe Project Key |
| config.verify.input-format | string | `"attest"` | Evidence format |
| imagePullSecrets | list | `[]` | OCI evidence store secret name |
| scribe.auth.client_id | string | `""` | Scribe Client ID |
| scribe.auth.client_secret | string | `""` | Scribe Client Secret |
| scribe.service.enable | bool | `false` |  |
| serviceMonitor.enabled | bool | `false` |  |
| webhook.env | object | `{}` |  |
| webhook.extraArgs.structured | bool | `true` |  |
| webhook.extraArgs.verbose | int | `2` |  |
| webhook.image.pullPolicy | string | `"IfNotPresent"` |  |
| webhook.image.repository | string | `"scribesecuriy.jfrog.io/scribe-docker-public-local/valint"` |  |
| webhook.image.version | string | `"v0.1.4-1-admission"` |  |
| webhook.name | string | `"webhook"` |  |
| webhook.podSecurityContext.allowPrivilegeEscalation | bool | `false` |  |
| webhook.podSecurityContext.capabilities.drop[0] | string | `"all"` |  |
| webhook.podSecurityContext.enabled | bool | `true` |  |
| webhook.podSecurityContext.readOnlyRootFilesystem | bool | `true` |  |
| webhook.podSecurityContext.runAsUser | int | `1000` |  |
| webhook.replicaCount | int | `1` |  |
| webhook.secretName | string | `""` |  |
| webhook.securityContext.enabled | bool | `false` |  |
| webhook.securityContext.runAsUser | int | `65532` |  |
| webhook.service.annotations | object | `{}` |  |
| webhook.service.port | int | `443` |  |
| webhook.service.type | string | `"ClusterIP"` |  |
| webhook.serviceAccount.annotations | object | `{}` |  |
| webhook.webhookName | string | `"admission.scribe.dev"` |  |
