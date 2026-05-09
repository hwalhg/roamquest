-- ========================================
-- 修复 profiles 表 RLS 策略 - 版本 2
-- 旧版本曾使用 `user_id = user_id`，该条件恒为 true，不安全。
-- 请优先使用 database/migrations/20260509_harden_profiles_rls.sql。
-- ========================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 删除旧的 INSERT 策略
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

-- 重新创建 INSERT 策略：只能创建自己的 profile
CREATE POLICY "Users can insert own profile" ON profiles
FOR INSERT
WITH CHECK (auth.uid() = user_id);
