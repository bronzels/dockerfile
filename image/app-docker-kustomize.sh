#!/bin/bash
echo "APP_DIR:${APP_DIR}"
echo "gitops_cd_git:${gitops_cd_git}"
echo "imageRepoPath:${imageRepoPath}"
echo "imageTag:${imageTag}"
echo "dockerRegistryUrl:${dockerRegistryUrl}"
echo "addHost:${addHost}"

docker login ${dockerRegistryUrl} -u ${DOCKER_HUB_USER} -p ${DOCKER_HUB_PASSWORD}
docker build ${addHost} -t ${imageRepoPath}:${imageTag} .
docker push ${imageRepoPath}:${imageTag}
docker rmi ${imageRepoPath}:${imageTag}

git remote set-url origin http://${DEVOPS_USER}:${DEVOPS_PASSWORD}@${gitops_cd_git}
git config --global user.name ${DEVOPS_USER}
git config --global user.email "bronzels@163.com"
git clone http://${DEVOPS_USER}:${DEVOPS_PASSWORD}@${gitops_cd_git} /opt/gitops-cd
cd /opt/gitops-cd
git pull
arrayAPP=(${APP_DIR//,/ })
for var in ${arrayAPP[@]}
do
	echo "var:${var}"
	if echo "$var" | grep -q -E '\.yaml$'
  then
    repoPaths=`echo $imageRepoPath | sed "s/\// /g"`
    repoName=`echo $repoPaths| awk 'NR==1{print $NF}'`
    echo "repoName:$repoName"
    sed -r "s/${repoName}\:([0123456789_a-zA-Z]*?)/$repoName:${imageTag}/g" $var
    sed -ri "s/${repoName}\:([0123456789_a-zA-Z]*?)/$repoName:${imageTag}/g" $var
  else
    cd ${var}
    kustomize edit set image ${imageRepoPath}:${imageTag}
    cd -
  fi
done
git commit -am 'image update'
git push origin master

