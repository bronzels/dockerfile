helm repo add traefik https://containous.github.io/traefik-helm-chart
helm repo update
helm pull traefik/traefik
#traefik-9.1.1.tgz
cd traefik
helm install mytrf ./ -n cattle-system
helm uninstall mytrf -n cattle-system
#替换values.yaml
kubectl apply -f traefik-service-monitor.yaml
#prometheus用monitor的名字安装在monitoring的ns