-- create database
CREATE DATABASE IF NOT EXISTS streamx DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
-- create user and grant authorization
GRANT ALL ON streamx.* TO 'streamx'@'%' IDENTIFIED BY '${USER_IDENTIFIER}';
USE streamx;
