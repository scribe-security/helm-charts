---
sidebar_label: "K8s Admission Controller"
title: K8s Admission Controller - Coming Soon!
sidebar_position: 5
toc_min_heading_level: 2
toc_max_heading_level: 5
---

<!-- # K8s Admission Controller - Coming Soon! -->
![Coming Soon](/img/help/coming-soon.jpg)


![Version: 0.1.4-1](https://img.shields.io/badge/Version-0.1.4--1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.4-1](https://img.shields.io/badge/AppVersion-0.1.4--1-informational?style=flat-square)

### Introduction to K8s Admission Controller

The Scribe Admission Controller is a component in your Kubernetes cluster that enforces policy decisions to validate the integrity of your supply chain.  

It does this by checking resources that are being created in the cluster against admission compliance requirements, which determine if the resources are allowed.  

This document provides instructions for installing and integrating the admission controller in your cluster, including options for both Scribe service and OCI registry integration.  

The admission controller is built with Helm and is supported by the Scribe security team. To enable the admission logic, simply add the `admission.scribe.dev/include` label to a namespace. 

<!-- ### Supported K8s platforms

### Prerequisites -->

### Installing the K8s Admission Controller

The admission-controller is installed using Helm.  

Here are the steps to add the chart repository and install the admission-controller/

1. Add the chart repository:
```bash
helm repo add scribe https://scribe-security.github.io/helm-charts
helm repo update
kubectl create namespace scribe
helm install admission-controller scribe/admission-controller -n scribe
```
> For detailed integration option, see **[evidence stores](#evidence-stores)** section.

### How the Admission Controller works

Valint `admission controller` manages verification of evidence using a policy engine. The policy engine uses different `evidence stores` to store and provide `evidence` for the policy engine to query on any required `evidence` required to comply with across your supply chain.

Each policy proposes to enforce a set of policies on the targets produced by your supply chain. Policies produce a result, including compliance results as well as `evidence` referenced in the verification.

# Policy engine
At the heart of Valint lies the `policy engine`, which enforces a set of policies on the `evidence` produced by your supply chain. The policy engine accesses different `evidence stores` to retrieve and store `evidence` for compliance verification throughout your supply chain.  

Each `policy` proposes to enforce a set of policy modules your supply chain must comply with. 

### Evidence Stores
Each storer can be used to store, find and download evidence, unifying all the supply chain evidence into a system is an important part to be able to query any subset for policy validation.

| Type  | Description | requirement |
| --- | --- | --- |
| scribe | Evidence is stored on scribe service | scribe credentials |
| OCI | Evidence is stored on a remote OCI registry | access to a OCI registry |

## Scribe Evidence store
Scribe evidence store allows you store evidence using scribe Service.

Related values:
> Note the values set:
>* `scribe.auth.client_id`
>* `scribe.auth.client_secret`
>* `scribe.service.enable`

* To install the admission-controller with Scribe service integration:
```bash
  helm install admission-controller -n scribe scribe/admission-controller \
    --set scribe.service.enable=true \
    --set scribe.auth.client_id=$(CLIENT_ID) \
    --set scribe.auth.client_secret=$(CLIENT_SECRET)
```
> Credentials will be stored as a secret named `admission-controller-scribe-cred`.


### Alternative evidence stores

> You can learn more about alternative stores **[here](https://scribe-security.github.io/docs/integrating-scribe/other-evidence-stores)**.

<details>
  <summary> <b> OCI Evidence store </b></summary>
Admission supports both storage and verification flows for `attestations` and `statement` objects using an OCI registry as an evidence store. <br />
Using OCI registry as an evidence store allows you to upload and verify evidence across your supply chain in a seamless manner.

Related flags:
>* `config.attest.cocosign.storer.OCI.enable` - Enable OCI store.
>* `config.attest.cocosign.storer.OCI.repo` - Evidence store location.
>* `imagePullSecrets` - Secret name for private registry.

### Dockerhub limitation
Dockerhub does not support the subpath format, `oci-repo` should be set to your Dockerhub Username.

> Some registries like Jfrog allow multi layer format for repo names such as , `my_org.jfrog.io/policies/attestations`.

### Before you begin
- Write access to upload evidence using the `valint` tool.
- Read access to download evidence for the admission controller.
- Evidence can be stored in any accessible OCI registry.

1. Install admission with evidence store [oci-repo].
    - [oci-repo] is the URL of the OCI repository where all evidence will be uploaded.
    - For image targets only: Attach the evidence to the same repo as the uploaded image.
      Example: If you upload an image `example/my_image:latest`, read access is required for `example/my_image` (oci-repo).
     
2. If [oci-repo] is a private registry, attach permissions to the admission with the following steps:
    1. Create a secret:
    ```bash
    kubectl create secret docker-registry [secret-name] --docker-server=[registry_url] --docker-username=[username] --docker-password=[access_token] -n scribe
    ```
     
3. Install admission with an OCI registry as the evidence store:
    ```bash
    helm install admission-controller scribe/admission-controller -n scribe \
    --set config.attest.cocosign.storer.OCI.enable=true \
    --set config.attest.cocosign.storer.OCI.repo=[oci-repo] \
    --set imagePullSecrets=[secret-name]
    ```
  > Note `oci-repo` and `secret-name` need to be replaced with values.
  
</details>


### Enabling Scribe Admission
To enable Scribe admission in a namespace, add the label `admission.scribe.dev/include` to the namespace.
Scribe admission logic will be triggered on all resources within the namespace that match any of the regular expressions specified by the `glob` field.

In order to enable admission on a namespace you must add `admission.scribe.dev/include` label to it.
Namespaces will trigger Scribe admission logic on all its resources **matching* any regular expression specified by the `glob` fields.

### Adding the admission label to a namespace
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

### Adding image `glob`
To enable admission for a specific set of images, add regular expressions to match the image names.
Regular expressions uses the perl regular expression format.

#### Command
```bash
helm upgrade admission-controller scribe/admission-controller --reuse-values -n scribe \
    --set config.admission.glob={[list of regular expressions]}
```
> For example:
This will match images that have the string nginx or busybox in their name.
```bash
helm upgrade admission-controller scribe/admission-controller --reuse-values -n scribe \
    --set config.admission.glob={\.\*busybox:\.\*,\.\*nginx:\.\*} -n scribe
```

> Note the escaping of `.` and `*` when using `Bash` shell.

> `--reuse-values` so that the values are not reset.

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

### Setting Evidence type
Admission supports both verification flows for `attestations` (signed)  and `statement` (unsigned) objects utilizing OCI registry or Scribe service as an evidence store.

> By default, admission will require signed evidence (`config.verify.input-format=attest`).

#### Command
```bash
helm upgrade admission-controller scribe/admission-controller --reuse-values -n scribe \
    --set config.verify.input-format=[format]
```

> `--reuse-values` so that the values are not reset.

#### Configuration
```yaml
...
config:
  verify:
    # -- Select required evidence type
    input-format: [format]
```

### Uploading evidence
After installing the admission you you want to upload evidence .

### Upload to Scribe service
```bash
# Generating evidence, storing on [my_repo] OCI repo.
valint [bom,slsa,evidence] [target] -o [attest, statement] \
  -P $SCRIBE_TOKEN
```

### Upload to OCI registry
```bash
# Generating evidence, storing on [my_repo] OCI repo.
valint [bom,slsa,evidence] [target] -o [attest, statement] --oci --oci-repo=[my_repo]
```

> For image targets **only** you may attach the evidence in the same repo as the image.

```bash
valint [bom,slsa,evidence] [image] -o [attest, statement] --oci
```

### Uninstall `admission-controller`
Uninstall the chart by running

```bash
helm uninstall -n scribe admission-controller
```

### Admission Controller Optional Flags

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
| scribe.auth.client_secret | string | `""` | Scribe Client Secret |
| scribe.service.enable | bool | `false` | Scribe Client Enable |
| serviceMonitor.enabled | bool | `false` |  |
| webhook.env | object | `{}` |  |
| webhook.extraArgs.structured | bool | `true` |  |
| webhook.extraArgs.verbose | int | `2` |  |
| webhook.image.pullPolicy | string | `"IfNotPresent"` |  |
| webhook.image.repository | string | `"scribesecurity/valint"` |  |
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

<!-- ### Troubleshooting  -->
