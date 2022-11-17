docker run -itd -p 8081:8081 --privileged=true --name nexus3 \
-v /Volumes/data/nexus:/var/nexus-data --restart=always sonatype/nexus3
