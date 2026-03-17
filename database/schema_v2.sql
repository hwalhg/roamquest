-- ========================================
-- RoamQuest 数据库 Schema
-- 版本: 2.0
-- 说明:
--   1. 将 items 从 JSON 字段分离为独立的 checklist_items 表
--   2. 添加 profiles 和 subscriptions 表
-- ========================================

-- ========================================
-- 第一步：删除旧表（按依赖顺序）
-- ========================================
DROP TABLE IF EXISTS checklist_items CASCADE;
DROP TABLE IF EXISTS checklists CASCADE;
DROP TABLE IF EXISTS attractions CASCADE;
DROP TABLE IF EXISTS cities CASCADE;
DROP TABLE IF EXISTS subscriptions CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- ========================================
-- 第二步：创建新表
-- ========================================

-- 1. Cities 表（城市数据，公开预置）
CREATE TABLE cities (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  country VARCHAR(255) NOT NULL,
  country_code VARCHAR(10),
  latitude DECIMAL(11, 8),
  longitude DECIMAL(11, 8),
  is_active BOOLEAN DEFAULT false,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Attractions 表（景点模板，公开数据）
CREATE TABLE attractions (
  id SERIAL PRIMARY KEY,
  city_id INTEGER REFERENCES cities(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  location VARCHAR(500) NOT NULL,
  category VARCHAR(50) NOT NULL,
  language VARCHAR(10) NOT NULL,
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Checklists 表（用户清单头部）
CREATE TABLE checklists (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  city_id INTEGER REFERENCES cities(id) ON DELETE CASCADE,
  language VARCHAR(10) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Checklist_items 表（用户清单项目）
CREATE TABLE checklist_items (
  id UUID PRIMARY KEY,
  checklist_id UUID REFERENCES checklists(id) ON DELETE CASCADE,
  attraction_id INTEGER REFERENCES attractions(id) ON DELETE SET NULL,
  title VARCHAR(255) NOT NULL,
  location VARCHAR(500) NOT NULL,
  category VARCHAR(50) NOT NULL,
  sort_order INTEGER DEFAULT 0,
  is_completed BOOLEAN DEFAULT false,
  checkin_photo_url TEXT,
  checked_at TIMESTAMP WITH TIME ZONE,
  latitude DECIMAL(11, 8),
  longitude DECIMAL(11, 8),
  rating INTEGER,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Subscriptions 表（用户订阅记录）
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  product_id VARCHAR(50) NOT NULL,
  start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  end_date TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT true,
  auto_renew BOOLEAN DEFAULT true,
  original_transaction_id VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT fk_subscriptions_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- 6. Profiles 表（用户个人资料）
CREATE TABLE profiles (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  username VARCHAR(100),
  full_name VARCHAR(255),
  avatar_url TEXT,
  preferences JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT fk_profiles_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- ========================================
-- 第三步：配置 RLS（Row Level Security）策略
-- ========================================

-- 注意：cities 和 attractions 是公开数据表，不需要启用 RLS
-- 只有用户数据表需要 RLS 保护

-- 1. 对用户表启用 RLS
ALTER TABLE checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 4. 删除可能存在的旧策略（防止冲突）
DROP POLICY IF EXISTS "Users can read own checklists" ON checklists;
DROP POLICY IF EXISTS "Users can insert own checklists" ON checklists;
DROP POLICY IF EXISTS "Users can update own checklists" ON checklists;
DROP POLICY IF EXISTS "Users can delete own checklists" ON checklists;
DROP POLICY IF EXISTS "Users can read own checklist items" ON checklist_items;
DROP POLICY IF EXISTS "Users can insert own checklist items" ON checklist_items;
DROP POLICY IF EXISTS "Users can update own checklist items" ON checklist_items;
DROP POLICY IF EXISTS "Users can delete own checklist items" ON checklist_items;
DROP POLICY IF EXISTS "Users can manage own subscriptions" ON subscriptions;
DROP POLICY IF EXISTS "Users can read own subscriptions" ON subscriptions;
DROP POLICY IF EXISTS "Users can manage own profile" ON profiles;

-- 5. checklists 表策略：用户只能管理自己的清单
CREATE POLICY "Users can read own checklists" ON checklists
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own checklists" ON checklists
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own checklists" ON checklists
FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own checklists" ON checklists
FOR DELETE
USING (auth.uid() = user_id);

-- 6. checklist_items 表策略：用户只能管理自己清单中的项目
CREATE POLICY "Users can read own checklist items" ON checklist_items
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM checklists
    WHERE id = checklist_items.checklist_id
    AND auth.uid() = user_id
  )
);

CREATE POLICY "Users can insert own checklist items" ON checklist_items
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM checklists
    WHERE id = checklist_items.checklist_id
    AND auth.uid() = user_id
  )
);

CREATE POLICY "Users can update own checklist items" ON checklist_items
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM checklists
    WHERE id = checklist_items.checklist_id
    AND auth.uid() = user_id
  )
);

