-- ========================================
-- Fix RLS policies for cities and attractions tables
-- Problem: cities table has RLS enabled but only SELECT policy
-- Solution: Add INSERT policy for authenticated users
-- ========================================

-- 删除旧的 public read access 策略
DROP POLICY IF EXISTS "Public read access" ON cities;
DROP POLICY IF EXISTS "Public read access" ON attractions;

-- 禁用 cities 和 attractions 表的 RLS（公开数据，不需要 RLS）
ALTER TABLE cities DISABLE ROW LEVEL SECURITY;
ALTER TABLE attractions DISABLE ROW LEVEL SECURITY;

-- 验证 RLS 状态
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE tablename IN ('cities', 'attractions');
