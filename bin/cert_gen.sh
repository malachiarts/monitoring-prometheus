#!/bin/sh

# https://sysdig.com/blog/kubernetes-security-rbac-tls/
openssl genrsa -out prometheus.key 2048
openssl req -new -key prometheus.key -out prometheus.csr -subj "/CN=system:serviceaccount:default:api-prometheus/O=monitoring"
openssl x509 -req -in prometheus.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out prometheus.crt -days 365
