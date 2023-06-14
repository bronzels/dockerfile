
for namespace in 'infra' 'kubeflow' 'istio-system' 'pipeline' 'automl' 'jupyter' 'service' 'monitoring' 'logging' 'kube-system'
do
    kubectl delete secret docker-registry hubsecret -n $namespace
    kubectl delete ns $namespace
done


