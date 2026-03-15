{{- define "simple-game.name" -}}
{{- .Chart.Name -}}
{{- end -}}

{{- define "simple-game.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "simple-game.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{ default (include "simple-game.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
{{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}
