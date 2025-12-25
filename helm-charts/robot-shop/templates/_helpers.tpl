{{/*
Expand the name of the chart.
*/}}
{{- define "robot-shop.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "robot-shop.fullname" -}}
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
Common labels
*/}}
{{- define "robot-shop.labels" -}}
helm.sh/chart: {{ include "robot-shop.chart" . }}
{{ include "robot-shop.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
environment: {{ .Values.global.environment }}
{{ include "robot-shop.enterpriseLabels" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "robot-shop.selectorLabels" -}}
app.kubernetes.io/name: {{ include "robot-shop.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Chart name and version
*/}}
{{- define "robot-shop.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Enterprise Security Context - OWASP Best Practices
*/}}
{{- define "robot-shop.securityContext" -}}
securityContext:
  runAsNonRoot: {{ .Values.global.securityContext.runAsNonRoot | default true }}
  runAsUser: {{ .Values.global.securityContext.runAsUser | default 1000 }}
  runAsGroup: {{ .Values.global.securityContext.runAsGroup | default 3000 }}
  readOnlyRootFilesystem: {{ .Values.global.securityContext.readOnlyRootFilesystem | default true }}
  allowPrivilegeEscalation: {{ .Values.global.securityContext.allowPrivilegeEscalation | default false }}
  capabilities:
    drop:
      {{- range .Values.global.securityContext.capabilities.drop | default (list "ALL") }}
      - {{ . }}
      {{- end }}
{{- end }}

{{/*
Pod Security Context - Pod Security Standards
*/}}
{{- define "robot-shop.podSecurityContext" -}}
securityContext:
  fsGroup: {{ .Values.global.securityContext.fsGroup | default 2000 }}
  {{- if .Values.global.podSecurityContext.seccompProfile }}
  seccompProfile:
    type: {{ .Values.global.podSecurityContext.seccompProfile.type | default "RuntimeDefault" }}
  {{- end }}
{{- end }}

{{/*
Resource Limits Template - Cost Optimization
*/}}
{{- define "robot-shop.resources" -}}
{{- $resources := . -}}
resources:
  requests:
    cpu: {{ $resources.requests.cpu | default $.Values.global.resources.requests.cpu }}
    memory: {{ $resources.requests.memory | default $.Values.global.resources.requests.memory }}
  limits:
    cpu: {{ $resources.limits.cpu | default $.Values.global.resources.limits.cpu }}
    memory: {{ $resources.limits.memory | default $.Values.global.resources.limits.memory }}
{{- end }}

{{/*
Image Template with GitOps Support
*/}}
{{- define "robot-shop.image" -}}
{{- $service := .service -}}
{{- $tag := .tag | default "latest" -}}
{{- $registry := .Values.global.imageRegistry -}}
image: {{ $registry }}/{{ $service }}:{{ $tag }}
imagePullPolicy: {{ .Values.global.imagePullPolicy }}
{{- end }}

{{/*
Monitoring Annotations - Observability
*/}}
{{- define "robot-shop.monitoringAnnotations" -}}
{{- if .Values.global.monitoring.enabled }}
prometheus.io/scrape: "true"
prometheus.io/port: "9090"
prometheus.io/path: "/metrics"
prometheus.io/scheme: "http"
{{- end }}
{{- end }}

{{/*
Enterprise Security Labels - Compliance
*/}}
{{- define "robot-shop.enterpriseLabels" -}}
security.robot-shop.io/level: {{ .Values.global.environment | default "dev" }}
security.robot-shop.io/network-policy: {{ .Values.global.networkPolicy.enabled | default "false" | quote }}
security.robot-shop.io/read-only-fs: {{ .Values.global.securityContext.readOnlyRootFilesystem | default "true" | quote }}
compliance.robot-shop.io/soc2: "enabled"
compliance.robot-shop.io/pci-dss: {{ eq .Values.global.environment "production" | quote }}
{{- end }}

{{/*
Service Template with Enterprise Features
*/}}
{{- define "robot-shop.service" -}}
{{- $service := .service -}}
{{- $port := .port | default 8080 -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ $service }}
  namespace: {{ $.Release.Namespace }}
  labels:
    {{- include "robot-shop.labels" $ | nindent 4 }}
    app.kubernetes.io/component: {{ $service }}
  annotations:
    {{- include "robot-shop.monitoringAnnotations" $ | nindent 4 }}
spec:
  type: {{ $.Values.global.service.type | default "ClusterIP" }}
  ports:
    - port: {{ $port }}
      targetPort: {{ $port }}
      protocol: TCP
      name: http
  selector:
    app.kubernetes.io/name: {{ include "robot-shop.name" $ }}
    app.kubernetes.io/component: {{ $service }}
{{- end }}

{{/*
Deployment Template with Enterprise Security
*/}}
{{- define "robot-shop.deployment" -}}
{{- $service := .service -}}
{{- $config := index $.Values $service -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $service }}
  namespace: {{ $.Release.Namespace }}
  labels:
    {{- include "robot-shop.labels" $ | nindent 4 }}
    app.kubernetes.io/component: {{ $service }}
spec:
  replicas: {{ $config.replicas | default 1 }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ include "robot-shop.name" $ }}
      app.kubernetes.io/component: {{ $service }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {{ include "robot-shop.name" $ }}
        app.kubernetes.io/component: {{ $service }}
        {{- include "robot-shop.enterpriseLabels" $ | nindent 8 }}
      annotations:
        {{- include "robot-shop.monitoringAnnotations" $ | nindent 8 }}
    spec:
      {{- include "robot-shop.podSecurityContext" $ | nindent 6 }}
      containers:
        - name: {{ $service }}
          {{- include "robot-shop.image" (dict "service" $service "tag" ($config.image.tag | default "latest") "Values" $.Values) | nindent 10 }}
          {{- include "robot-shop.securityContext" $ | nindent 10 }}
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
          {{- if eq $service "shipping" }}
          env:
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysql-secret
                  key: user-password
          {{- end }}
          {{- if $config.resources }}
          {{- include "robot-shop.resources" $config.resources | nindent 10 }}
          {{- else }}
          {{- include "robot-shop.resources" $.Values.global.resources | nindent 10 }}
          {{- end }}
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /ready
              port: http
            initialDelaySeconds: 5
            periodSeconds: 5
          {{- if $.Values.global.securityContext.readOnlyRootFilesystem }}
          volumeMounts:
            - name: tmp
              mountPath: /tmp
            - name: var-cache
              mountPath: /var/cache
          {{- end }}
      {{- if $.Values.global.securityContext.readOnlyRootFilesystem }}
      volumes:
        - name: tmp
          emptyDir: {}
        - name: var-cache
          emptyDir: {}
      {{- end }}
{{- end }}
