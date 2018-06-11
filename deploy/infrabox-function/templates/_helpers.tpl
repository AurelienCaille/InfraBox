{{- define "system_namespace" -}}
{{- required "system_namespace is required" .Values.system_namespace -}}
{{- end -}}

{{- define "worker_namespace" -}}
{{- required "worker_namespace is required" .Values.worker_namespace -}}
{{- end -}}

{{- define "root_url" -}}
{{- if eq 443.0 .Values.port -}}
https://{{- required "host is required" .Values.host -}}
{{- else -}}
https://{{- required "host is required" .Values.host -}}:{{- .Values.port -}}
{{- end -}}
{{- end -}}

{{- define "image_repository" -}}
{{- required "image.repository is required" .Values.image.repository -}}
{{- end -}}

{{- define "image_tag" -}}
{{- required "image.tag is required" .Values.image.tag -}}
{{- end -}}

{{ define "env_database" }}
-
    name: INFRABOX_DATABASE_USER
    valueFrom:
        secretKeyRef:
            name: infrabox-postgres
            key: username
-
    name: INFRABOX_DATABASE_PASSWORD
    valueFrom:
        secretKeyRef:
            name: infrabox-postgres
            key: password
{{ if .Values.database.postgres.enabled }}
-
    name: INFRABOX_DATABASE_HOST
    value: {{ required "database.postgres.host is required" .Values.database.postgres.host | quote }}
-
    name: INFRABOX_DATABASE_DB
    value: {{ required "database.postgres.db is required" .Values.database.postgres.db | quote }}
-
    name: INFRABOX_DATABASE_PORT
    value: {{ required "database.postgres.port is required" .Values.database.postgres.port | quote }}
{{ end }}
{{ if .Values.database.cloudsql.enabled }}
-
    name: INFRABOX_DATABASE_HOST
    value: localhost
-
    name: INFRABOX_DATABASE_DB
    value: {{ required "database.cloudsql.db is required" .Values.database.cloudsql.db | quote }}
-
    name: INFRABOX_DATABASE_PORT
    value: "5432"
-
    name: INFRABOX_STORAGE_CLOUDSQL_INSTANCE_CONNECTION_NAME
    value: {{ .Values.database.cloudsql.instance_connection_name }}
{{ end }}
{{ end }}

{{ define "volumes_rsa" }}
-
    name: rsa-key
    secret:
        secretName: infrabox-rsa
{{ end }}

{{ define "mounts_rsa_private" }}
-
    name: rsa-key
    mountPath: "/var/run/secrets/infrabox.net/rsa/id_rsa"
    subPath: id_rsa
    readOnly: true
{{ end }}

{{ define "mounts_rsa_public" }}
-
    name: rsa-key
    mountPath: "/var/run/secrets/infrabox.net/rsa/id_rsa.pub"
    subPath: id_rsa.pub
    readOnly: true
{{ end }}

{{ define "mounts_gcs" }}
{{ if .Values.storage.gcs.enabled }}
-
    name: gcs-service-account
    mountPath: /etc/infrabox/gcs
    readOnly: true
{{ end }}
{{ end }}

{{ define "mounts_gerrit" }}
-
    name: gerrit-ssh
    mountPath: /tmp/gerrit
    readOnly: true
{{ end }}

{{ define "volumes_gerrit" }}
{{ if .Values.gerrit.enabled }}
-
    name: gerrit-ssh
    secret:
        secretName: infrabox-gerrit-ssh
{{ end }}
{{ end }}

{{ define "volumes_gcs" }}
{{ if .Values.storage.gcs.enabled }}
-
    name: gcs-service-account
    secret:
        secretName: infrabox-gcs
{{ end }}
{{ end }}

{{ define "volumes_database" }}
{{ if .Values.database.cloudsql.enabled }}
-
    name: cloudsql-instance-credentials
    secret:
        secretName: infrabox-cloudsql-instance-credentials
-
    name: cloudsql
    emptyDir:
{{ end }}
{{ end }}

{{ define "env_account" }}
-
    name: INFRABOX_ACCOUNT_SIGNUP_ENABLED
    value: {{ .Values.account.signup.enabled | quote }}
{{ end }}

{{ define "env_gcs" }}
-
    name: INFRABOX_STORAGE_GCS_ENABLED
    value: {{ .Values.storage.gcs.enabled | quote }}
{{ if .Values.storage.gcs.enabled }}
-
    name: INFRABOX_STORAGE_GCS_BUCKET
    value: {{ .Values.storage.gcs.bucket }}
