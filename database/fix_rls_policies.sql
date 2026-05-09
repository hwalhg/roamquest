-- ========================================
-- Harden public catalog table permissions.
-- Cities and attractions are readable public catalog data, but app clients must
-- not be able to modify official catalog records with the anon key.
-- ========================================

-- 删除旧的 public read access 策略
DROP POLICY IF EXISTS "Public read access" ON cities;
DROP POLICY IF EXISTS "Public read access" ON attractions;

-- 允许客户端读取公开目录数据。
ALTER TABLE cities DISABLE ROW LEVEL SECURITY;
ALTER TABLE attractions DISABLE ROW LEVEL SECURITY;

GRANT SELECT ON public.cities TO anon, authenticated;
GRANT SELECT ON public.attractions TO anon, authenticated;

REVOKE INSERT, UPDATE, DELETE ON public.cities FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.attractions FROM anon, authenticated;

-- 验证权限和 RLS 状态。
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE tablename IN ('cities', 'attractions');
