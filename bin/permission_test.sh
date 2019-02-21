#!/bin/sh

APISERVER="https://tycho-api-elb-1459645966.us-west-2.elb.amazonaws.com:6443"
CERTS="--key certs/prometheus.key --cacert certs/ca.pem --cert certs/prometheus.csr"
# curl -v -v -s ${APISERVER}/api/v1/namespaces/default/pods/guestbook-frontend-845d478878-267dc/log $CERTS
# curl -v -v -s ${APISERVER}/api/v1/nodes/ip-10-77-1-121.us-west-2.compute.internal/proxy/metrics $CERTS

# kube-service-endpoints
ENDPOINT="/api/v1/namespaces/kube-system/services/coredns:9153/proxy/metrics"
# ENDPOINT="/api/v1/namespaces/kube-system/services/coredns:53/proxy/metrics"
curl -v -v -s ${APISERVER}${ENDPOINT} $CERTS
