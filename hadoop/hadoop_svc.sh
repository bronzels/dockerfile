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
#HDPHOME=~/charts/stable/hadoop

cat << \EOF > $HDPHOME/templates/yarn-rm-web-svc.yaml
# A headless service to create DNS records
apiVersion: v1
kind: Service
metadata:
  name: {{ include "hadoop.fullname" . }}-yarn-rm-web
  labels:
    app: {{ include "hadoop.name" . }}
    chart: {{ include "hadoop.chart" . }}
    release: {{ .Release.Name }}
    component: yarn-rm
spec:
  type: NodePort
  ports:
  - port: 8088
    name: web
    nodePort: 31088
  selector:
    app: {{ include "hadoop.name" . }}
    release: {{ .Release.Name }}
    component: yarn-rm
EOF

cat << \EOF > $HDPHOME/templates/hdfs-nn-web-svc.yaml
# A headless service to create DNS records
apiVersion: v1
kind: Service
metadata:
  name: {{ include "hadoop.fullname" . }}-hdfs-nn-web
  labels:
    app: {{ include "hadoop.name" . }}
    chart: {{ include "hadoop.chart" . }}
    release: {{ .Release.Name }}
    component: hdfs-nn
spec:
  type: NodePort
  ports:
  - port: 50070
    name: web
    nodePort: 30870
  selector:
    app: {{ include "hadoop.name" . }}
    release: {{ .Release.Name }}
    component: hdfs-nn
EOF
$SED -i 's@- port: 50070@- port: 9870@g' $HDPHOME/templates/hdfs-nn-web-svc.yaml