-
    name: GOOGLE_APPLICATION_CREDENTIALS
    value: /etc/infrabox/gcs/gcs_service_account.json
{{ end }}
{{ end }}

{{ define "env_s3" }}
-
    name: INFRABOX_STORAGE_S3_ENABLED
    value: {{ .Values.storage.s3.enabled | quote }}
{{ if .Values.storage.s3.enabled }}
-
    name: INFRABOX_STORAGE_S3_ENDPOINT
    value: {{ .Values.storage.s3.endpoint }}
-
    name: INFRABOX_STORAGE_S3_PORT
    value: {{ .Values.storage.s3.port | quote }}
-
    name: INFRABOX_STORAGE_S3_REGION
    value: {{ .Values.storage.s3.region | quote }}
-
    name: INFRABOX_STORAGE_S3_SECURE
    value: {{ .Values.storage.s3.secure | quote }}
-
    name: INFRABOX_STORAGE_S3_BUCKET
    value: {{ default "infrabox" .Values.storage.s3.bucket | quote }}
-
    name: INFRABOX_STORAGE_S3_ACCESS_KEY
    valueFrom:
        secretKeyRef:
            name: infrabox-s3-credentials
            key: accessKey
-
    name: INFRABOX_STORAGE_S3_SECRET_KEY
    valueFrom:
        secretKeyRef:
            name: infrabox-s3-credentials
            key: secretKey
{{ end }}
{{ end }}

{{ define "env_azure" }}
-
    name: INFRABOX_STORAGE_AZURE_ENABLED
    value: {{ .Values.storage.azure.enabled | quote }}
{{ if .Values.storage.azure.enabled }}
-
    name: INFRABOX_STORAGE_AZURE_ACCOUNT_NAME
    valueFrom:
        secretKeyRef:
            name: infrabox-azure-credentials
            key: account-name
-
    name: INFRABOX_STORAGE_AZURE_ACCOUNT_KEY
    valueFrom:
        secretKeyRef:
            name: infrabox-azure-credentials
            key: account-key
{{ end }}
{{ end }}

{{ define "env_swift" }}
-
    name: INFRABOX_STORAGE_SWIFT_ENABLED
    value: {{ .Values.storage.swift.enabled | quote }}
{{ if .Values.storage.swift.enabled }}
-
    name: INFRABOX_STORAGE_SWIFT_PROJECT_NAME
    value: {{ .Values.storage.swift.project_name }}
-
    name: INFRABOX_STORAGE_SWIFT_PROJECT_DOMAIN_NAME
    value: {{ .Values.storage.swift.project_domain_name }}
-
    name: INFRABOX_STORAGE_SWIFT_USER_DOMAIN_NAME
    value: {{ .Values.storage.swift.user_domain_name }}
-
    name: INFRABOX_STORAGE_SWIFT_AUTH_URL
    value: {{ .Values.storage.swift.auth_url }}
-
    name: INFRABOX_STORAGE_SWIFT_CONTAINER_NAME
    value: {{ .Values.storage.swift.container_name }}
-
    name: INFRABOX_STORAGE_SWIFT_USERNAME
    valueFrom:
        secretKeyRef:
            name: infrabox-swift-credentials
            key: username
-
    name: INFRABOX_STORAGE_SWIFT_PASSWORD
    valueFrom:
        secretKeyRef:
            name: infrabox-swift-credentials
            key: password
{{ end }}
{{ end }}

{{ define "env_github" }}
-
    name: INFRABOX_GITHUB_ENABLED
    value: {{ .Values.github.enabled | quote }}
{{ if .Values.github.enabled }}
-
    name: INFRABOX_GITHUB_LOGIN_ENABLED
    value: {{ .Values.github.login.enabled | quote }}
-
    name: INFRABOX_GITHUB_API_URL
    value: {{ default "https://api.github.com" .Values.github.api_url }}
-
    name: INFRABOX_GITHUB_LOGIN_URL
    value: {{ default "https://github.com/login" .Values.github.login.url }}
-
    name: INFRABOX_GITHUB_LOGIN_ALLOWED_ORGANIZATIONS
    value: {{ default "" .Values.github.login.allowed_organizations | quote }}
{{ end }}
{{ end }}

