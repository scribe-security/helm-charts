{{/*
Expand the name of the chart.
*/}}
{{- define "attstore.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "attstore.fullname" -}}
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
{{- define "attstore.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "attstore.labels" -}}
helm.sh/chart: {{ include "attstore.chart" . }}
{{ include "attstore.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "attstore.selectorLabels" -}}
app.kubernetes.io/name: {{ include "attstore.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "attstore.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "attstore.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
PostgreSQL fullname
*/}}
{{- define "attstore.postgresql.fullname" -}}
{{- printf "%s-postgresql" (include "attstore.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
PostgreSQL labels
*/}}
{{- define "attstore.postgresql.labels" -}}
helm.sh/chart: {{ include "attstore.chart" . }}
{{ include "attstore.postgresql.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: database
{{- end }}

{{/*
PostgreSQL selector labels
*/}}
{{- define "attstore.postgresql.selectorLabels" -}}
app.kubernetes.io/name: {{ include "attstore.name" . }}-postgresql
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
MinIO fullname
*/}}
{{- define "attstore.minio.fullname" -}}
{{- printf "%s-minio" (include "attstore.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
MinIO labels
*/}}
{{- define "attstore.minio.labels" -}}
helm.sh/chart: {{ include "attstore.chart" . }}
{{ include "attstore.minio.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: object-storage
{{- end }}

{{/*
MinIO selector labels
*/}}
{{- define "attstore.minio.selectorLabels" -}}
app.kubernetes.io/name: {{ include "attstore.name" . }}-minio
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
PgBouncer fullname
*/}}
{{- define "attstore.pgbouncer.fullname" -}}
{{- printf "%s-pgbouncer" (include "attstore.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
PgBouncer labels
*/}}
{{- define "attstore.pgbouncer.labels" -}}
helm.sh/chart: {{ include "attstore.chart" . }}
{{ include "attstore.pgbouncer.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: connection-pooler
{{- end }}

{{/*
PgBouncer selector labels
*/}}
{{- define "attstore.pgbouncer.selectorLabels" -}}
app.kubernetes.io/name: {{ include "attstore.name" . }}-pgbouncer
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Generate session secret
*/}}
{{- define "attstore.sessionSecret" -}}
{{- if .Values.config.sessionSecret }}
{{- .Values.config.sessionSecret }}
{{- else }}
{{- randAlphaNum 32 }}
{{- end }}
{{- end }}

{{/*
Generate JWT secret
*/}}
{{- define "attstore.jwtSecret" -}}
{{- if .Values.config.jwtSecretKey }}
{{- .Values.config.jwtSecretKey }}
{{- else }}
{{- randAlphaNum 32 }}
{{- end }}
{{- end }}

{{/*
Generate PostgreSQL password
*/}}
{{- define "attstore.postgresql.password" -}}
{{- if .Values.database.postgresql.password }}
{{- .Values.database.postgresql.password }}
{{- else }}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (include "attstore.postgresql.fullname" .)) }}
{{- if $secret }}
{{- index $secret.data "POSTGRES_PASSWORD" | b64dec }}
{{- else }}
{{- randAlphaNum 16 }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Generate MinIO root password
*/}}
{{- define "attstore.minio.password" -}}
{{- if .Values.minio.rootPassword }}
{{- .Values.minio.rootPassword }}
{{- else }}
{{- randAlphaNum 16 }}
{{- end }}
{{- end }}

{{/*
Database URL
*/}}
{{- define "attstore.databaseUrl" -}}
{{- if eq .Values.database.type "sqlite" }}
{{- printf "sqlite:///%s" .Values.database.sqlite.path }}
{{- else if .Values.database.externalDatabase.enabled }}
{{- if .Values.database.externalDatabase.url }}
{{- .Values.database.externalDatabase.url }}
{{- else }}
{{- printf "postgresql://%s:%s@%s:%d/%s" .Values.database.externalDatabase.username .Values.database.externalDatabase.password .Values.database.externalDatabase.host (.Values.database.externalDatabase.port | int) .Values.database.externalDatabase.database }}
{{- end }}
{{- else if .Values.database.postgresql.enabled }}
{{- if .Values.pgbouncer.enabled }}
{{- printf "postgresql://%s:%s@%s:6432/%s" .Values.database.postgresql.username (include "attstore.postgresql.password" .) (include "attstore.pgbouncer.fullname" .) .Values.database.postgresql.database }}
{{- else }}
{{- printf "postgresql://%s:%s@%s:%d/%s" .Values.database.postgresql.username (include "attstore.postgresql.password" .) (include "attstore.postgresql.fullname" .) (.Values.database.postgresql.port | int) .Values.database.postgresql.database }}
{{- end }}
{{- else }}
{{- printf "sqlite:///attestation_store.db" }}
{{- end }}
{{- end }}

{{/*
File storage base URL
*/}}
{{- define "attstore.fileStorageBaseUrl" -}}
{{- if .Values.storage.fileMount.baseUrl }}
{{- .Values.storage.fileMount.baseUrl }}
{{- else if .Values.ingress.enabled }}
{{- $host := (index .Values.ingress.hosts 0).host }}
{{- $scheme := ternary "https" "http" (gt (len .Values.ingress.tls) 0) }}
{{- printf "%s://%s" $scheme $host }}
{{- else }}
{{- printf "http://%s:%d" (include "attstore.fullname" .) (.Values.service.port | int) }}
{{- end }}
{{- end }}

{{/*
MinIO endpoint
*/}}
{{- define "attstore.minioEndpoint" -}}
{{- if .Values.storage.cloudStorage.minio.endpoint }}
{{- .Values.storage.cloudStorage.minio.endpoint }}
{{- else if .Values.minio.enabled }}
{{- printf "http://%s:%d" (include "attstore.minio.fullname" .) (.Values.minio.service.port | int) }}
{{- else }}
{{- "" }}
{{- end }}
{{- end }}
