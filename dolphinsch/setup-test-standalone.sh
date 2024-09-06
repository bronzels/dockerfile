tar -xvzf apache-dolphinscheduler-${DOLPHINSCH_REV}-bin.tar.gz
chmod -R 755 apache-dolphinscheduler-${DOLPHINSCH_REV}-bin
cd apache-dolphinscheduler-${DOLPHINSCH_REV}-bin
bash ./bin/dolphinscheduler-daemon.sh start standalone-server