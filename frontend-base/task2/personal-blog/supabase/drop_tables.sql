-- 删除现有表的 SQL 脚本
-- 注意：按照依赖关系的逆序删除

-- 删除视图
DROP VIEW IF EXISTS article_stats CASCADE;
DROP VIEW IF EXISTS tag_stats CASCADE;

-- 删除触发器
DROP TRIGGER IF EXISTS update_articles_updated_at ON articles;
DROP TRIGGER IF EXISTS update_authors_updated_at ON authors;

-- 删除函数
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- 删除表（按照外键依赖的逆序）
DROP TABLE IF EXISTS contact_messages CASCADE;
DROP TABLE IF EXISTS subscribers CASCADE;
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS article_tags CASCADE;
DROP TABLE IF EXISTS articles CASCADE;
DROP TABLE IF EXISTS tags CASCADE;
DROP TABLE IF EXISTS authors CASCADE;

-- 删除扩展（可选，如果不需要保留）
-- DROP EXTENSION IF EXISTS "uuid-ossp";

-- 清理完成提示
SELECT 'All tables, views, triggers, and functions have been dropped successfully.' as status;