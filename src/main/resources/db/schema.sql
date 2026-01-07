-- 个人记账系统数据库初始化脚本 (微服务架构版本)
-- Database per Service: 每个服务独立数据库
-- Soft Delete: 所有表支持软删除
-- Pre-computation: 统计数据预计算

-- 授权: 确保业务账号对所有服务库有权限
CREATE USER IF NOT EXISTS 'accont'@'%' IDENTIFIED BY 'accont123';
GRANT ALL PRIVILEGES ON accont_user.* TO 'accont'@'%';
GRANT ALL PRIVILEGES ON accont_asset.* TO 'accont'@'%';
GRANT ALL PRIVILEGES ON accont_transaction.* TO 'accont'@'%';
GRANT ALL PRIVILEGES ON accont_statistics.* TO 'accont'@'%';
FLUSH PRIVILEGES;

-- ================================
-- 1. 用户服务数据库 (User Service)
-- ================================
CREATE DATABASE IF NOT EXISTS accont_user DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE accont_user;

-- 用户表
DROP TABLE IF EXISTS sys_user;
CREATE TABLE sys_user (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    username VARCHAR(50) NOT NULL UNIQUE COMMENT '用户名',
    password VARCHAR(100) NOT NULL COMMENT '密码',
    is_deleted TINYINT(1) DEFAULT 0 COMMENT '软删除标记: 0-正常, 1-已删除',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX idx_username (username),
    INDEX idx_deleted (is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 测试数据
INSERT INTO sys_user (username, password, is_deleted) VALUES ('admin', '123456', 0);

-- ================================
-- 2. 资产服务数据库 (Asset Service)
-- ================================
CREATE DATABASE IF NOT EXISTS accont_asset DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE accont_asset;

-- 资产表
DROP TABLE IF EXISTS tb_asset;
CREATE TABLE tb_asset (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    name VARCHAR(50) NOT NULL COMMENT '账户名称',
    balance DECIMAL(15, 2) DEFAULT 0.00 COMMENT '余额',
    version INT DEFAULT 1 COMMENT '版本号(乐观锁)',
    is_deleted TINYINT(1) DEFAULT 0 COMMENT '软删除标记: 0-正常, 1-已删除',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX idx_user_id (user_id),
    INDEX idx_deleted (is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='资产表';

-- 测试数据
INSERT INTO tb_asset (user_id, name, balance, version, is_deleted) VALUES 
(1, '现金钱包', 10000.00, 1, 0),
(1, '银行卡', 50000.00, 1, 0),
(1, '支付宝', 2000.00, 1, 0);

-- ================================
-- 3. 交易服务数据库 (Transaction Service)
-- ================================
CREATE DATABASE IF NOT EXISTS accont_transaction DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE accont_transaction;

-- 流水表
DROP TABLE IF EXISTS tb_transaction;
CREATE TABLE tb_transaction (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    asset_id BIGINT NOT NULL COMMENT '资产ID',
    amount DECIMAL(15, 2) NOT NULL COMMENT '金额',
    type TINYINT NOT NULL COMMENT '类型: 1-支出, 2-收入',
    category VARCHAR(50) NOT NULL COMMENT '分类',
    trans_time DATETIME NOT NULL COMMENT '交易时间',
    is_deleted TINYINT(1) DEFAULT 0 COMMENT '软删除标记: 0-正常, 1-已删除',
    INDEX idx_user_id (user_id),
    INDEX idx_asset_id (asset_id),
    INDEX idx_trans_time (trans_time),
    INDEX idx_deleted (is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='流水表';

-- 测试数据
INSERT INTO tb_transaction (user_id, asset_id, amount, type, category, trans_time, is_deleted) VALUES
(1, 1, 100.00, 1, '餐饮', NOW(), 0),
(1, 2, 5000.00, 2, '工资', NOW(), 0);

-- ================================
-- 4. 统计服务数据库 (Statistics Service)
-- ================================
CREATE DATABASE IF NOT EXISTS accont_statistics DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE accont_statistics;

-- 日统计预计算表
DROP TABLE IF EXISTS tb_daily_statistics;
CREATE TABLE tb_daily_statistics (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    stat_date DATE NOT NULL COMMENT '统计日期',
    total_income DECIMAL(15, 2) DEFAULT 0.00 COMMENT '当日收入总额',
    total_expense DECIMAL(15, 2) DEFAULT 0.00 COMMENT '当日支出总额',
    trans_count INT DEFAULT 0 COMMENT '交易笔数',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    UNIQUE KEY uk_user_date (user_id, stat_date),
    INDEX idx_stat_date (stat_date),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='日统计预计算表';

-- 分类统计预计算表
DROP TABLE IF EXISTS tb_category_statistics;
CREATE TABLE tb_category_statistics (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    stat_month VARCHAR(7) NOT NULL COMMENT '统计月份，如 2025-12',
    category_name VARCHAR(50) NOT NULL COMMENT '分类名称',
    type TINYINT NOT NULL COMMENT '类型: 1-支出, 2-收入',
    total_amount DECIMAL(15, 2) DEFAULT 0.00 COMMENT '总金额',
    trans_count INT DEFAULT 0 COMMENT '交易笔数',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    UNIQUE KEY uk_user_month_cat (user_id, stat_month, category_name, type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='分类统计预计算表';
