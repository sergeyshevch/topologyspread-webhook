{{/*
Expand the name of the chart.
*/}}
{{- define "topologyspread-webhook.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "topologyspread-webhook.fullname" -}}
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
{{- define "topologyspread-webhook.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "topologyspread-webhook.labels" -}}
helm.sh/chart: {{ include "topologyspread-webhook.chart" . }}
{{ include "topologyspread-webhook.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "topologyspread-webhook.selectorLabels" -}}
app.kubernetes.io/name: {{ include "topologyspread-webhook.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "topologyspread-webhook.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "topologyspread-webhook.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Create the name of the role manifests to use
*/}}
{{- define "topologyspread-webhook.rbacName" -}}
{{- if .Values.rbac.create }}
{{- default (include "topologyspread-webhook.fullname" .) .Values.rbac.name }}
{{- else }}
{{- default "default" .Values.rbac.name }}
{{- end }}
{{- end }}

{{/*
Create the name for certificates
*/}}
{{- define "topologyspread-webhook.certName" -}}
{{- printf "%s-serving-cert" (include "topologyspread-webhook.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{/*
Create the name for issuer
*/}}
{{- define "topologyspread-webhook.issuerName" -}}
{{- printf "%s-self-signed" (include "topologyspread-webhook.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the name for service
*/}}
{{- define "topologyspread-webhook.serviceName" -}}
{{ include "topologyspread-webhook.fullname" . -}}
{{- end }}

{{/*
Generate certificates for webhook
*/}}
{{- define "topologyspread-webhook.webhookCerts" -}}
{{- $serviceName := (include "topologyspread-webhook.serviceName" .) -}}
{{- $secretName := (include "topologyspread-webhook.certName" .) -}}
{{- $secret := lookup "v1" "Secret" .Release.Namespace $secretName -}}
{{- if (and .Values.webhookTLS.caCert .Values.webhookTLS.cert .Values.webhookTLS.key) -}}
caCert: {{ .Values.webhookTLS.caCert | b64enc }}
clientCert: {{ .Values.webhookTLS.cert | b64enc }}
clientKey: {{ .Values.webhookTLS.key | b64enc }}
{{- else if and .Values.keepTLSSecret $secret -}}
caCert: {{ index $secret.data "ca.crt" }}
clientCert: {{ index $secret.data "tls.crt" }}
clientKey: {{ index $secret.data "tls.key" }}
{{- else -}}
{{- $altNames := list (printf "%s.%s" $serviceName .Release.Namespace) (printf "%s.%s.svc" $serviceName .Release.Namespace) (printf "%s.%s.svc.cluster.local" $serviceName .Release.Namespace) -}}
{{- $ca := genCA "topologyspread-webhook-ca" 3650 -}}
{{- $cert := genSignedCert (include "topologyspread-webhook.fullname" .) nil $altNames 3650 $ca -}}
caCert: {{ $ca.Cert | b64enc }}
clientCert: {{ $cert.Cert | b64enc }}
clientKey: {{ $cert.Key | b64enc }}
{{- end -}}
{{- end -}}