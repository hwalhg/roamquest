-- RoamQuest Supabase 数据库设置脚本
-- 在 Supabase SQL Editor 中运行此脚本

-- ============================================
-- 1. 创建 checklists 表（用户清单）
-- ============================================
CREATE TABLE IF NOT EXISTS public.checklists (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    city_name TEXT NOT NULL,
    country TEXT NOT NULL,
    country_code TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    language TEXT NOT NULL DEFAULT 'en',
    items JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- 用户关联（如果需要登录功能）
    user_id UUID DEFAULT auth.uid(),

    -- 索引优化
    CONSTRAINT checklists_city_name_check CHECK (char_length(city_name) > 0)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_checklists_user_id ON public.checklists(user_id);
CREATE INDEX IF NOT EXISTS idx_checklists_created_at ON public.checklists(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_checklists_city_country ON public.checklists(city_name, country);

-- ============================================
-- 2. 创建 checkins 表（打卡记录）
-- ============================================
CREATE TABLE IF NOT EXISTS public.checkins (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    checklist_id UUID NOT NULL REFERENCES public.checklists(id) ON DELETE CASCADE,
    item_id TEXT NOT NULL,
    photo_url TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- 用户关联
    user_id UUID DEFAULT auth.uid(),

    -- 约束
    CONSTRAINT checkins_checklist_item_unique UNIQUE (checklist_id, item_id)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_checkins_checklist_id ON public.checkins(checklist_id);
CREATE INDEX IF NOT EXISTS idx_checkins_user_id ON public.checkins(user_id);
CREATE INDEX IF NOT EXISTS idx_checkins_created_at ON public.checkins(created_at DESC);

-- ============================================
-- 3. 创建 subscriptions 表（订阅记录）
-- ============================================
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active', -- active, cancelled, expired
    transaction_id TEXT,
    purchase_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expiry_date TIMESTAMP WITH TIME ZONE,

    -- 约束
    CONSTRAINT subscriptions_status_check CHECK (status IN ('active', 'cancelled', 'expired'))
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON public.subscriptions(status);

-- ============================================
-- 4. 启用行级安全策略 (RLS)
-- ============================================

-- 对 checklists 表启用 RLS
ALTER TABLE public.checklists ENABLE ROW LEVEL SECURITY;

-- 用户只能查看自己的清单
CREATE POLICY "Users can view own checklists"
ON public.checklists FOR SELECT
USING (auth.uid() IS NULL OR user_id = auth.uid());

-- 用户可以创建清单
CREATE POLICY "Users can create checklists"
ON public.checklists FOR INSERT
WITH CHECK (auth.uid() IS NULL OR user_id = auth.uid());

-- 用户可以更新自己的清单
CREATE POLICY "Users can update own checklists"
ON public.checklists FOR UPDATE
USING (auth.uid() IS NULL OR user_id = auth.uid());

-- 用户可以删除自己的清单
CREATE POLICY "Users can delete own checklists"
ON public.checklists FOR DELETE
USING (auth.uid() IS NULL OR user_id = auth.uid());

-- 对 checkins 表启用 RLS
ALTER TABLE public.checkins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own checkins"
ON public.checkins FOR SELECT
USING (auth.uid() IS NULL OR user_id = auth.uid());

CREATE POLICY "Users can create checkins"
ON public.checkins FOR INSERT
WITH CHECK (auth.uid() IS NULL OR user_id = auth.uid());

-- 对 subscriptions 表启用 RLS
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own subscriptions"
ON public.subscriptions FOR SELECT
USING (auth.uid() = user_id);

-- ============================================
-- 5. 创建存储桶 (用于照片存储)
-- ============================================
-- 在 Supabase Dashboard → Storage 中创建名为 'photos' 的存储桶
-- 设置为公开访问 (Public bucket)

-- 照片存储策略
CREATE POLICY "Anyone can view photos"
ON storage.objects FOR SELECT
USING (bucket_id = 'photos');

CREATE POLICY "Authenticated users can upload photos"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'photos' AND
    auth.role() = 'authenticated'
);

CREATE POLICY "Users can delete own photos"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- ============================================
-- 6. 创建实用函数
-- ============================================

-- 更新 updated_at 字段的触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为 checklists 表添加更新时间触发器
CREATE TRIGGER update_checklists_updated_at
BEFORE UPDATE ON public.checklists
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 7. 插入示例数据（可选）
-- ============================================
-- 取消注释以下代码来插入示例清单

/*
INSERT INTO public.checklists (city_name, country, country_code, latitude, longitude, language, items)
VALUES
(
    '北京',
    '中国',
    'CN',
    39.9042,
    116.4074,
    'zh',
    '[
        {"title": "参观故宫博物院", "location": "故宫博物院", "category": "landmark", "order": 0},
        {"title": "登长城", "location": "八达岭长城", "category": "landmark", "order": 1},
        {"title": "品北京烤鸭", "location": "全聚德烤鸭店", "category": "food", "order": 2},
        {"title": "游颐和园", "location": "颐和园", "category": "landmark", "order": 3},
        {"title": "胡同游", "location": "南锣鼓巷", "category": "experience", "order": 4},
        {"title": "吃炸酱面", "location": "老北京炸酱面", "category": "food", "order": 5},
        {"title": "天坛祈福", "location": "天坛公园", "category": "landmark", "order": 6},
        {"title": "798艺术区", "location": "798艺术区", "category": "hidden", "order": 7},
        {"title": "豆汁体验", "location": "护国寺小吃", "category": "food", "order": 8},
        {"title": "景山观全景", "location": "景山公园", "category": "hidden", "order": 9}
    ]'::jsonb
);
*/

-- ============================================
-- 完成！
-- ============================================
-- 运行完成后，检查表是否创建成功
SELECT
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
    AND table_name IN ('checklists', 'checkins', 'subscriptions')
ORDER BY table_name;
