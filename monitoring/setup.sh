helm repo add loki https://grafana.github.io/loki/charts
helm repo update
#如果docker被安装在非缺省位置
#helm upgrade --install loki loki/loki-stack --namespace monitoring --set volumeMounts/cdhdata1/docker/containers
#helm upgrade --install loki loki/loki-stack --namespace monitoring
helm fetch loki/loki-stack --version 2.1.2
tar xzvf loki-stack-2.1.2.tgz
cd loki-stack
cp values.yaml values.yaml.bk
sed -i 's@\/var\/log\/containers@\/home\/docker\/containers@g' values.yaml
cp charts/promtail/values.yaml charts/promtail/values.yaml.bk
sed -i 's@\/var\/lib\/docker\/containers@\/home\/docker\/containers@g' charts/promtail/values.yaml
cd ..
helm install loki ./loki-stack --namespace monitoring
helm uninstall loki --namespace monitoring

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm fetch prometheus-community/kube-prometheus-stack --version 15.3.1
tar xzvf kube-prometheus-stack-15.3.1.tgz
mv kube-prometheus-stack/values.yaml kube-prometheus-stackvalues.yaml.bk
#sz values.yaml
:<<eof
#grafana管理员密码
grafana:
  adminPassword: prom-operator
eof

#repeat on all working nodes
docker pull quay.io/coreos/kube-state-metrics:v1.9.8
docker tag quay.io/coreos/kube-state-metrics:v1.9.8 k8s.gcr.io/kube-state-metrics/kube-state-metrics:v1.9.8

helm install monitor ./kube-prometheus-stack --namespace monitoring
kubectl edit svc -n monitoring monitor-grafana
:<<eof
    targetPort: 3000
    nodePort: 30300
  selector:
    app.kubernetes.io/instance: monitor
    app.kubernetes.io/name: grafana
  sessionAffinity: None
  type: NodePort
eof

helm uninstall monitor --namespace monitoring
kubectl get pod -n monitoring
