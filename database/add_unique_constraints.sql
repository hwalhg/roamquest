-- ========================================
-- 添加唯一索引防止重复数据
-- ========================================

-- 1. checklists 表：用户 + 城市 唯一约束
-- 确保同一用户不会创建多个同一城市的 checklist

-- 删除可能存在的旧索引（如果存在）
DROP INDEX IF EXISTS idx_checklists_user_city_unique;

-- 创建唯一索引
CREATE UNIQUE INDEX idx_checklists_user_city_unique
ON checklists (user_id, city_id);

-- ========================================
-- 2. checklist_items 表：用户 + 城市 + 景点 唯一约束
-- 确保同一用户在同一城市的同一景点只有一条记录

-- 删除可能存在的旧索引（如果存在）
DROP INDEX IF EXISTS idx_checklist_items_user_city_attr_unique;

-- 创建唯一索引
-- 使用 user_id, checklist_id, title 组合确保唯一性
-- 注意：checklist_id 已经包含了 user_id 和 city_id 的关系
-- 所以只需要 checklist_id + title 就可以保证用户+城市+景点的唯一性
CREATE UNIQUE INDEX idx_checklist_items_user_city_attr_unique
ON checklist_items (checklist_id, title);

-- ========================================
-- 说明
-- ========================================
-- checklists 表的唯一约束：
--   - 一个用户对一个城市只能有一个 checklist
--   - 组合键：(user_id, city_id)
--
-- checklist_items 表的唯一约束：
--   - 一个用户在一个城市的一个景点只能有一条记录
--   - 组合键：(checklist_id, title)
--   - 由于 checklist_id 已经关联到 user_id 和 city_id
--   - 所以 (checklist_id, title) 保证了用户+城市+景点的唯一性
--
-- 这些约束防止：
--   1. 应用层的并发问题导致重复插入
--   2. 直接操作数据库插入重复数据
--   3. 数据不一致问题