{{ define "env_gerrit" }}
-
    name: INFRABOX_GERRIT_ENABLED
    value: {{ .Values.gerrit.enabled | quote }}
{{ if .Values.gerrit.enabled }}
-
    name: INFRABOX_GERRIT_HOSTNAME
    value: {{ required "gerrit.hostname is required" .Values.gerrit.hostname }}
-
    name: INFRABOX_GERRIT_KEY_FILENAME
    value: /root/.ssh/id_rsa
-
    name: INFRABOX_GERRIT_USERNAME
    value: {{ required "gerrit.username is required" .Values.gerrit.username }}
-
    name: INFRABOX_GERRIT_PORT
    value: {{ default "29418" .Values.gerrit.port | quote }}
{{ end }}
{{ end }}

{{ define "env_ldap" }}
{{ if eq .Values.cluster.name "master" }}
-
    name: INFRABOX_ACCOUNT_LDAP_ENABLED
    value: "false"
{{ else }}
-
    name: INFRABOX_ACCOUNT_LDAP_ENABLED
    value: {{ .Values.account.ldap.enabled | quote }}
{{ if .Values.account.ldap.enabled }}
-
    name: INFRABOX_ACCOUNT_LDAP_URL
    value: {{ required "account.ldap.url is required" .Values.account.ldap.url }}
-
    name: INFRABOX_ACCOUNT_LDAP_BASE
    value: {{ required "account.ldap.base is required" .Values.account.ldap.base }}
-
    name: INFRABOX_ACCOUNT_LDAP_DN
    valueFrom:
        secretKeyRef:
            name: infrabox-ldap
            key: dn
-
    name: INFRABOX_ACCOUNT_LDAP_PASSWORD
    valueFrom:
        secretKeyRef:
            name: infrabox-ldap
            key: password
{{ end }}
{{ end }}
{{ end }}


{{ define "env_github_secrets" }}
{{ if .Values.github.enabled }}
-
    name: INFRABOX_GITHUB_CLIENT_ID
    valueFrom:
        secretKeyRef:
            name: infrabox-github
            key: client_id
-
    name: INFRABOX_GITHUB_CLIENT_SECRET
    valueFrom:
        secretKeyRef:
            name: infrabox-github
            key: client_secret
-
    name: INFRABOX_GITHUB_WEBHOOK_SECRET
    valueFrom:
        secretKeyRef:
            name: infrabox-github
            key: webhook_secret
{{ end }}
{{ end }}

{{ define "env_version" }}
-
    name: INFRABOX_VERSION
    value: {{ include "image_tag" . }}
{{ end }}

{{ define "env_cluster" }}
-
    name: INFRABOX_CLUSTER_NAME
    value: {{ required "cluster.name is required" .Values.cluster.name }}
-
    name: INFRABOX_CLUSTER_LABELS
    value: {{ .Values.cluster.labels }}
{{ end }}

{{ define "env_general" }}
-
    name: INFRABOX_GENERAL_DONT_CHECK_CERTIFICATES
    value: {{ default "false" .Values.general.dont_check_certificates | quote }}
-
    name: INFRABOX_GENERAL_WORKER_NAMESPACE
    value: {{ template "worker_namespace" . }}
-
    name: INFRABOX_ROOT_URL
    value: {{ template "root_url" . }}
-
    name: INFRABOX_VERSION
    value: {{ template "image_tag" . }}
-
    name: INFRABOX_GENERAL_REPORT_ISSUE_URL
    value: {{ .Values.general.report_issue_url }}
{{ end }}

{{ define "env_docker_registry" }}
-
    name: INFRABOX_DOCKER_REGISTRY_ADMIN_USERNAME
    value: "admin"
-
    name: INFRABOX_DOCKER_REGISTRY_ADMIN_PASSWORD
    valueFrom:
        secretKeyRef:
            name: infrabox-admin
            key: password
{{ end }}

{{ define "containers_database" }}
{{ if .Values.database.cloudsql.enabled }}
-
    image: gcr.io/cloudsql-docker/gce-proxy:1.09
    name: cloudsql-proxy
    command: ["/cloud_sql_proxy", "--dir=/cloudsql",
              "-instances={{ .Values.database.cloudsql.instance_connection_name }}=tcp:5432",
              "-credential_file=/secrets/cloudsql/credentials.json"]
    volumeMounts:
    - name: cloudsql-instance-credentials
      mountPath: /secrets/cloudsql
      readOnly: true
    - name: cloudsql
      mountPath: /cloudsql
{{ end }}
{{ end }}
