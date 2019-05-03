kubectl create -f monitoring-namespace.json
helm tiller run -- helm install --debug --name=monitoring --namespace=monitoring --values=values.yaml stable/prometheus-operator