CREATE POLICY "Users can delete own checklist items" ON checklist_items
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM checklists
    WHERE id = checklist_items.checklist_id
    AND auth.uid() = user_id
  )
);

-- 7. subscriptions 表策略：用户只能管理自己的订阅
CREATE POLICY "Users can read own subscriptions" ON subscriptions
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subscriptions" ON subscriptions
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own subscriptions" ON subscriptions
FOR UPDATE
USING (auth.uid() = user_id);

-- 8. profiles 表策略：用户只能管理自己的资料
CREATE POLICY "Users can manage own profile" ON profiles
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile" ON profiles
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" ON profiles
FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own profile" ON profiles
FOR DELETE
USING (auth.uid() = user_id);

-- ========================================
-- 第四步：创建索引以提高查询性能
-- ========================================

-- cities 表索引
CREATE INDEX IF NOT EXISTS idx_cities_active ON cities(is_active);
CREATE INDEX IF NOT EXISTS idx_cities_country ON cities(country);
CREATE INDEX IF NOT EXISTS idx_cities_name ON cities(name);

-- attractions 表索引
CREATE INDEX IF NOT EXISTS idx_attractions_city_language ON attractions(city_id, language);
CREATE INDEX IF NOT EXISTS idx_attractions_active ON attractions(is_active);
CREATE INDEX IF NOT EXISTS idx_attractions_category ON attractions(category);

-- checklists 表索引
CREATE INDEX IF NOT EXISTS idx_checklists_user_city ON checklists(user_id, city_id);
CREATE INDEX IF NOT EXISTS idx_checklists_created_at ON checklists(created_at DESC);

-- checklist_items 表索引
CREATE INDEX IF NOT EXISTS idx_checklist_items_checklist ON checklist_items(checklist_id);
CREATE INDEX IF NOT EXISTS idx_checklist_items_attraction ON checklist_items(attraction_id);
CREATE INDEX IF NOT EXISTS idx_checklist_items_completed ON checklist_items(is_completed);
CREATE INDEX IF NOT EXISTS idx_checklist_items_checked_at ON checklist_items(checked_at DESC);

-- subscriptions 表索引
CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_active ON subscriptions(is_active);
CREATE INDEX IF NOT EXISTS idx_subscriptions_product ON subscriptions(product_id);

-- profiles 表索引
CREATE INDEX IF NOT EXISTS idx_profiles_user ON profiles(user_id);

-- ========================================
-- 表结构说明
-- ========================================

-- cities 表：存储城市信息，公开预置数据
--   - id: SERIAL 自增整数主键
--   - is_active: 标记城市是否对用户可见

-- attractions 表：存储景点模板，由 AI 生成后保存
--   - 通过 city_id 外键关联到 cities 表
--   - is_active: 标记模板是否启用

-- checklists 表：存储用户的清单头部信息
--   - id: UUID 主键，与 auth.uid() 类型匹配
--   - user_id: 关联到 Supabase Auth 用户
--   - city_id: 外键关联到城市

-- checklist_items 表：存储用户清单的具体项目
--   - id: UUID 主键
--   - checklist_id: 外键关联到 checklists 表
--   - attraction_id: 可选外键，关联到 attractions 模板
--   - is_completed: 标记项目是否已完成
--   - checkin_photo_url: 打卡照片
--   - checked_at: 打卡时间
--   - rating: 用户评分 (1-20，显示时除以2得到0.5-10)
--   - notes: 用户备注

-- subscriptions 表：存储用户订阅记录
--   - id: UUID 主键
--   - user_id: 关联到 auth.users 表
--   - product_id: 订阅产品 ID (如 'com.roamquest.premium.monthly')
--   - start_date: 订阅开始时间
--   - end_date: 订阅结束时间（NULL 表示持续订阅）
--   - is_active: 订阅是否激活
--   - auto_renew: 是否自动续订
--   - original_transaction_id: 原始交易 ID（用于 App Store/Play Store 回调）

-- profiles 表：存储用户个人资料
--   - id: UUID 主键
--   - user_id: 关联到 auth.users 表（一对一关系）
--   - username: 用户名
--   - full_name: 用户全名
--   - avatar_url: 头像 URL
--   - preferences: JSON 格式的用户偏好设置
--   - created_at/updated_at: 创建和更新时间

-- RLS 策略说明：
--   - cities 和 attractions 表：禁用 RLS，允许所有用户读取
--   - checklists, checklist_items, subscriptions, profiles 表：启用 RLS
--   - auth.uid() 是 Supabase 内置函数，返回当前登录用户的 UUID
--   - 所有用户数据表都只允许用户访问自己的数据（通过 auth.uid() = user_id 检查）
