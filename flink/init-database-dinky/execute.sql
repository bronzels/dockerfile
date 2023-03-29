-- create database
CREATE DATABASE IF NOT EXISTS dlink DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
-- create user and grant authorization
GRANT ALL ON dlink.* TO 'dlink'@'%' IDENTIFIED BY '${DINKY_IDENTIFIED}';

USE dlink;

SET NAMES utf8mb4;


-- ----------------------------
-- Table structure for dlink_alert_group
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_alert_group` (
                                     `id` int NOT NULL AUTO_INCREMENT COMMENT 'id',
                                     `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'alert group name',
                                     `tenant_id` int NOT NULL DEFAULT '1' COMMENT 'tenant id',
                                     `alert_instance_ids` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT 'Alert instance IDS',
                                     `note` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'note',
                                     `enabled` tinyint DEFAULT '1' COMMENT 'is enable',
                                     `create_time` datetime DEFAULT NULL COMMENT 'create time',
                                     `update_time` datetime DEFAULT NULL COMMENT 'update time',
                                     PRIMARY KEY (`id`) USING BTREE,
                                     UNIQUE KEY `dlink_alert_instance_un` (`name`,`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='Alert group';


-- ----------------------------
-- Table structure for dlink_alert_history
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_alert_history` (
                                       `id` int NOT NULL AUTO_INCREMENT COMMENT 'id',
                                       `tenant_id` int NOT NULL DEFAULT '1' COMMENT 'tenant id',
                                       `alert_group_id` int DEFAULT NULL COMMENT 'Alert group ID',
                                       `job_instance_id` int DEFAULT NULL COMMENT 'job instance ID',
                                       `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'alert title',
                                       `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT 'content description',
                                       `status` int DEFAULT NULL COMMENT 'alert status',
                                       `log` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT 'log',
                                       `create_time` datetime DEFAULT NULL COMMENT 'create time',
                                       `update_time` datetime DEFAULT NULL COMMENT 'update time',
                                       PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='Alert history';


-- ----------------------------
-- Table structure for dlink_alert_instance
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_alert_instance` (
                                        `id` int NOT NULL AUTO_INCREMENT COMMENT 'id',
                                        `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'alert instance name',
                                        `tenant_id` int NOT NULL DEFAULT '1' COMMENT 'tenant id',
                                        `type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'alert instance type such as: DingTalk,Wechat(Webhook,app) Feishu ,email',
                                        `params` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT 'configuration',
                                        `enabled` tinyint DEFAULT '1' COMMENT 'is enable',
                                        `create_time` datetime DEFAULT NULL COMMENT 'create time',
                                        `update_time` datetime DEFAULT NULL COMMENT 'update time',
                                        PRIMARY KEY (`id`) USING BTREE,
                                        UNIQUE KEY `dlink_alert_instance_un` (`name`,`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='Alert instance';


-- ----------------------------
-- Table structure for dlink_catalogue
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_catalogue` (
                                   `id` int NOT NULL AUTO_INCREMENT COMMENT 'ID',
                                   `tenant_id` int NOT NULL DEFAULT '1' COMMENT 'tenant id',
                                   `task_id` int DEFAULT NULL COMMENT 'Job ID',
                                   `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'Job Name',
                                   `type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'Job Type',
                                   `parent_id` int NOT NULL DEFAULT '0' COMMENT 'parent ID',
                                   `enabled` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'is enable',
                                   `is_leaf` tinyint(1) NOT NULL COMMENT 'is leaf node',
                                   `create_time` datetime DEFAULT NULL COMMENT 'create time',
                                   `update_time` datetime DEFAULT NULL COMMENT 'update time',
                                   PRIMARY KEY (`id`) USING BTREE,
                                   UNIQUE KEY `dlink_catalogue_un` (`name`,`parent_id`,`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='catalogue';


-- ----------------------------
-- Table structure for dlink_cluster
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_cluster` (
                                 `id` int NOT NULL AUTO_INCREMENT COMMENT 'ID',
                                 `tenant_id` int NOT NULL DEFAULT '1' COMMENT 'tenant id',
                                 `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'cluster instance name',
                                 `alias` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'cluster instance alias',
                                 `type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'cluster types',
                                 `hosts` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT 'cluster hosts',
                                 `job_manager_host` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'Job Manager Host',
                                 `version` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'version',
                                 `status` int DEFAULT NULL COMMENT 'cluster status',
                                 `note` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'note',
                                 `auto_registers` tinyint(1) DEFAULT '0' COMMENT 'is auto registration',
                                 `cluster_configuration_id` int DEFAULT NULL COMMENT 'cluster configuration id',
                                 `task_id` int DEFAULT NULL COMMENT 'task ID',
                                 `enabled` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'is enable',
                                 `application_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'Resource Manger Address',
                                 `resource_manager_addr` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'Application Id',
                                 `create_time` datetime DEFAULT NULL COMMENT 'create time',
                                 `update_time` datetime DEFAULT NULL COMMENT 'update time',
                                 PRIMARY KEY (`id`) USING BTREE,
                                 UNIQUE KEY `dlink_cluster_un` (`name`,`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='cluster instance management';


-- ----------------------------
-- Table structure for dlink_cluster_configuration
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_cluster_configuration` (
                                               `id` int NOT NULL AUTO_INCREMENT COMMENT 'ID',
                                               `tenant_id` int NOT NULL DEFAULT '1' COMMENT 'tenant id',
                                               `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'cluster configuration name',
                                               `alias` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'cluster configuration alias',
                                               `type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'cluster type',
                                               `config_json` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT 'json of configuration',
                                               `is_available` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'is available',
                                               `note` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'note',
                                               `enabled` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'is enable',
                                               `create_time` datetime DEFAULT NULL COMMENT 'create time',
                                               `update_time` datetime DEFAULT NULL COMMENT 'update time',
                                               PRIMARY KEY (`id`),
                                               UNIQUE KEY `dlink_cluster_configuration_un` (`name`,`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='cluster configuration management';


-- ----------------------------
-- Table structure for dlink_database
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_database` (
                                  `id` int NOT NULL AUTO_INCREMENT COMMENT 'ID',
                                  `tenant_id` int NOT NULL DEFAULT '1' COMMENT 'tenant id',
                                  `name` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'database name',
                                  `alias` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'database alias',
                                  `group_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'Default' COMMENT 'database belong group name',
                                  `type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'database type',
                                  `ip` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'database ip',
                                  `port` int DEFAULT NULL COMMENT 'database port',
                                  `url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'database url',
                                  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'username',
                                  `password` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'password',
                                  `note` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'note',
                                  `flink_config` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT 'Flink configuration',
                                  `flink_template` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT 'Flink template',
                                  `db_version` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'version，such as: 11g of oracle ，2.2.3 of hbase',
                                  `status` tinyint(1) DEFAULT NULL COMMENT 'heartbeat status',
                                  `health_time` datetime DEFAULT NULL COMMENT 'last heartbeat time of trigger',
                                  `heartbeat_time` datetime DEFAULT NULL COMMENT 'last heartbeat time',
                                  `enabled` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'is enable',
                                  `create_time` datetime DEFAULT NULL COMMENT 'create time',
                                  `update_time` datetime DEFAULT NULL COMMENT 'update time',
                                  PRIMARY KEY (`id`) USING BTREE,
                                  UNIQUE KEY `dlink_database_un` (`name`,`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='database management';


-- ----------------------------
-- Table structure for dlink_flink_document
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_flink_document` (
                                        `id` int NOT NULL AUTO_INCREMENT COMMENT 'id',
                                        `category` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'document category',
                                        `type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'document type',
                                        `subtype` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'document subtype',
                                        `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'document name',
                                        `description` longtext COLLATE utf8mb4_general_ci,
                                        `fill_value` longtext COLLATE utf8mb4_general_ci COMMENT 'fill value',
                                        `version` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'document version such as:(flink1.12,flink1.13,flink1.14,flink1.15)',
                                        `like_num` int DEFAULT '0' COMMENT 'like number',
                                        `enabled` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'is enable',
                                        `create_time` datetime DEFAULT NULL COMMENT 'create time',
                                        `update_time` datetime DEFAULT NULL COMMENT 'update_time',
                                        PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='flink document management';


-- ----------------------------
-- Table structure for dlink_history
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_history` (
                                 `id` int NOT NULL AUTO_INCREMENT COMMENT 'ID',
                                 `tenant_id` int NOT NULL DEFAULT '1' COMMENT 'tenant id',
                                 `cluster_id` int NOT NULL DEFAULT '0' COMMENT 'cluster ID',
                                 `cluster_configuration_id` int DEFAULT NULL COMMENT 'cluster configuration id',
                                 `session` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'session',
                                 `job_id` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'Job ID',
                                 `job_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'Job Name',
                                 `job_manager_address` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'JJobManager Address',
                                 `status` int NOT NULL DEFAULT '0' COMMENT 'status',
                                 `type` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'job type',
                                 `statement` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT 'statement set',
                                 `error` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT 'error message',
                                 `result` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT 'result set',
                                 `config_json` json DEFAULT NULL COMMENT 'config json',
                                 `start_time` datetime DEFAULT NULL COMMENT 'job start time',
                                 `end_time` datetime DEFAULT NULL COMMENT 'job end time',
                                 `task_id` int DEFAULT NULL COMMENT 'task ID',
                                 PRIMARY KEY (`id`) USING BTREE,
                                 KEY `task_index` (`task_id`) USING BTREE,
                                 KEY `cluster_index` (`cluster_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='execution history';


-- ----------------------------
-- Table structure for dlink_jar
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_jar` (
                             `id` int NOT NULL AUTO_INCREMENT COMMENT 'ID',
                             `tenant_id` int NOT NULL DEFAULT '1' COMMENT 'tenant id',
                             `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'jar name',
                             `alias` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'jar alias',
                             `type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'jar type',
                             `path` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'file path',
                             `main_class` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'application of main class',
                             `paras` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'main class of args',
                             `note` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'note',
                             `enabled` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'is enable',
                             `create_time` datetime DEFAULT NULL COMMENT 'create time',
                             `update_time` datetime DEFAULT NULL COMMENT 'update time',
                             PRIMARY KEY (`id`),
                             UNIQUE KEY `dlink_jar_un` (`tenant_id`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='jar management';


-- ----------------------------
-- Table structure for dlink_job_history
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_job_history` (
                                     `id` int NOT NULL COMMENT 'id',
                                     `tenant_id` int NOT NULL DEFAULT '1' COMMENT 'tenant id',
                                     `job_json` json DEFAULT NULL COMMENT 'Job information json',
                                     `exceptions_json` json DEFAULT NULL COMMENT 'error message json',
                                     `checkpoints_json` json DEFAULT NULL COMMENT 'checkpoints json',
                                     `checkpoints_config_json` json DEFAULT NULL COMMENT 'checkpoints configuration json',
                                     `config_json` json DEFAULT NULL COMMENT 'configuration',
                                     `jar_json` json DEFAULT NULL COMMENT 'Jar configuration',
                                     `cluster_json` json DEFAULT NULL COMMENT 'cluster instance configuration',
                                     `cluster_configuration_json` json DEFAULT NULL COMMENT 'cluster config',
                                     `update_time` datetime DEFAULT NULL COMMENT 'update time',
                                     PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='Job history details';


-- ----------------------------
-- Table structure for dlink_job_instance
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_job_instance` (
                                      `id` int NOT NULL AUTO_INCREMENT COMMENT 'id',
                                      `name` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'job instance name',
                                      `tenant_id` int NOT NULL DEFAULT '1' COMMENT 'tenant id',
                                      `task_id` int DEFAULT NULL COMMENT 'task ID',
                                      `step` int DEFAULT NULL COMMENT 'job lifecycle',
                                      `cluster_id` int DEFAULT NULL COMMENT 'cluster ID',
                                      `jid` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'Flink JobId',
                                      `status` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'job instance status',
                                      `history_id` int DEFAULT NULL COMMENT 'execution history ID',
                                      `create_time` datetime DEFAULT NULL COMMENT 'create time',
                                      `update_time` datetime DEFAULT NULL COMMENT 'update time',
                                      `finish_time` datetime DEFAULT NULL COMMENT 'finish time',
                                      `duration` bigint DEFAULT NULL COMMENT 'job duration',
                                      `error` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT 'error logs',
                                      `failed_restart_count` int DEFAULT NULL COMMENT 'failed restart count',
                                      PRIMARY KEY (`id`) USING BTREE,
                                      UNIQUE KEY `dlink_job_instance_un` (`tenant_id`,`name`,`task_id`,`history_id`),
                                      KEY `dlink_job_instance_task_id_IDX` (`task_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='job instance';


-- ----------------------------
-- Table structure for dlink_savepoints
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_savepoints` (
                                    `id` int NOT NULL AUTO_INCREMENT COMMENT 'ID',
                                    `task_id` int NOT NULL COMMENT 'task ID',
                                    `tenant_id` int NOT NULL DEFAULT '1' COMMENT 'tenant id',
                                    `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'task name',
                                    `type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'savepoint type',
                                    `path` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'savepoint path',
                                    `create_time` datetime DEFAULT NULL COMMENT 'create time',
                                    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='job savepoint management';


-- ----------------------------
-- Table structure for dlink_schema_history
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_schema_history` (
                                        `installed_rank` int NOT NULL,
                                        `version` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
                                        `description` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
                                        `type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
                                        `script` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
                                        `checksum` int DEFAULT NULL,
                                        `installed_by` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
                                        `installed_on` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                        `execution_time` int NOT NULL,
                                        `success` tinyint(1) NOT NULL,
                                        PRIMARY KEY (`installed_rank`) USING BTREE,
                                        KEY `dlink_schema_history_s_idx` (`success`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;


-- ----------------------------
-- Table structure for dlink_sys_config
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_sys_config` (
                                    `id` int NOT NULL AUTO_INCREMENT COMMENT 'ID',
                                    `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'configuration name',
                                    `value` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT 'configuration value',
                                    `create_time` datetime DEFAULT NULL COMMENT 'create time',
                                    `update_time` datetime DEFAULT NULL COMMENT 'update time',
                                    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='system configuration';


-- ----------------------------
-- Table structure for dlink_task
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_task` (
                              `id` int NOT NULL AUTO_INCREMENT COMMENT 'ID',
                              `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'Job name',
                              `tenant_id` int NOT NULL DEFAULT '1' COMMENT 'tenant id',
                              `alias` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'Job alias',
                              `dialect` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'dialect',
                              `type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'Job type',
                              `check_point` int DEFAULT NULL COMMENT 'CheckPoint trigger seconds',
                              `save_point_strategy` int DEFAULT NULL COMMENT 'SavePoint strategy',
                              `save_point_path` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'SavePointPath',
                              `parallelism` int DEFAULT NULL COMMENT 'parallelism',
                              `fragment` tinyint(1) DEFAULT '0' COMMENT 'fragment',
                              `statement_set` tinyint(1) DEFAULT '0' COMMENT 'enable statement set',
                              `batch_model` tinyint(1) DEFAULT '0' COMMENT 'use batch model',
                              `cluster_id` int DEFAULT NULL COMMENT 'Flink cluster ID',
                              `cluster_configuration_id` int DEFAULT NULL COMMENT 'cluster configuration ID',
                              `database_id` int DEFAULT NULL COMMENT 'database ID',
                              `jar_id` int DEFAULT NULL COMMENT 'Jar ID',
                              `env_id` int DEFAULT NULL COMMENT 'env id',
                              `alert_group_id` bigint DEFAULT NULL COMMENT 'alert group id',
                              `config_json` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT 'configuration json',
                              `note` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'Job Note',
                              `step` int DEFAULT NULL COMMENT 'Job lifecycle',
                              `job_instance_id` bigint DEFAULT NULL COMMENT 'job instance id',
                              `enabled` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'is enable',
                              `create_time` datetime DEFAULT NULL COMMENT 'create time',
                              `update_time` datetime DEFAULT NULL COMMENT 'update time',
                              `version_id` int DEFAULT NULL COMMENT 'version id',
                              PRIMARY KEY (`id`) USING BTREE,
                              UNIQUE KEY `dlink_task_un` (`name`,`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='Task';


-- ----------------------------
-- Table structure for dlink_task_statement
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_task_statement` (
                                        `id` int NOT NULL COMMENT 'ID',
                                        `tenant_id` int NOT NULL DEFAULT '1' COMMENT 'tenant id',
                                        `statement` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT 'statement set',
                                        PRIMARY KEY (`id`) USING BTREE,
                                        UNIQUE KEY `dlink_task_statement_un` (`tenant_id`,`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='statement';


-- ----------------------------
-- Table structure for dlink_task_version
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_task_version` (
                                      `id` int NOT NULL AUTO_INCREMENT COMMENT 'ID',
                                      `task_id` int NOT NULL COMMENT 'task ID ',
                                      `tenant_id` int NOT NULL DEFAULT '1' COMMENT 'tenant id',
                                      `version_id` int NOT NULL COMMENT 'version ID ',
                                      `statement` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT 'flink sql statement',
                                      `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'version name',
                                      `alias` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'alisa',
                                      `dialect` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'dialect',
                                      `type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'type',
                                      `task_configure` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'task configuration',
                                      `create_time` datetime DEFAULT NULL COMMENT 'create time',
                                      PRIMARY KEY (`id`) USING BTREE,
                                      UNIQUE KEY `dlink_task_version_un` (`task_id`,`tenant_id`,`version_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='job history version';


-- ----------------------------
-- Table structure for dlink_upload_file_record
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_upload_file_record` (
                                            `id` tinyint NOT NULL AUTO_INCREMENT COMMENT 'id',
                                            `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'upload file name',
                                            `enabled` tinyint(1) DEFAULT NULL COMMENT 'is enable',
                                            `file_type` tinyint DEFAULT '-1' COMMENT 'upload file type ，such as：hadoop-conf(1)、flink-conf(2)、flink-lib(3)、user-jar(4)、dlink-jar(5)，default is -1 ',
                                            `target` tinyint NOT NULL COMMENT 'upload file of target ，such as：local(1)、hdfs(2)',
                                            `file_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'file name',
                                            `file_parent_path` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'file parent path',
                                            `file_absolute_path` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'fila absolute path',
                                            `is_file` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'is file',
                                            `create_time` datetime DEFAULT NULL COMMENT 'create time',
                                            `update_time` datetime DEFAULT NULL COMMENT 'update time',
                                            PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='file upload history';


-- ----------------------------
-- Table structure for dlink_user
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_user` (
                              `id` int NOT NULL AUTO_INCREMENT COMMENT 'ID',
                              `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'username',
                              `password` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'password',
                              `nickname` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'nickname',
                              `worknum` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'worknum',
                              `avatar` blob COMMENT 'avatar',
                              `mobile` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'mobile phone',
                              `enabled` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'is enable',
                              `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'is delete',
                              `create_time` datetime DEFAULT NULL COMMENT 'create time',
                              `update_time` datetime DEFAULT NULL COMMENT 'update time',
                              PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='user';


-- ----------------------------
-- Table structure for dlink_fragment
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_fragment` (
                                  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
                                  `name` varchar(50) NOT NULL COMMENT 'fragment name',
                                  `alias` varchar(50) DEFAULT NULL COMMENT 'alias',
                                  `tenant_id` int(11) NOT NULL DEFAULT '1' COMMENT 'tenant id',
                                  `fragment_value` text NOT NULL COMMENT 'fragment value',
                                  `note` text COMMENT 'note',
                                  `enabled` tinyint(4) DEFAULT '1' COMMENT 'is enable',
                                  `create_time` datetime DEFAULT NULL COMMENT 'create time',
                                  `update_time` datetime DEFAULT NULL COMMENT 'update time',
                                  PRIMARY KEY (`id`) USING BTREE,
                                  UNIQUE KEY `un_idx1` (`name`,`tenant_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='fragment management';


-- ----------------------------------------------------------------------------- Metadata related data table the start -------------------------------------------------------------------------------------------

-- ----------------------------
-- Table structure for metadata_column
-- ----------------------------
CREATE TABLE IF NOT EXISTS `metadata_column` (
                                   `column_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'column name',
                                   `column_type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'column type, such as : Physical , Metadata , Computed , WATERMARK',
                                   `data_type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'data type',
                                   `expr` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'expression',
                                   `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'column description',
                                   `table_id` int NOT NULL COMMENT 'table id',
                                   `primary` bit(1) DEFAULT NULL COMMENT 'table primary key',
                                   `update_time` datetime DEFAULT NULL COMMENT 'update time',
                                   `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'create time',
                                   PRIMARY KEY (`table_id`,`column_name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='column informations';


-- ----------------------------
-- Table structure for metadata_database
-- ----------------------------
CREATE TABLE IF NOT EXISTS `metadata_database` (
                                     `id` int NOT NULL AUTO_INCREMENT COMMENT 'id',
                                     `database_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'database name',
                                     `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'database description',
                                     `update_time` datetime DEFAULT NULL COMMENT 'update time',
                                     `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT 'create time',
                                     PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='metadata of database information';


-- ----------------------------
-- Table structure for metadata_database_property
-- ----------------------------
CREATE TABLE IF NOT EXISTS `metadata_database_property` (
                                              `key` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'key',
                                              `value` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'value',
                                              `database_id` int NOT NULL COMMENT 'database id',
                                              `update_time` datetime DEFAULT NULL COMMENT 'update time',
                                              `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'create time',
                                              PRIMARY KEY (`key`,`database_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='metadata of database configurations';


-- ----------------------------
-- Table structure for metadata_function
-- ----------------------------
CREATE TABLE IF NOT EXISTS `metadata_function` (
                                     `id` int NOT NULL AUTO_INCREMENT COMMENT '主键',
                                     `function_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'function name',
                                     `class_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'class name',
                                     `database_id` int NOT NULL COMMENT 'database id',
                                     `function_language` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'function language',
                                     `update_time` datetime DEFAULT NULL COMMENT 'update time',
                                     `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT 'create time',
                                     PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='UDF informations';


-- ----------------------------
-- Table structure for metadata_table
-- ----------------------------
CREATE TABLE IF NOT EXISTS `metadata_table` (
                                  `id` int NOT NULL AUTO_INCREMENT COMMENT '主键',
                                  `table_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'table name',
                                  `table_type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'type，such as：database,table,view',
                                  `database_id` int NOT NULL COMMENT 'database id',
                                  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'table description',
                                  `update_time` datetime DEFAULT NULL COMMENT 'update time',
                                  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT 'create time',
                                  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='metadata of table information';


-- ----------------------------
-- Table structure for metadata_table_property
-- ----------------------------
CREATE TABLE IF NOT EXISTS `metadata_table_property` (
                                           `key` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'key',
                                           `value` MEDIUMTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'value',
                                           `table_id` int NOT NULL COMMENT 'table id',
                                           `update_time` datetime DEFAULT NULL COMMENT 'update time',
                                           `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'create tiime',
                                           PRIMARY KEY (`key`,`table_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='metadata of table configurations';


-- ----------------------------
-- Table structure for dlink_tenant
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_tenant` (
                                `id` int NOT NULL AUTO_INCREMENT COMMENT 'ID',
                                `tenant_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'tenant code',
                                `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'is delete',
                                `note` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'note',
                                `create_time` datetime DEFAULT NULL COMMENT 'create time',
                                `update_time` datetime DEFAULT NULL COMMENT 'update time',
                                PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='tenant';


-- ----------------------------
-- Table structure for dlink_namespace
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_namespace` (
                                   `id` int NOT NULL AUTO_INCREMENT COMMENT 'ID',
                                   `tenant_id` int NOT NULL COMMENT 'tenant id',
                                   `namespace_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'namespace code',
                                   `enabled` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'is enable',
                                   `note` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'note',
                                   `create_time` datetime DEFAULT NULL COMMENT 'create time',
                                   `update_time` datetime DEFAULT NULL COMMENT 'update time',
                                   PRIMARY KEY (`id`) USING BTREE,
                                   UNIQUE KEY `dlink_namespace_un` (`namespace_code`,`tenant_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='namespace';


-- ----------------------------
-- Table structure for dlink_role
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_role` (
                              `id` int NOT NULL AUTO_INCREMENT COMMENT 'ID',
                              `tenant_id` int NOT NULL COMMENT 'tenant id',
                              `role_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'role code',
                              `role_name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'role name',
                              `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'is delete',
                              `note` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'note',
                              `create_time` datetime DEFAULT NULL COMMENT 'create time',
                              `update_time` datetime DEFAULT NULL COMMENT 'update time',
                              PRIMARY KEY (`id`) USING BTREE,
                              UNIQUE KEY `dlink_role_un` (`role_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='role';


-- ----------------------------
-- Table structure for dlink_role_namespace
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_role_namespace` (
                                        `id` int NOT NULL AUTO_INCREMENT COMMENT 'ID',
                                        `role_id` int NOT NULL COMMENT 'user id',
                                        `namespace_id` int NOT NULL COMMENT 'namespace id',
                                        `create_time` datetime DEFAULT NULL COMMENT 'create time',
                                        `update_time` datetime DEFAULT NULL COMMENT 'update time',
                                        PRIMARY KEY (`id`) USING BTREE,
                                        UNIQUE KEY `dlink_role_namespace_un` (`role_id`,`namespace_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='Role and namespace relationship';


-- ----------------------------
-- Table structure for dlink_user_role
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_user_role` (
                                   `id` int NOT NULL AUTO_INCREMENT COMMENT 'ID',
                                   `user_id` int NOT NULL COMMENT 'user id',
                                   `role_id` int NOT NULL COMMENT 'role id',
                                   `create_time` datetime DEFAULT NULL COMMENT 'create time',
                                   `update_time` datetime DEFAULT NULL COMMENT 'update time',
                                   PRIMARY KEY (`id`) USING BTREE,
                                   UNIQUE KEY `dlink_user_role_un` (`user_id`,`role_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='Relationship between users and roles';


-- ----------------------------
-- Table structure for dlink_user_tenant
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_user_tenant` (
                                     `id` int NOT NULL AUTO_INCREMENT COMMENT 'ID',
                                     `user_id` int NOT NULL COMMENT 'user id',
                                     `tenant_id` int NOT NULL COMMENT 'tenant id',
                                     `create_time` datetime DEFAULT NULL COMMENT 'create time',
                                     `update_time` datetime DEFAULT NULL COMMENT 'update time',
                                     PRIMARY KEY (`id`) USING BTREE,
                                     UNIQUE KEY `dlink_user_role_un` (`user_id`,`tenant_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='Relationship between users and tenants';


-- ----------------------------
-- Table structure for dlink_udf
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_udf` (
                             `id` int NOT NULL AUTO_INCREMENT,
                             `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'udf name',
                             `class_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'Complete class name',
                             `source_code` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT 'source code',
                             `compiler_code` binary(255) DEFAULT NULL COMMENT 'compiler product',
                             `version_id` int DEFAULT NULL COMMENT 'version',
                             `version_description` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'version description',
                             `is_default` tinyint(1) DEFAULT NULL COMMENT 'Is it default',
                             `document_id` int DEFAULT NULL COMMENT 'corresponding to the document id',
                             `from_version_id` int DEFAULT NULL COMMENT 'Based on udf version id',
                             `code_md5` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'source code of md5',
                             `dialect` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'dialect',
                             `type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'type',
                             `step` int DEFAULT NULL COMMENT 'job lifecycle step',
                             `enable` tinyint(1) DEFAULT NULL COMMENT 'is enable',
                             `create_time` datetime DEFAULT NULL COMMENT 'create time',
                             `update_time` datetime DEFAULT NULL COMMENT 'update time',
                             PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='udf';


-- ----------------------------
-- Table structure for dlink_udf_template
-- ----------------------------
CREATE TABLE IF NOT EXISTS `dlink_udf_template` (
                                      `id` int NOT NULL AUTO_INCREMENT,
                                      `name` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '模板名称',
                                      `code_type` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '代码类型',
                                      `function_type` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '函数类型',
                                      `template_code` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '模板代码',
                                      `enabled` tinyint(1) DEFAULT NULL COMMENT 'is enable',
                                      `create_time` datetime DEFAULT NULL COMMENT 'create time',
                                      `update_time` datetime DEFAULT NULL COMMENT 'update time',
                                      PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='udf template';


-- ----------------------------
-- Table structure for dlink_role_select_permissions
-- ----------------------------
CREATE TABLE IF NOT EXISTS dlink_role_select_permissions
(
    id           int auto_increment comment 'ID'
        primary key,
    role_id      int      not null comment '角色ID',
    table_name varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL  comment '表名',
    expression varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL  comment '表达式',
    create_time  datetime null comment '创建时间',
    update_time  datetime null comment '更新时间'
)
    COMMENT '角色数据查询权限' COLLATE = utf8mb4_general_ci;
