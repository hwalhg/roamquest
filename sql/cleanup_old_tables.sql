-- ============================================
-- 清理单城市购买模式的旧表和字段
-- 执行前请确认：你的项目已改为全局订阅模式
-- ============================================

-- ============================================
-- 1. 删除 user_cities 表（单城市购买模式）
-- ============================================
DROP TABLE IF EXISTS public.user_cities CASCADE;

-- ============================================
-- 2. 删除 cities 表中不需要的字段
-- ============================================

-- 删除 subscription_price 字段（订阅模式不需要单独城市定价）
ALTER TABLE public.cities DROP COLUMN IF EXISTS subscription_price;

-- 删除 is_free 字段（订阅模式下所有城市统一解锁）
ALTER TABLE public.cities DROP COLUMN IF EXISTS is_free;

-- ============================================
-- 3. 验证清理结果
-- ============================================

-- 检查 user_cities 表是否已删除
SELECT
    'user_cities' as table_name,
    CASE
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_cities')
        THEN 'NOT DELETED'
        ELSE 'DELETED'
    END as status;

-- 检查 cities 表的字段
SELECT
    column_name,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_name = 'cities' AND column_name = column_name
        )
        THEN 'EXISTS'
        ELSE 'REMOVED'
    END as status
FROM (VALUES ('subscription_price'), ('is_free')) AS old_columns(column_name);

-- ============================================
-- 4. 显示当前所有表
-- ============================================
SELECT
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = 'public' AND table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
    AND table_name IN ('cities', 'checklists', 'checkins', 'checklist_templates', 'subscriptions', 'user_cities')
ORDER BY table_name;

-- ============================================
-- 完成！
-- ============================================
-- 说明：
-- 1. user_cities 表已删除（单城市购买模式不需要）
-- 2. cities.subscription_price 已删除（订阅模式不需要）
-- 3. cities.is_free 已删除（订阅模式不需要）
--
-- 现在项目使用全局订阅模式：
-- - 一个订阅 = 解锁所有城市
-- - 用户状态存储在 subscriptions 表
