kubectl get pods -A |grep -v 'Running\|ContainerCreating\|Pending\|Init' |awk '{printf("kubectl delete pods %s -n %s --force --grace-period=0\n", $2,$1)}' | /bin/bash

