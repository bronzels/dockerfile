rm -rf helm-hadoop-3
git clone https://github.com/chenseanxy/helm-hadoop-3.git
rm -rf helm-hadoop-3.bk
cp -r helm-hadoop-3 helm-hadoop-3.bk
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    HDPHOME=/Volumes/data/workspace/cluster-sh-k8s/hadoop/helm-hadoop-3
    SED=gsed
else
    echo "Assuming linux by default."
    #linux
    HDPHOME=~/helm-hadoop-3
    SED=sed
fi

cd $HDPHOME
file=values.yaml
cp ${HDPHOME}.bk/$file $file

kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
   name: hdfs-local-storage-dn
provisioner: kubernetes.io/no-provisioner
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
EOF
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
   name: hdfs-local-storage-nn
provisioner: kubernetes.io/no-provisioner
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
EOF
kubectl get sc

ansible all -m shell -a"rm -rf /data0/hdfs"
ansible all -m shell -a"mkdir -p /data0/hdfs/pvdn"

mkdir pvs
cat << \EOF > hdfs-pv-template.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
   name: myhost-hdfs-pvdn
   labels:
     app: hdfs
spec:
   capacity:
      storage: 80Gi
   volumeMode: Filesystem
   accessModes:
   - ReadWriteOnce
   persistentVolumeReclaimPolicy: Retain
   storageClassName: hdfs-local-storage-dn
   local:
      path: /data0/hdfs/pvdn
   nodeAffinity:
      required:
         nodeSelectorTerms:
         - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
              - myhost
EOF

sudo ssh dtpct mkdir -p /data0/hdfs/pvnn
cat << \EOF > hdfs-pv-nn.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
   name: dtpct-hdfs-pvnn
   labels:
     app: hdfs
spec:
   capacity:
      storage: 20Gi
   volumeMode: Filesystem
   accessModes:
   - ReadWriteOnce
   persistentVolumeReclaimPolicy: Retain
   storageClassName: hdfs-local-storage-nn
   local:
      path: /data0/hdfs/pvnn
   nodeAffinity:
      required:
         nodeSelectorTerms:
         - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
              - dtpct
EOF
kubectl apply -f hdfs-pv-nn.yaml
kubectl delete -f hdfs-pv-nn.yaml

for myhost in {dtpct,mdubu,mdlapubu}
do
  echo "myhost:${myhost}"
  cp hdfs-pv-template.yaml pvs/hdfs-pv-${myhost}.yaml
  sed -i "" "s/myhost/${myhost}/g" pvs/hdfs-pv-${myhost}.yaml
  cat pvs/hdfs-pv-${myhost}.yaml
done

kubectl apply -f pvs/
kubectl delete -f pvs/
kubectl get pv

find $HDPHOME -name "*.yaml" | xargs grep "apps/v1beta1"
find $HDPHOME -name "*.yaml" | xargs $SED -i 's@apps/v1beta1@apps/v1@g'

$SED -i '/  serviceName:/i\  selector:\n    matchLabels:\n      app: {{ include "hadoop.name" . }}' templates/yarn-nm-statefulset.yaml
$SED -i '/  serviceName:/i\  selector:\n    matchLabels:\n      app: {{ include "hadoop.name" . }}' templates/hdfs-dn-statefulset.yaml
$SED -i '/  serviceName:/i\  selector:\n    matchLabels:\n      app: {{ include "hadoop.name" . }}' templates/yarn-rm-statefulset.yaml
$SED -i '/  serviceName:/i\  selector:\n    matchLabels:\n      app: {{ include "hadoop.name" . }}' templates/hdfs-nn-statefulset.yaml

file=templates/hadoop-configmap.yaml
cp ../helm-hadoop-3.bk/$file $file
#$SED -i 's@@@g' $file

rm -f templates/hdfs-dn-pvc.yaml

file=templates/hdfs-dn-statefulset.yaml
cp ../helm-hadoop-3.bk/$file $file
cat << \EOF > templates/hdfs-dn-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ include "hadoop.fullname" . }}-hdfs-dn
  annotations:
    checksum/config: {{ include (print $.Template.BasePath "/hadoop-configmap.yaml") . | sha256sum }}
  labels:
    app: {{ include "hadoop.name" . }}
    chart: {{ include "hadoop.chart" . }}
    release: {{ .Release.Name }}
    component: hdfs-dn
spec:
  selector:
      matchLabels:
        app: {{ include "hadoop.name" . }}
  serviceName: {{ include "hadoop.fullname" . }}-hdfs-dn
  replicas: {{ .Values.hdfs.dataNode.replicas }}
  template:
    metadata:
      labels:
        app: {{ include "hadoop.name" . }}
        release: {{ .Release.Name }}
        component: hdfs-dn
    spec:
      affinity:
        podAntiAffinity:
        {{- if eq .Values.antiAffinity "hard" }}
          requiredDuringSchedulingIgnoredDuringExecution:
          - topologyKey: "kubernetes.io/hostname"
            labelSelector:
              matchLabels:
                app:  {{ include "hadoop.name" . }}
                release: {{ .Release.Name | quote }}
                component: hdfs-dn
        {{- else if eq .Values.antiAffinity "soft" }}
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 5
            podAffinityTerm:
              topologyKey: "kubernetes.io/hostname"
              labelSelector:
                matchLabels:
                  app:  {{ include "hadoop.name" . }}
                  release: {{ .Release.Name | quote }}
                  component: hdfs-dn
        {{- end }}
      terminationGracePeriodSeconds: 0
      containers:
      - name: hdfs-dn
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy | quote }}
        command:
           - "/bin/bash"
           - "/tmp/hadoop-config/bootstrap.sh"
           - "-d"
        resources:
{{ toYaml .Values.hdfs.dataNode.resources | indent 10 }}
        readinessProbe:
          httpGet:
            path: /
            port: 9864
          initialDelaySeconds: 5
          timeoutSeconds: 2
        livenessProbe:
          httpGet:
            path: /
            port: 9864
          initialDelaySeconds: 10
          timeoutSeconds: 2
        volumeMounts:
        - name: hadoop-config
          mountPath: /tmp/hadoop-config
        - name: dfs
          mountPath: /root/hdfs/datanode
      volumes:
      - name: hadoop-config
        configMap:
          name: {{ include "hadoop.fullname" . }}
      {{- if not .Values.persistence.dataNode.enabled }}
      - name: dfs
        emptyDir: {}
      {{- end }}
  {{- if .Values.persistence.dataNode.enabled }}
  volumeClaimTemplates:
    - metadata:
        name: dfs
      spec:
        accessModes:
          - {{ .Values.persistence.dataNode.accessMode | quote }}
        resources:
          requests:
            storage: {{ .Values.persistence.dataNode.size | quote }}
      {{- if .Values.persistence.dataNode.storageClass }}
        {{- if (eq "-" .Values.persistence.dataNode.storageClass) }}
        storageClassName: ""
        {{- else }}
        storageClassName: "{{ .Values.persistence.dataNode.storageClass }}"
        {{- end }}
      {{- end }}
  {{- end }}
EOF


