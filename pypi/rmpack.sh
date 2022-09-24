#!/bin/bash
#put into same folder of pypi repo
p="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "$p"
cd $p

repo_name=$1
echo repo_name:${repo_name}
rev=$2
echo rev:${rev}

if ls ${repo_name}-${rev}* 1> /dev/null 2>&1; then
rm -f ${repo_name}-${rev}*
fi

