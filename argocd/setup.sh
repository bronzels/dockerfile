#2个环境都要安装argocd
kubectl apply -f install.yaml -n argocd
:<<\EOF
http://www.ab126.com/goju/10822.html
	输入argo56789
	把加密结果copy到下面的admin.password
EOF
kubectl -n argocd patch secret argocd-secret   -p '{"stringData": {
      "admin.password": "$2a$10$x.7L4gBC9CrSXcvjqW6gM.A/1hD8g2fz8APKxboJCnjVX0VRvON8W",
      "admin.passwordMtime": "'$(date +%FT%T%Z)'"
    }}'
#admin/argo56789

#kubectl delete -f install.yaml -n argocd