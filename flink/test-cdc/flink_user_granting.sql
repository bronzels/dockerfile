-- pg新建用户
CREATE USER flink WITH PASSWORD 'flinkpw';
-- 给用户复制流权限
ALTER ROLE flink replication;
-- 创建数据库
CREATE DATABASE mydb;
-- 给用户登录数据库权限
GRANT CONNECT ON DATABASE mydb to flink;
-- 把当前库public下所有表查询权限赋给用户
GRANT SELECT ON ALL TABLES IN SCHEMA public TO flink;
