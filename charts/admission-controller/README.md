---
title: Admission Controller
sidebar_position: 4
---

# admission-controller

![Version: 0.1.4-1](https://img.shields.io/badge/Version-0.1.4--1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.4-1](https://img.shields.io/badge/AppVersion-0.1.4--1-informational?style=flat-square)

**Homepage:** <https://scribesecurity.com>

# Admission Controller
The Scribe Admission Controller is a component in your Kubernetes cluster that enforces policy decisions to validate the integrity of your supply chain. <br />
It does this by checking resources that are being created in the cluster against admission rules, which determine if the resources are allowed. <br />
This document provides instructions for installing and integrating the admission controller in your cluster, including options for both Scribe service and OCI registry integration. <br />
The admission controller is built with Helm and is supported by the Scribe security team. To enable the admission logic, simply add the `admission.scribe.dev/include` label to a namespace. <br />

## Policy engine
Valint `admission controller` manages verification of evidence using a policy engine. The policy engine uses different `evidence stores` to store and provide `evidence` for the policy engine to query on any required `evidence` required to comply with across your supply chain.

Each policy proposes to enforce a set of rules on the targets produced by your supply chain. Policies produce a result, including compliance results as well as `evidence` referenced in the verification.

# Policy engine
At the heart of Valint lies the `policy engine`, which enforces a set of rules on the `evidence` produced by your supply chain. The policy engine accesses different `evidence stores` to retrieve and store `evidence` for compliance verification throughout your supply chain. <br />
Each `policy` proposes to enforce a set of rules your supply chain must comply with. 

## Evidence:
Evidence can refer to metadata collected about artifacts, reports, events or settings produced or provided to your supply chain.
Evidence can be either signed (attestations) or unsigned (statements).

## Evidence:
Evidence can refer to metadata collected about artifacts, reports, events or settings produced or provided to your supply chain.
Evidence can be either signed (attestations) or unsigned (statements).

### Evidence formats
`admission controller` supports following evidence formats.

| Format | alias | Description | signed |
| --- | --- | --- | --- |
| statement-CycloneDX-json | statement | In-toto Statement | no |
| attest-CycloneDX-json | attest | In-toto Attestation | yes |
| statement-slsa |  | In-toto Statement | no |
| attest-slsa |  | In-toto Attestations | yes |

> Note using pure `cyclonedx-json` format is currently supported by the admission.

### Evidence Stores
Each storer can be used to store, find and download evidence, unifying all the supply chain evidence into a system is an important part to be able to query any subset for policy validation.

| Type  | Description | requirement |
| --- | --- | --- |
| OCI | Evidence is stored on a remote OCI registry | access to a OCI registry |
| scribe | Evidence is stored on scribe service | scribe credentials |

> For details, see [evidence stores integrations](#evidence-stores-integration) section

## Installing `admission-controller`
The admission-controller is installed using Helm. <br />
Here are the steps to add the chart repository and install the admission-controller/

1. Add the chart repository:
```bash
helm repo add scribe https://scribe-security.github.io/helm-charts
helm repo update
kubectl create namespace scribe
```

>You can inspect the admission version by running the following command
 `helm search repo scribe/admission-controller`

2. Install the admission-controller:
```bash
helm install admission-controller -n scribe scribe/admission-controller
```

## Evidence Stores Integration
There are two evidence storer options for the admission-controller:
- Scribe service store
- OCI registry store

## Scribe service store
Admission supports both storage and verification flows for `attestations`  and `statement` objects utilizing Scribe Hub as evidence store.

### Before you begin
Integrating Scribe Hub with admission controller requires the following credentials that are found in the **Integrations** page. (In your **[Scribe Hub](https://prod.hub.scribesecurity.com/ "Scribe Hub Link")** go to **integrations**)

* **Client ID**
* **Client Secret**

<img src='../../img/ci/integrations-secrets.jpg' alt='Scribe Integration Secrets' width='70%' min-width='400px'/>

### Procedure
To install the admission-controller with Scribe service integration:
```bash
  helm install admission-controller -n scribe scribe/admission-controller \
    --set scribe.auth.client_id=$(CLIENT_ID) \
    --set scribe.auth.client_secret=$(CLIENT_SECRET)
```

> Credentials will be stored as a secret named `admission-controller-scribe-cred`.

## OCI registry integration
Admission supports both storage and verification flows for `attestations` and `statement` objects using an OCI registry as an evidence store. <br />
Using OCI registry as an evidence store allows you to upload and verify evidence across your supply chain in a seamless manner.

### Before you begin
- Write access to upload evidence using the `valint` tool
- Read access to download evidence for the admission controller
- Evidence can be stored in any accessible registry

### Procedure
1. Install admission with evidence store [oci-repo].
    - [oci-repo] is the URL of the OCI repository where all evidence will be uploaded.
    - For image targets only: Attach the evidence to the same repo as the uploaded image.
      Example: If you upload an image `example/my_image:latest`, read access is required for `example/my_image` (oci-repo).
     
2. If [oci-repo] is a private registry, attach permissions to the admission with the following steps:
    1. Create a secret:
    ```bash
    kubectl create secret docker-registry [secret-name] --docker-server=[registry_url] --docker-username=[username] --docker-password=[access_token] -n scribe
    ```
    > Note: The `oci-repo` must be hosted on the `oci-url` you're adding the secret to.
    Example: `oci-repo=my_org.jfrog.io/docker-public-local` while `oci-url=my_org.jfrog.io`
     
3. Install admission with an OCI registry as the evidence store:
    ```bash
    helm install admission-controller scribe/admission-controller -n scribe \
    --set config.attest.cocosign.storer.OCI.enable=true \
    --set config.attest.cocosign.storer.OCI.repo=[oci-repo] \
    --set imagePullSecrets=[secret-name]
    ```
  > Note `oci-repo` and `secret-name` need to be replaced with values.

# Enabling Scribe Admission
To enable Scribe admission in a namespace, add the label `admission.scribe.dev/include` to the namespace.
Scribe admission logic will be triggered on all resources within the namespace that match any of the regular expressions specified by the `glob` field.

In order to enable admission on a namespace you must add `admission.scribe.dev/include` label to it.
Namespaces will trigger Scribe admission logic on all its resources **matching* any regular expression specified by the `glob` fields.

## Adding the admission label to a namespace
Use the following command to add the `admission.scribe.dev/include` label to a namespace:

#### Command
```bash
kubectl label namespace my-namespace admission.scribe.dev/include=true
```

#### Configuration
```yaml
apiVersion: v1
kind: Namespace
metadata:
  labels:
    admission.scribe.dev/include: "true"
  name: my-namespace
```

## Adding image `glob`
To enable admission for a specific set of images, add regular expressions to match the image names.
Regular expressions uses the perl regular expression format.

#### Command
```bash
helm upgrade admission-controller scribe/admission-controller -n scribe \
    --set config.admission.glob={[list of regular expressions]} -n scribe
```
> For example:
This will match images that have the string nginx or busybox in their name.
```bash
helm upgrade admission-controller scribe/admission-controller -n scribe \
    --set config.admission.glob={\.\*busybox:\.\*,\.\*nginx:\.\*} -n scribe
```
Note the escaping of `.` and `*` when using `Bash` shell.

#### Configuration
```yaml
...
config:
  admission:
    glob: [list of regular expressions]
```
> For example:
> This will match images that have the string nginx or busybox in their name.
```yaml
...
config:
  admission:
    # -- Select admitted images by regex
    glob:
      - .*nginx:.*
      - .*busybox:.*
```

# Setting Evidence type
Admission supports both verification flows for `attestations` (signed)  and `statement` (unsigned) objects utilizing OCI registry or Scribe service as an evidence store.

>By default, admission will require signed evidence (`config.verify.input-format=attest`).

#### Command
```bash
helm upgrade admission-controller scribe/admission-controller -n scribe \
    --set config.verify.input-format=[format]
```

#### Configuration
```yaml
...
config:
  verify:
    # -- Select required evidence type
    input-format: [format]
```

### Supported format tables
The following table lists the supported evidence types:

| Format | alias | Description | signed
| --- | --- | --- | --- |
| statement-cyclonedx-json | statement | In-toto Statement | no |
| attest-cyclonedx-json | attest | In-toto Attestation | yes |
| statement-slsa |  | In-toto Statement | no |
| attest-slsa |  | In-toto Attestations | yes |

Aliases:
* statement=statement-cyclonedx-json
* attest=attest-cyclonedx-json

# Uploading evidence
After installing the admission you you want to upload evidence .

## Upload to Scribe service
```bash
# Generating evidence, storing on [my_repo] OCI repo.
valint bom [target] -o [attest, statement, attest-slsa,statement-slsa] -E \
  -U $SCRIBE_CLIENT_ID \
  -P $SCRIBE_CLIENT_SECRET
```

## Upload to OCI registry
```bash
# Generating evidence, storing on [my_repo] OCI repo.
valint bom [target] -o [attest, statement, attest-slsa,statement-slsa] --oci --oci-repo=[my_repo]
```

> For image targets **only** you may attach the evidence in the same repo as the image.

```bash
valint bom [image] -o [attest, statement, attest-slsa,statement-slsa] --oci
```

## Uninstall `admission-controller`
Uninstall the chart by running

```bash
helm uninstall -n scribe admission-controller
```

## Configuration values
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| config.admission.glob | list | `[]` | Select admitted images by regex |
| config.attest.cocosign.storer.OCI.enable | bool | `true` | OCI evidence enable |
| config.attest.cocosign.storer.OCI.repo | string | `""` | OCI evidence repo location  |
| config.attest.default | string | `"sigstore"` | Signature verification type |
| config.context.name | string | `""` | Scribe Project Key |
| config.verify.input-format | string | `"attest"` | Evidence format |
| imagePullSecrets | list | `[]` | OCI evidence store secret name |
| scribe.auth.client_id | string | `""` | Scribe Client ID |
| scribe.auth.client_secret | string | `""` | Scribe Client Secret |
| scribe.service.enable | bool | `false` | Scribe Client Enable |

For the full list of available values see the following section.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| commonNodeSelector | object | `{}` |  |
| commonTolerations | list | `[]` |  |
| config.admission.glob | list | `[]` | Select admitted images by regex |
| config.attest.cocosign.storer.OCI.enable | bool | `true` | OCI evidence enable |
| config.attest.cocosign.storer.OCI.repo | string | `""` | OCI evidence repo location  |
| config.attest.default | string | `"sigstore"` | Signature verification type |
| config.context.name | string | `""` | Scribe Project Key |
| config.verify.input-format | string | `"attest"` | Evidence format |
| imagePullSecrets | list | `[]` | OCI evidence store secret name |
| scribe.auth.client_id | string | `""` | Scribe Client ID |
| scribe.auth.client_secret | string | `""` | Scribe Client Secret |
| scribe.service.enable | bool | `false` | Scribe Client Enable |
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