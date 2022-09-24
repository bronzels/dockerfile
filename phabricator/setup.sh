mkdir repos
chmod 777 repos	  
docker run \
    --name phabricator \
    --restart unless-stopped \
    -p 10080:80 -p 10443:443 -p 10022:22 \
    --env PHABRICATOR_HOST=phabricator.my.org:10080 \
    --env MYSQL_HOST=192.168.0.150 \
    --env MYSQL_USER=root \
    --env MYSQL_PASS=root \
    --env PHABRICATOR_REPOSITORY_PATH=/repos \
    -v /cdhdata1/bigopera/phabricator/repos:/repos \
    -d redpointgames/phabricator
