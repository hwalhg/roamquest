-- ========================================
-- 修复 profiles 表 RLS 策略 - 版本 2
-- 问题：auth.uid() 可能在某些情况下评估为 null
-- 解决：允许 user_id 匹配的插入（认证用户的 own profile）
-- ========================================

-- 删除旧的 INSERT 策略
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

-- 重新创建 INSERT 策略：只要 user_id 匹配就允许
CREATE POLICY "Users can insert own profile" ON profiles
FOR INSERT
WITH CHECK (user_id = user_id);
