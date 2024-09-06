#!/bin/bash
echo "imageRepoPathPrefix:${imageRepoPathPrefix}"
echo "dockerRegistryUrl:${dockerRegistryUrl}"
echo "imageTag:${imageTag}"
echo "addHost:${addHost}"
echo "gitops_cd_git:${gitops_cd_git}"
echo "imageRepoPathPrefix:${imageRepoPathPrefix}"

whodeps=`cat whodeps.json`
arr_wdruleout=(`echo "$whodeps" | jq -r '.wdruleout[]|"\(.wdname)"'`)

git remote set-url origin http://${DEVOPS_USER}:${DEVOPS_PASSWORD}@${gitops_cd_git}
git config --global user.name ${DEVOPS_USER}
git config --global user.email "bronzels@163.com"
git clone http://${DEVOPS_USER}:${DEVOPS_PASSWORD}@${gitops_cd_git} /opt/gitops-cd

counter=0
while read wdname wdgiturl ; do
	[[ ${arr_wdruleout[@]/${wdname}/} != ${arr_wdruleout[@]} ]] && continue || echo "${wdname} included"
	counter=$((counter+1))
	echo "wdname:${wdname}"
	echo "wdgiturl:${wdgiturl}"
	wdImageRepoPath="${imageRepoPathPrefix}/${wdname}"
	echo "wdImageRepoPath:${wdImageRepoPath}"

	git remote set-url origin http://${CODE_GIT_USER}:${CODE_GIT_PASSWORD}@${wdgiturl}
	git config --global user.name ${CODE_GIT_USER}
	git config --global user.email "bronzels@163.com"
	git clone http://${CODE_GIT_USER}:${CODE_GIT_PASSWORD}@${wdgiturl} /opt/${wdname}
	cd /opt/${wdname}
	wdkustpath=`cat cdpath`
        echo "wdkustpath:${wdkustpath}"
        wdImageRepoPath="${imageRepoPathPrefix}/${wdname}"
        echo "wdImageRepoPath:${wdImageRepoPath}"

	docker login ${dockerRegistryUrl} -u ${DOCKER_HUB_USER} -p ${DOCKER_HUB_PASSWORD}
	docker build ${addHost} -t ${wdImageRepoPath}:${imageTag} .
	docker push ${wdImageRepoPath}:${imageTag}
	docker rmi ${wdImageRepoPath}:${imageTag}

	cd /opt/gitops-cd/${wdkustpath}
        kustomize edit set image ${wdImageRepoPath}:${imageTag}
done < <(echo "$whodeps" | jq -r '.whodeps[]|"\(.wdname) \(.wdgiturl)"')

if [ $counter -gt 0 ]; then
  git remote set-url origin http://${DEVOPS_USER}:${DEVOPS_PASSWORD}@${gitops_cd_git}
  git config --global user.name ${DEVOPS_USER}
  git config --global user.email "bronzels@163.com"
  git commit -am 'image update'
  git push origin master
fi

