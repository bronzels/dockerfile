#!/usr/bin/env bash
SESSION=$1
kubectl exec -it -n flink `kubectl get pod -n flink | grep ${SESSION} | grep -v taskmanager | awk '{print $1}'` -- sql-client.sh embedded -i usrlib/setting.sql