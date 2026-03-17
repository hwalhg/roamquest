-- ========================================
-- 修复 profiles 表 RLS 策略
-- 问题：INSERT 策略使用 WITH CHECK，但用户刚注册时 auth.uid() 可能还未设置
-- 解决：允许认证用户插入自己的 profile
-- ========================================

-- 删除旧的 INSERT 策略
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

-- 重新创建 INSERT 策略：允许认证用户插入自己的 profile
CREATE POLICY "Users can insert own profile" ON profiles
FOR INSERT
WITH CHECK (
  auth.uid() IS NOT NULL OR auth.uid() = user_id
);
