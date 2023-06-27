# vault-pki-demo

This repo is to be used with the following Instruqt lab.  This Instruqt lab is private.

https://play.instruqt.com/hashicorp/tracks/vault-managing-secrets-and-moving-to-cloud

**Overview**

This demo was created to show the PKI secrets engine being used with the Vault Agent Injector Sidecar.  Every 3 minutes the agent will retreive a new certificate & private key from Vault.  These will be placed in the pod at /vault/secrets

**Instructions**

1. Skip ahead to the last challenge "Vault Agent with Kubernetes"
2. Clone the git repo with the command below
```
git clone https://github.com/jtabbert/vault-pki-demo
```
4. Run the script. This will enable the PKI secrets engine, create a k8s service account, and create a pod that will grab a certificate from Vault.
```
bash vault-pki-demo/setup-pki.sh
```
4. Run the command below to start an interactive shell in the new pod.
```
kubectl exec -it pki-test -- sh
```
5. Run the command below to move to the directory where the certificate & key are stored.
```
cd vault/secrets
```
7. Run the command below to inspect the certificate
```
openssl x509 -text -in server.crt
```
9. The Certificate will be rotated every 3 minutes, you can run the above command to show the new serial number & the time the certificate is valid for
10. You can also show server.key is present in vault/secrets in the container.
11. The Vault UI can also be used to show the certificates being issued.  The token to login to the Vault UI in this challenge is "root"
12. At this time the certificate is not being used by any webserver or application.  A future enhancement will aim to demonstrate that.
