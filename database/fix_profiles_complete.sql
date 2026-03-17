-- ========================================
-- 完整修复 profiles 表问题
-- 问题：
-- 1. Supabase Auth 在注册时自动创建 profile，但 user_id 为 null
-- 2. 用户注册后 profile 不存在，导致更新失败
-- 3. RLS 策略 `user_id = user_id` 不够安全
--
-- 解决方案：
-- 1. 修正 RLS 策略，使用 auth.uid() = user_id
-- 2. 添加触发器，在 auth.users 插入时自动创建 profile
-- ========================================

-- 1. 删除旧的 RLS 策略
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Users can manage own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON profiles;

-- 2. 重新创建正确的 RLS 策略
-- SELECT: 用户只能查看自己的 profile
CREATE POLICY "Users can select own profile" ON profiles
FOR SELECT
USING (auth.uid() = user_id);

-- INSERT: 用户可以创建自己的 profile（通过 auth.uid() = user_id 验证）
CREATE POLICY "Users can insert own profile" ON profiles
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- UPDATE: 用户可以更新自己的 profile
CREATE POLICY "Users can update own profile" ON profiles
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- DELETE: 用户可以删除自己的 profile
CREATE POLICY "Users can delete own profile" ON profiles
FOR DELETE
USING (auth.uid() = user_id);

-- 3. 创建触发器函数：在 auth.users 插入时自动创建 profile
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, user_id, full_name, username)
  VALUES (
    NEW.id,
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'username', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. 删除旧的触发器（如果存在）
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 5. 创建触发器：当在 auth.users 中插入新用户时
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 6. 为现有用户创建 profile（如果还没有）
INSERT INTO public.profiles (id, user_id, full_name, username)
SELECT
  au.id,
  au.id,
  COALESCE(au.raw_user_meta_data->>'full_name', ''),
  COALESCE(au.raw_user_meta_data->>'username', '')
FROM auth.users au
WHERE NOT EXISTS (
  SELECT 1 FROM public.profiles p WHERE p.id = au.id
);
