CREATE DATABASE test;
CREATE TABLE IF NOT EXISTS test.user
(
    `user_id` LARGEINT NOT NULL COMMENT "用户 id",
    `username` VARCHAR(50) NOT NULL COMMENT "用户昵称",
    `city` VARCHAR(20) COMMENT "用户所在城市",
    `age` SMALLINT COMMENT "用户年龄",
    `sex` TINYINT COMMENT "用户性别",
    `phone` LARGEINT COMMENT "用户电话",
    `address` VARCHAR(500) COMMENT "用户地址",
    `register_time` DATETIME COMMENT "用户注册时间"
    )
    UNIQUE KEY(`user_id`, `username`)
    DISTRIBUTED BY HASH(`user_id`) BUCKETS 10
    PROPERTIES
(
    "replication_num" = "1"
);

INSERT INTO test.user VALUES (10000,'wuyanzu',' 北京',18,0,12345678910,' 北京朝阳区 ','2017-10-01 07:00:00');
INSERT INTO test.user VALUES (10000,'wuyanzu',' 北京',19,0,12345678910,' 北京朝阳区 ','2017-10-01 07:00:00');
INSERT INTO test.user VALUES (10000,'zhangsan','北京',20,0,12345678910,'北京海淀区','2017-11-15 06:10:20');

SELECT * FROM test.user;