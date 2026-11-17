{{/* Shared immutable worker template for poll, digest and schema initialization. */}}
{{- define "notifications.podTemplate" -}}
{{- $root := .root -}}
{{- $paths := list "/app" -}}
{{- range $filename := keys $root.Values.wheelFiles | sortAlpha -}}
{{- $paths = append $paths (printf "/deps/%s" $filename) -}}
{{- end -}}
metadata:
  labels:
    app.kubernetes.io/name: defectdojo-notifications
    app.kubernetes.io/instance: {{ $root.Release.Name }}
    app.kubernetes.io/component: {{ .kind }}
  annotations:
    checksum/content: {{ $root.Values.contentChecksum | quote }}
    checksum/policy: {{ toJson $root.Values.policy | sha256sum | quote }}
    checksum/source: {{ toJson $root.Values.sourceFiles | sha256sum | quote }}
    checksum/dependencies: {{ toJson $root.Values.wheelFiles | sha256sum | quote }}
spec:
  restartPolicy: Never
  automountServiceAccountToken: false
  securityContext:
    runAsNonRoot: true
    runAsUser: 65532
    runAsGroup: 65532
    fsGroup: 65532
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: {{ .kind }}
      image: {{ required "A public Python runtime image is required" $root.Values.image | quote }}
      imagePullPolicy: IfNotPresent
      command: ["python", "-m", "notifier", {{ .kind | quote }}]
      env:
        - name: POLICY_FILE
          value: /config/policy.json
        - name: SECRET_DIR
          value: /var/run/secrets/notifications
        - name: PYTHONDONTWRITEBYTECODE
          value: "1"
        - name: PYTHONPATH
          value: {{ join ":" $paths | quote }}
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop: ["ALL"]
      resources:
        requests:
          cpu: 50m
          memory: 128Mi
        limits:
          cpu: 500m
          memory: 512Mi
      volumeMounts:
        - name: config
          mountPath: /config
          readOnly: true
        - name: source
          mountPath: /app
          readOnly: true
        - name: dependencies
          mountPath: /deps
          readOnly: true
        - name: credentials
          mountPath: /var/run/secrets/notifications
          readOnly: true
        {{- if $root.Values.mysqlCaSecret.name }}
        - name: mysql-ca
          mountPath: /var/run/secrets/mysql-ca
          readOnly: true
        {{- end }}
  volumes:
    - name: config
      configMap:
        name: {{ $root.Release.Name }}
    - name: source
      configMap:
        name: {{ $root.Release.Name }}-source
        items:
          {{- range $filename := keys $root.Values.sourceFiles | sortAlpha }}
          - key: {{ $filename | quote }}
            path: {{ printf "notifier/%s" $filename | quote }}
          {{- end }}
    - name: dependencies
      configMap:
        name: {{ $root.Release.Name }}-dependencies
    - name: credentials
      projected:
        defaultMode: 0440
        sources:
          - secret:
              name: {{ required "Existing API token Secret name is required" $root.Values.apiTokenSecret.name | quote }}
              items:
                - key: {{ required "API token Secret key is required" $root.Values.apiTokenSecret.key | quote }}
                  path: api-token
          - secret:
              name: {{ required "MySQL credentials Secret name is required" $root.Values.mysqlCredentialsSecret.name | quote }}
              items:
                - key: {{ required "MySQL username Secret key is required" $root.Values.mysqlCredentialsSecret.usernameKey | quote }}
                  path: mysql-user
                - key: {{ required "MySQL password Secret key is required" $root.Values.mysqlCredentialsSecret.passwordKey | quote }}
                  path: mysql-password
          - secret:
              name: {{ required "Existing channels Secret name is required" $root.Values.channelsSecret.name | quote }}
              optional: true
              items:
                - key: {{ required "Slack Secret key is required" $root.Values.channelsSecret.slackKey | quote }}
                  path: slack-url
                - key: {{ required "Teams Secret key is required" $root.Values.channelsSecret.teamsKey | quote }}
                  path: teams-url
                - key: {{ required "Opsgenie individual Secret key is required" $root.Values.channelsSecret.opsgenieKey | quote }}
                  path: opsgenie-key
    {{- if $root.Values.mysqlCaSecret.name }}
    - name: mysql-ca
      secret:
        secretName: {{ $root.Values.mysqlCaSecret.name | quote }}
        defaultMode: 0440
        items:
          - key: {{ required "MySQL CA Secret key is required" $root.Values.mysqlCaSecret.key | quote }}
            path: ca.crt
    {{- end }}
{{- end -}}
