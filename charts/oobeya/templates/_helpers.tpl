{{/*
Expand the name of the chart.
*/}}
{{- define "oobeya.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "oobeya.fullname" -}}
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
{{- define "oobeya.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "oobeya.labels" -}}
helm.sh/chart: {{ include "oobeya.chart" . }}
{{ include "oobeya.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "oobeya.selectorLabels" -}}
app.kubernetes.io/name: {{ include "oobeya.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "oobeya.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "oobeya.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Resolve the MongoDB connection URI of a single Oobeya service.

Usage: include "oobeya.mongo.uri" (dict "mongo" .Values.oobeyaExternalMongo "service" "dashboard")

The base URI is oobeyaExternalMongo.uris.<service> when it is set, otherwise the
shared oobeyaExternalMongo.mongoUri. When oobeyaExternalMongo.credentials.<service>
carries a username, it replaces any user info the base URI already had, and its
optional authSource replaces the authSource of the query string. The database path
is always taken from oobeyaExternalMongo.databases.<service>; hosts and every other
query parameter are preserved as given.
*/}}
{{- define "oobeya.mongo.uri" -}}
{{- $mongo := .mongo -}}
{{- $service := .service -}}
{{- $db := index $mongo.databases $service -}}
{{- $base := default $mongo.mongoUri (get (default (dict) $mongo.uris) $service) -}}
{{- $scheme := regexFind "^mongodb(\\+srv)?://" $base -}}
{{- if not $scheme -}}
{{- fail (printf "oobeyaExternalMongo: the URI for %q must start with mongodb:// or mongodb+srv:// (got %q)" $service $base) -}}
{{- end -}}
{{- $rest := trimPrefix $scheme $base -}}
{{- $userinfo := regexFind "^[^/?]*@" $rest -}}
{{- $remainder := trimPrefix $userinfo $rest -}}
{{- $path := $remainder -}}
{{- $query := "" -}}
{{- if contains "?" $remainder -}}
{{- $split := splitn "?" 2 $remainder -}}
{{- $path = $split._0 -}}
{{- $query = $split._1 -}}
{{- end -}}
{{- $hosts := $path -}}
{{- if contains "/" $path -}}
{{- $hosts = (splitn "/" 2 $path)._0 -}}
{{- end -}}
{{- $creds := default (dict) (get (default (dict) $mongo.credentials) $service) -}}
{{- $username := default "" (get $creds "username") -}}
{{- if $username -}}
{{- $userinfo = printf "%s:%s@" $username (default "" (get $creds "password")) -}}
{{- end -}}
{{- $authSource := default "" (get $creds "authSource") -}}
{{- if $authSource -}}
{{- $params := list -}}
{{- range $param := (splitList "&" $query) -}}
{{- if and $param (not (hasPrefix "authSource=" $param)) -}}
{{- $params = append $params $param -}}
{{- end -}}
{{- end -}}
{{- $query = join "&" (append $params (printf "authSource=%s" $authSource)) -}}
{{- end -}}
{{- if $query -}}
{{- printf "%s%s%s/%s?%s" $scheme $userinfo $hosts $db $query -}}
{{- else -}}
{{- printf "%s%s%s/%s" $scheme $userinfo $hosts $db -}}
{{- end -}}
{{- end }}
