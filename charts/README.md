# RUNNING

With these values for prometheus-operator, we're not installing Prometheus, Alertmanager or Grafana in our k8s cluster. We're running those outside the cluster since, if the cluster goes down, you won't be alerted! So our `values.yaml` is configured to just install kube-state-metrics, node-exporter and the prometheus-operator `shims` for kube-scheduler, kube-controller-manager, kubelt and etcd. May be able to turn off coredns since the endpoints are already discovered.

```bash
kubectl create -f monitoring-namespace.json
# https://github.com/helm/charts/issues/9941#issuecomment-447844259
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheusrule.crd.yaml
# prometheusOperator.createCustomResource= false
helm tiller run -- helm install --debug --name=monitoring --namespace=monitoring --values=values.yaml stable/prometheus-operator
```

# DEBUGGING

When completed, you'll have these "shims" to specific Kubernetes
endpoints. If the ENDPOINTS column is "none", then it didn't work
properly.

```bash
$ k get endpoints -n kube-system
NAME                                                 ENDPOINTS                                                           AGE
coredns                                              10.233.120.21:53,10.233.80.45:53,10.233.120.21:53 + 3 more...       59d
dnsmasq                                              10.233.80.46:53,10.233.92.5:53,10.233.80.46:53 + 1 more...          100d
kube-controller-manager                              <none>                                                              100d
kube-scheduler                                       <none>                                                              100d
kubernetes-dashboard                                 10.233.80.44:8443                                                   100d
metrics-server                                       10.233.84.5:443                                                     79d
monitoring-prometheus-oper-coredns                   <none>                                                              17h
monitoring-prometheus-oper-kube-controller-manager   <none>                                                              17h
monitoring-prometheus-oper-kube-etcd                 10.77.1.116:2379,10.77.1.69:2379,10.77.2.22:2379                    17h
monitoring-prometheus-oper-kube-scheduler            <none>                                                              17h
monitoring-prometheus-oper-kubelet                   10.77.1.121:10255,10.77.1.13:10255,10.77.1.249:10255 + 15 more...   17h
tiller-deploy                                        10.233.84.12:44134                                                  80d
```

In our clusters, we ran etcd as separate instances so we have
to specify the IP addresses in our values.yaml file.

However, scheduler and controller-manager are running as pods.

```bash
$ k get pods -n kube-system | egrep '(controller-manager|scheduler)'
kube-controller-manager-ip-10-77-1-121.us-west-2.compute.internal   1/1     Running   80         73d
kube-controller-manager-ip-10-77-1-5.us-west-2.compute.internal     1/1     Running   44         95d
kube-controller-manager-ip-10-77-2-208.us-west-2.compute.internal   1/1     Running   68         95d
kube-scheduler-ip-10-77-1-121.us-west-2.compute.internal            1/1     Running   72         73d
kube-scheduler-ip-10-77-1-5.us-west-2.compute.internal              1/1     Running   54         95d
kube-scheduler-ip-10-77-2-208.us-west-2.compute.internal            1/1     Running   66         73d
```

So why aren't they showing up? In our `values.yaml` file, we have the
following:

```yaml
  service:
    port: 10252
    targetPort: 10252
    selector:
      component: kube-controller-manager
```

Lets test the selector:

```bash
$ k describe pods -n kube-system -l component=kube-controller-manager
```

And nothing comes back. Now it's time to check the labels.

```bash
$ k describe pod -n kube-system kube-controller-manager-ip-10-77-1-5.us-west-2.compute.internal | grep Label
Labels:             k8s-app=kube-controller-manager
```

Right there we see that the label is k8s-app and not component. To
verify:

```bash
$ k get pods -l k8s-app=kube-controller-manager -n kube-system
kube-controller-manager-ip-10-77-1-121.us-west-2.compute.internal   1/1     Running   80         73d
kube-controller-manager-ip-10-77-1-5.us-west-2.compute.internal     1/1     Running   44         95d
kube-controller-manager-ip-10-77-2-208.us-west-2.compute.internal   1/1     Running   68         95d
```

Perfect! Now we'll change our `values.yaml` file so it looks like:

```yaml
  service:
    port: 10252
    targetPort: 10252
    selector:
      k8s-app: kube-controller-manager
```

In our case, kube-scheduler had a similar selector and we had to also
change it from `component` to `k8s-app`.

Update our chart deployment and we should start seeing endpoints for
controller-manager which should mean that data will start to flow
through Prometheus.

```bash
$ helm tiller run -- helm upgrade --values=values.yaml monitoring stable/prometheus-operator
```

To verify:

```bash
$ k get endpoints -n kube-system
NAME                                                 ENDPOINTS                                                           AGE
coredns                                              10.233.120.21:53,10.233.80.45:53,10.233.120.21:53 + 3 more...       59d
dnsmasq                                              10.233.80.46:53,10.233.92.5:53,10.233.80.46:53 + 1 more...          100d
kube-controller-manager                              <none>                                                              100d
kube-scheduler                                       <none>                                                              100d
kubernetes-dashboard                                 10.233.80.44:8443                                                   100d
metrics-server                                       10.233.84.5:443                                                     79d
monitoring-prometheus-oper-coredns                   <none>                                                              17h
monitoring-prometheus-oper-kube-controller-manager   10.77.1.121:10252,10.77.1.5:10252,10.77.2.208:10252                 17h
monitoring-prometheus-oper-kube-etcd                 10.77.1.116:2379,10.77.1.69:2379,10.77.2.22:2379                    17h
monitoring-prometheus-oper-kube-scheduler            10.77.1.121:10251,10.77.1.5:10251,10.77.2.208:10251                 17h
monitoring-prometheus-oper-kubelet                   10.77.1.121:10255,10.77.1.13:10255,10.77.1.249:10255 + 15 more...   17h
tiller-deploy                                        10.233.84.12:44134                                                  80d
```

Much better!
