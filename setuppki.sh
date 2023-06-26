#! /bin/bash

CONFIG="
  [req]
  distinguished_name=dn
  [ dn ]
  [ ext ]
  basicConstraints=CA:TRUE,pathlen:0
  "

openssl req -config <(echo "$CONFIG") -new -newkey rsa:2048 -nodes \-subj "/C=IN/O=hashicorpjustin/OU=Cloud-DevOps/ST=AP/CN=hashicorpjustin.com/emailAddress=justin.tabbert@hashicorp.com" -x509 -days 365 -extensions ext -keyout root-key.pem -out root-cert.pem

cat root-key.pem root-cert.pem > pem_bundle

vault secrets enable pki

vault secrets tune -max-lease-ttl=8760h pki

vault write pki/config/ca pem_bundle=@pem_bundle ttl=8760h

vault write pki/roles/hashicorpjustin allowed_domains=hashicorpjustin.com allow_subdomains=true max_ttl=3m

vault write pki/config/urls issuing_certificates="$VAULT_ADDR/v1/pki/ca" crl_distribution_points="$VAULT_ADDR/v1/pki/crl"

vault policy write hashicorpjustin_pki - << EOF
# policies required for PKI demo
path "pki*" {
  capabilities = ["read", "list"]
}

path "pki/roles/hashicorpjustin" {
  capabilities = ["create", "update"]
}

path "pki/sign/hashicorpjustin" {
  capabilities = ["create", "update"]
}

path "pki/issue/hashicorpjustin" {
  capabilities = ["create", "update", "read", "list"]
}
EOF

vault write auth/kubernetes/role/issuer \
bound_service_account_names=products-api \
bound_service_account_namespaces=default \
policies=hashicorpjustin_pki \
ttl=20m

echo 'apiVersion: v1
kind: Pod
metadata:
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/agent-init-first: "true"
    vault.hashicorp.com/agent-inject-secret-server.key: "pki/issue/hashicorpjustin"
    vault.hashicorp.com/agent-inject-template-server.key: |
      {{- with secret "pki/issue/hashicorpjustin" "common_name=test.hashicorpjustin.com" -}}
      {{ .Data.private_key }}
      {{- end }}
    vault.hashicorp.com/agent-inject-secret-server.crt: "pki/issue/hashicorpjustin"
    vault.hashicorp.com/agent-inject-template-server.crt: |
      {{- with secret "pki/issue/hashicorpjustin" "common_name=test.hashicorpjustin.com" -}}
      {{ .Data.certificate }}
      {{- end }}
    vault.hashicorp.com/role: "issuer"
  labels:
    run: pki-test
  name: pki-test
spec:
  serviceAccountName: products-api
  containers:
  - image: nginx
    name: pki-test
  restartPolicy: Always' > k8s/pki-test.yml

kubectl apply -f k8s/pki-test.yml
