wget -c https://github.com/jetstack/cert-manager/releases/download/v1.8.2/cert-manager.yaml
kubectl create -f cert-manager.yaml
kubectl get pods -A |grep cert-manager
kubectl delete -f cert-manager.yaml
