kubectl create ns argo

wget -c https://raw.githubusercontent.com/argoproj/argo/stable/manifests/install.yaml
kubectl apply -n argo -f install.yaml
#kubectl delete -n argo -f install.yaml
wget -c https://raw.githubusercontent.com/argoproj/argo-workflows/stable/manifests/quick-start-postgres.yaml
#kubectl apply -n argo -f quick-start-postgres.yaml
#kubectl delete -n argo -f quick-start-postgres.yaml
kubectl edit svc -n argo argo-server
:<<\EOF
spec:
  ports:
  - name: web
    port: 2746
    protocol: TCP
    targetPort: 2746
    nodePort: 30501
  selector:
    app: argo-server
  sessionAffinity: None
  type: NodePort
status:
  loadBalancer: {}
EOF

curl -sLO https://github.com/argoproj/argo/releases/download/v3.0.2/argo-linux-amd64.gz
gunzip argo-linux-amd64.gz
chmod +x argo-linux-amd64
#mv ./argo-linux-amd64 /usr/bin/argo
sudo ln -s ${PWD}/argo-linux-amd64 /usr/bin/argo
argo version

cat << \EOF > argowf-hello-world.yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: hello-world-
  labels:
    workflows.argoproj.io/archive-strategy: "false"
spec:
  entrypoint: whalesay
  templates:
  - name: whalesay
    container:
      image: docker/whalesay:latest
      command: [cowsay]
      args: ["hello world"]
EOF
argo submit --watch argowf-hello-world.yaml
argo list
argo delete hello-world-bpd82
cat << \EOF > argowf-hello-world.yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: wf-hello-world
  labels:
    workflows.argoproj.io/archive-strategy: "false"
spec:
  entrypoint: whalesay
  templates:
  - name: whalesay
    container:
      image: docker/whalesay:latest
      command: [cowsay]
      args: ["hello world"]
EOF
kubectl apply -n batchpy -f argowf-hello-world.yaml
argo list -n batchpy
argo delete -n batchpy wf-hello-world

cat << \EOF > dag-diamond-steps.yaml
# The following workflow executes a diamond workflow
#
#   A
#  / \
# B   C
#  \ /
#   D
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: dag-diamond
spec:
  entrypoint: diamond
  templates:
  - name: diamond
    dag:
      tasks:
      - name: A
        template: echo
        arguments:
          parameters: [{name: message, value: A}]
      - name: B
        dependencies: [A]
        template: echo
        arguments:
          parameters: [{name: message, value: B}]
      - name: C
        dependencies: [A]
        template: echo
        arguments:
          parameters: [{name: message, value: C}]
      - name: D
        dependencies: [B, C]
        template: echo
        arguments:
          parameters: [{name: message, value: D}]

  - name: echo
    inputs:
      parameters:
      - name: message
    container:
      image: alpine:3.7
      command: [echo, "{{inputs.parameters.message}}"]
EOF
kubectl apply -n batchpy -f dag-diamond-steps.yaml
argo list -n batchpy
argo delete -n batchpy dag-diamond

#  schedule: "10 * * * *"
#  schedule: "33 11 * * *"
cat << \EOF > cron.yaml
apiVersion: argoproj.io/v1alpha1
kind: CronWorkflow
metadata:
  name: hourly-10min-job
spec:
  # run daily at 11:33 am
  timezone: "Asia/Shanghai"
  schedule: "10 * * * *"
  workflowSpec:
    entrypoint: whalesay
    templates:
      - name: whalesay
        container:
          env:
            - name: MY_POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
          image: docker/whalesay:latest
          command: [cowsay]
          args: ["$(MY_POD_NAME)"]
EOF
kubectl apply -n batchpy -f cron.yaml
argo cron list -n batchpy
argo cron delete -n batchpy minutely-job

