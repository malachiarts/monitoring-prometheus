#!/bin/sh

sudo docker run -p 443:443 \
		-v /etc/nginx/:/etc/nginx:ro \
		-v /root/certs/majustfortesting.com/:/root/certs/majustfortesting.com:ro \
		--network prom-network \
		-d nginx
