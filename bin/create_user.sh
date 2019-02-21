#!/bin/sh

# system:serviceaccount:default:api-prometheus
kubectl create serviceaccount api-prometheus
kubectl create -f role.yaml
kubectl create clusterrolebinding api-prometheus:log-reader --clusterrole log-reader --serviceaccount default:api-prometheus

SECRET=$(kubectl get serviceaccount "${SERVICE_ACCOUNT}" -o json | jq -Mr '.secrets[].name | select(contains("token"))')
TOKEN=$(kubectl get secret "${SECRET}" -o json | jq -Mr '.data.token' | base64 -D)
kubectl get secret "${SECRET}" -o json | jq -Mr '.data["ca.crt"]' | base64 -D > /tmp/ca.crt
# kubectl describe secret "${SECRET}" -n default

echo "$TOKEN"
