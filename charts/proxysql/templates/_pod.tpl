{{- define "proxysql.pod" -}}
metadata:
{{- with .Values.podAnnotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
{{- end }}
  labels:
    {{- include "proxysql.selectorLabels" . | nindent 4 }}
spec:
  {{- with .Values.imagePullSecrets }}
  imagePullSecrets:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  serviceAccountName: {{ include "proxysql.serviceAccountName" . }}
  securityContext:
    {{- toYaml .Values.podSecurityContext | nindent 4 }}
  containers:
    - name: {{ .Chart.Name }}
      securityContext:
        {{- toYaml .Values.securityContext | nindent 8 }}
      image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
      imagePullPolicy: {{ .Values.image.pullPolicy }}
      command:
        - proxysql
        - "-f"
        - "--idle-threads"
        - "-D"
        - "/var/lib/proxysql"
        - "--reload"
      ports:
        - name: mysql
          containerPort: {{ .Values.proxysql.mysql.port }}
          protocol: TCP
        - name: proxysql
          containerPort: {{ .Values.proxysql.port }}
          protocol: TCP
        {{- if .Values.proxysql.web.enabled }}
        - name: web
          containerPort: {{ .Values.proxysql.web.port }}
          protocol: TCP
        {{- end }}
        {{- if .Values.metrics.enabled }}
        - name: metrics
          containerPort: 6070
          protocol: TCP
        {{- end }}
      livenessProbe:
        tcpSocket:
          port: proxysql
      readinessProbe:
        tcpSocket:
          port: proxysql
      volumeMounts:
        - name: proxysql-config
          mountPath: /etc/proxysql.cnf
          subPath: proxysql.cnf
          readOnly: true
        - name: ca-cert-volume
          mountPath: /etc/ca.pem
          subPath: ca.pem
          readOnly: true
      {{- if and .Values.proxysql.cluster.enabled .Values.proxysql.cluster.claim.enabled }}
        - name: {{ include "proxysql.fullname" . }}-pv
          mountPath: /var/lib/proxysql
      {{- end }}
      resources:
        {{- toYaml .Values.resources | nindent 8 }}
  volumes:
    - name: ca-cert-volume
      secret:
        secretName: singlestore-ca-cert-secret
    - name: proxysql-config
      configMap:
        name: {{ .Values.proxysql.configmap | default (include "proxysql.fullname" .) }}
  {{- with .Values.nodeSelector }}
  nodeSelector:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.affinity }}
  affinity:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.tolerations }}
  tolerations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
