kubectl apply -f rbac.yaml -f rbac-kube-system.yaml
kubectl apply -f class.yaml
kubectl get sc
kubectl create ns kubernetes-plugin
kubectl apply -f deployment.yaml
kubectl get all -n kubernetes-plugin

kubectl create -f test-claim.yaml test-pod.yaml
kubectl get pvc
kubectl get pod
kubectl delete -f test-claim.yaml test-pod.yaml

kubectl patch storageclass managed-nfs-storage -p '{"metadata": {"annotations":{"storageclass.beta.kubernetes.io/is-default-class":"true"}}}'