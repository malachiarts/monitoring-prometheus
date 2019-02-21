#!/bin/env sh

sudo docker run -p 9090:9090 \
	--mount type=bind,source=/etc/prometheus,target=/etc/prometheus \
	--mount type=bind,source=/prometheus,target=/prometheus \
	--mount type=bind,source=/var/run/secrets/kubernetes.io/serviceaccount,target=/var/run/secrets/kubernetes.io/serviceaccount \
	--network prom-network \
	-d prom/prometheus \
	--config.file=/etc/prometheus/prometheus.yml
