
helm repo add pfisterer-hadoop https://pfisterer.github.io/apache-hadoop-helm/
helm install hadoop -n hadoop \
 pfisterer-hadoop/hadoop \
 --create-namespace
helm pull pfisterer-hadoop/hadoop