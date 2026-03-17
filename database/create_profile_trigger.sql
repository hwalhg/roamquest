-- ========================================
-- 创建触发器：用户注册时自动创建 profile 记录
-- ========================================

-- 删除旧的触发器（如果存在）
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- 创建函数：处理新用户创建
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, user_id, username, full_name, avatar_url, preferences)
  VALUES (
    gen_random_uuid(),
    NEW.id,
    NULL,
    NULL,
    NULL,
    '{}'::jsonb
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 创建触发器：当新用户在 auth.users 表中创建时，自动在 profiles 表中创建对应记录
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION handle_new_user();
