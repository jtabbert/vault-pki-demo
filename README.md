# vault-pki-demo

This repo is to be used with the following instruqt lab

https://play.instruqt.com/hashicorp/tracks/vault-managing-secrets-and-moving-to-cloud

Instructions

1. Skip to the end of the lab
2. Copy & Paste the code in "setup-pki.sh" into a new file on the Terminal Tab
3. Run the script. This will enable the PKI secrets engine, create a k8s service account, and create a pod that will grab a certificate from Vault.
```
bash setup-pki.sh
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
11. At this time the certificate is not being used by any webserver or application.  A future enhancement will aim to demonstrate that.
