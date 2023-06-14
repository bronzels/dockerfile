#!/usr/bin/env bash

shortversion=$1
echo "shortversion:${shortversion}"

export FLINK_HOME=/opt/flink-${shortversion}
echo "FLINK_HOME:${FLINK_HOME}"

export PATH=${PATH}:${FLINK_HOME}/bin
echo "PATH:${PATH}"

