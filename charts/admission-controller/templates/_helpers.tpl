{{/*
Expand the name of the chart.
*/}}
{{- define "admission-controller.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "admission-controller.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "admission-controller.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "admission-controller.labels" -}}
helm.sh/chart: {{ include "admission-controller.chart" . }}
{{ include "admission-controller.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "admission-controller.selectorLabels" -}}
app.kubernetes.io/name: {{ include "admission-controller.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "admission-controller.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "admission-controller.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Self-signed certificate authority issuer name
*/}}
{{- define "admission-controller.CAIssuerName" -}}
{{- if .Values.certificates.ca.issuer.name -}}
{{ .Values.certificates.ca.issuer.name }}
{{- else -}}
{{ template "admission-controller.fullname" . }}-ca-issuer
{{- end -}}
{{- end -}}

{{/*
CA Certificate issuer name
*/}}
{{- define "admission-controller.CAissuerName" -}}
{{- if .Values.certificates.selfSigned -}}
{{ template "admission-controller.CAIssuerName" . }}
{{- else -}}
{{ required "A valid .Values.certificates.ca.issuer.name is required!" .Values.certificates.issuer.name }}
{{- end -}}
{{- end -}}

{{/*
CA signed certificate issuer name
*/}}
{{- define "admission-controller.IssuerName" -}}
{{- if .Values.certificates.issuer.name -}}
{{ .Values.certificates.issuer.name }}
{{- else -}}
{{ template "admission-controller.fullname" . }}-issuer
{{- end -}}
{{- end -}}

{{/*
Certificate issuer name
*/}}
{{- define "admission-controller.issuerName" -}}
{{- if .Values.certificates.selfSigned -}}
{{ template "admission-controller.IssuerName" . }}
{{- else -}}
{{ required "A valid .Values.certificates.issuer.name is required!" .Values.certificates.issuer.name }}
{{- end -}}
{{- end -}}

{{/*
Create the image path for the passed in image field
*/}}
{{- define "admission-controller.image" -}}
{{- if eq (substr 0 7 .version) "sha256:" -}}
{{- printf "%s@%s" .repository .version -}}
{{- else -}}
{{- printf "%s:%s" .repository .version -}}
{{- end -}}
{{- end -}}

{{/*
Create the image path for the passed in webhook image field
*/}}
{{- define "webhook.image" -}}
{{- if eq (substr 0 7 .version) "sha256:" -}}
{{- printf "%s@%s" .repository .version -}}
{{- else -}}
{{- printf "%s:%s" .repository .version -}}
{{- end -}}
{{- end -}}
