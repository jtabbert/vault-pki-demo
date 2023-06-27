#! /bin/bash

CONFIG="
  [req]
  distinguished_name=dn
  [ dn ]
  [ ext ]
  basicConstraints=CA:TRUE,pathlen:0
  "

openssl req -config <(echo "$CONFIG") -new -newkey rsa:2048 -nodes \-subj "/C=IN/O=hashicups/OU=Cloud-DevOps/ST=AP/CN=hashicups.com/emailAddress=hashicups@hashicorp.com" -x509 -days 365 -extensions ext -keyout root-key.pem -out root-cert.pem

cat root-key.pem root-cert.pem > pem_bundle

vault secrets enable pki

vault secrets tune -max-lease-ttl=8760h pki

vault write pki/config/ca pem_bundle=@pem_bundle ttl=8760h

vault write pki/roles/hashicups allowed_domains=hashicups.com allow_subdomains=true max_ttl=3m

vault write pki/config/urls issuing_certificates="$VAULT_ADDR/v1/pki/ca" crl_distribution_points="$VAULT_ADDR/v1/pki/crl"

vault policy write hashicups_pki - << EOF
# policies required for PKI demo
path "pki*" {
  capabilities = ["read", "list"]
}

path "pki/roles/hashicups" {
  capabilities = ["create", "update"]
}

path "pki/sign/hashicups" {
  capabilities = ["create", "update"]
}

path "pki/issue/hashicups" {
  capabilities = ["create", "update", "read", "list"]
}
EOF

kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: issuer
EOF

vault write auth/kubernetes/role/issuer \
bound_service_account_names=issuer \
bound_service_account_namespaces=default \
policies=hashicups_pki \
ttl=20m

echo 'apiVersion: v1
kind: Pod
metadata:
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/agent-init-first: "true"
    vault.hashicorp.com/agent-inject-secret-server.key: "pki/issue/hashicups"
    vault.hashicorp.com/agent-inject-template-server.key: |
      {{- with secret "pki/issue/hashicups" "common_name=test.hashicups.com" -}}
      {{ .Data.private_key }}
      {{- end }}
    vault.hashicorp.com/agent-inject-secret-server.crt: "pki/issue/hashicups"
    vault.hashicorp.com/agent-inject-template-server.crt: |
      {{- with secret "pki/issue/hashicups" "common_name=test.hashicups.com" -}}
      {{ .Data.certificate }}
      {{- end }}
    vault.hashicorp.com/role: "issuer"
  labels:
    run: pki-test
  name: pki-test
spec:
  serviceAccountName: issuer
  containers:
  - image: nginx
    name: pki-test
  restartPolicy: Always' > ~/k8s/pki-test.yml

kubectl apply -f ~/k8s/pki-test.yml
