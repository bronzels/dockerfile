#!/usr/bin/env bash

/Volumes/data/workspace/dockerfile/client-upload.sh flink cdc-hudi-test-basic /opt/flink/usrlib showcatalogs.sql taskmanager
/Volumes/data/workspace/dockerfile/client-upload.sh flink cdc-hudi-test-basic /opt/flink/usrlib create_databases.sql taskmanager
/Volumes/data/workspace/dockerfile/client-upload.sh flink cdc-hudi-test-basic /opt/flink/usrlib showdatabases.sql taskmanager
/Volumes/data/workspace/dockerfile/client-upload.sh flink cdc-hudi-test-basic /opt/flink/usrlib showtables.sql taskmanager
/Volumes/data/workspace/dockerfile/client-upload.sh flink cdc-hudi-test-basic /opt/flink/usrlib dropdatabases.sql taskmanager
/Volumes/data/workspace/dockerfile/client-upload.sh flink cdc-hudi-test-basic /opt/flink/usrlib droptables.sql taskmanager
/Volumes/data/workspace/dockerfile/client-upload.sh flink cdc-hudi-test-basic /opt/flink/usrlib cdc-hudi-test-basic.sql taskmanager
/Volumes/data/workspace/dockerfile/client-upload.sh flink cdc-hudi-test-basic /opt/flink/usrlib cdc-hudi-test-basic-onlyjob.sql taskmanager
