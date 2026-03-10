-- ============================================
-- RoamQuest 完整数据库设置脚本
-- 按月订阅模式（全局订阅解锁所有城市）
-- ============================================

-- ============================================
-- 1. 创建/更新 cities 表（城市列表）
-- ============================================

-- 先删除表再创建（确保结构正确）
DROP TABLE IF EXISTS public.cities CASCADE;

CREATE TABLE public.cities (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    country TEXT NOT NULL,
    country_code TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_cities_country ON public.cities(country);
CREATE INDEX IF NOT EXISTS idx_cities_name ON public.cities(name);
CREATE INDEX IF NOT EXISTS idx_cities_location ON public.cities(latitude, longitude);

-- ============================================
-- 2. 创建/更新 checklists 表（用户清单）
-- ============================================

-- 先删除表再创建（确保结构正确）
DROP TABLE IF EXISTS public.checklists CASCADE;

CREATE TABLE public.checklists (
    id TEXT PRIMARY KEY,
    user_id UUID DEFAULT auth.uid(),
    city_name TEXT NOT NULL,
    country TEXT NOT NULL,
    country_code TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    language TEXT NOT NULL DEFAULT 'en',
    items JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_checklists_user_id ON public.checklists(user_id);
CREATE INDEX IF NOT EXISTS idx_checklists_city_name ON public.checklists(city_name, country);
CREATE INDEX IF NOT EXISTS idx_checklists_created_at ON public.checklists(created_at DESC);

-- ============================================
-- 3. 创建/更新 checkins 表（打卡记录）
-- ============================================

-- 先删除表再创建（确保结构正确）
DROP TABLE IF EXISTS public.checkins CASCADE;

CREATE TABLE public.checkins (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    checklist_id TEXT NOT NULL REFERENCES public.checklists(id) ON DELETE CASCADE,
    item_id TEXT NOT NULL,
    item_index INTEGER NOT NULL,
    photo_url TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    note TEXT,
    rating INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    user_id UUID DEFAULT auth.uid(),

    CONSTRAINT checkins_rating_check CHECK (rating >= 0 AND rating <= 5),
    CONSTRAINT checkins_checklist_item_unique UNIQUE (checklist_id, item_id)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_checkins_checklist_id ON public.checkins(checklist_id);
CREATE INDEX IF NOT EXISTS idx_checkins_user_id ON public.checkins(user_id);
CREATE INDEX IF NOT EXISTS idx_checkins_created_at ON public.checkins(created_at DESC);

-- ============================================
-- 4. 创建/更新 checklist_templates 表（预置清单模板）
-- ============================================

-- 先删除表再创建（确保结构正确）
DROP TABLE IF EXISTS public.checklist_templates CASCADE;

CREATE TABLE public.checklist_templates (
    id TEXT PRIMARY KEY,
    city_id BIGINT REFERENCES public.cities(id) ON DELETE CASCADE,
    city_name TEXT NOT NULL,
    country TEXT NOT NULL,
    country_code TEXT NOT NULL,
    language TEXT NOT NULL DEFAULT 'en',
    items JSONB NOT NULL DEFAULT '[]'::jsonb,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(city_id, language)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_checklist_templates_city ON public.checklist_templates(city_id);
CREATE INDEX IF NOT EXISTS idx_checklist_templates_city_name ON public.checklist_templates(city_name, country);
CREATE INDEX IF NOT EXISTS idx_checklist_templates_active ON public.checklist_templates(is_active);

-- ============================================
-- 5. 创建/更新 subscriptions 表（订阅记录）
-- ============================================

-- 先删除表再创建（确保结构正确）
DROP TABLE IF EXISTS public.subscriptions CASCADE;

CREATE TABLE public.subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id TEXT NOT NULL,  -- com.roamquest.subscription.monthly/quarterly/yearly
    status TEXT NOT NULL DEFAULT 'active',  -- active, cancelled, expired, pending
    original_transaction_id TEXT,  -- Apple 的原始交易 ID
    latest_receipt_data TEXT,  -- Apple receipt 数据
    auto_renew BOOLEAN DEFAULT true,  -- 是否自动续订
    purchase_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expiry_date TIMESTAMP WITH TIME ZONE NOT NULL,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT subscriptions_status_check CHECK (status IN ('active', 'cancelled', 'expired', 'pending'))
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON public.subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_product_id ON public.subscriptions(product_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_subscriptions_user_active ON public.subscriptions(user_id)
    WHERE status = 'active';

-- ============================================
-- 6. 启用行级安全策略 (RLS)
-- ============================================

-- cities 表: 公开读取
ALTER TABLE public.cities ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view cities"
ON public.cities FOR SELECT USING (is_active = true);

-- checklists 表: 用户只能操作自己的清单
ALTER TABLE public.checklists ENABLE ROW LEVEL SECURITY;

-- 未登录用户可以创建临时清单
CREATE POLICY "Guests can create checklists"
ON public.checklists FOR INSERT
WITH CHECK (user_id IS NULL);

-- 已登录用户可以创建自己的清单
CREATE POLICY "Users can create own checklists"
ON public.checklists FOR INSERT
WITH CHECK (user_id = auth.uid());

-- 用户只能查看自己的清单
CREATE POLICY "Users can view own checklists"
ON public.checklists FOR SELECT
USING (auth.uid() IS NULL OR user_id = auth.uid());

-- 用户只能更新自己的清单
CREATE POLICY "Users can update own checklists"
ON public.checklists FOR UPDATE
USING (auth.uid() IS NULL OR user_id = auth.uid());

-- 用户只能删除自己的清单
CREATE POLICY "Users can delete own checklists"
ON public.checklists FOR DELETE
USING (auth.uid() IS NULL OR user_id = auth.uid());

-- checkins 表: 用户只能操作自己的打卡
ALTER TABLE public.checkins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own checkins"
ON public.checkins FOR SELECT
USING (auth.uid() IS NULL OR user_id = auth.uid());

CREATE POLICY "Users can create checkins"
ON public.checkins FOR INSERT
WITH CHECK (auth.uid() IS NULL OR user_id = auth.uid());

CREATE POLICY "Users can update own checkins"
ON public.checkins FOR UPDATE
USING (auth.uid() IS NULL OR user_id = auth.uid());

CREATE POLICY "Users can delete own checkins"
ON public.checkins FOR DELETE
USING (auth.uid() IS NULL OR user_id = auth.uid());

-- checklist_templates 表: 公开读取
ALTER TABLE public.checklist_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view checklist templates"
ON public.checklist_templates FOR SELECT USING (true);

CREATE POLICY "Allow insert access on checklist templates"
ON public.checklist_templates FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow update access on checklist templates"
ON public.checklist_templates FOR UPDATE USING (true);

-- subscriptions 表: 用户只能查看自己的订阅
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own subscriptions"
ON public.subscriptions FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can create own subscriptions"
ON public.subscriptions FOR INSERT
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own subscriptions"
ON public.subscriptions FOR UPDATE
USING (user_id = auth.uid());

-- ============================================
-- 7. 创建实用函数
-- ============================================

-- 更新 updated_at 字段的触发器函数
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为 cities 表添加触发器
DROP TRIGGER IF EXISTS update_cities_updated_at ON public.cities;
CREATE TRIGGER update_cities_updated_at
BEFORE UPDATE ON public.cities
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- 为 checklists 表添加触发器
DROP TRIGGER IF EXISTS update_checklists_updated_at ON public.checklists;
CREATE TRIGGER update_checklists_updated_at
BEFORE UPDATE ON public.checklists
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- 为 checklist_templates 表添加触发器
DROP TRIGGER IF EXISTS update_checklist_templates_updated_at ON public.checklist_templates;
CREATE TRIGGER update_checklist_templates_updated_at
BEFORE UPDATE ON public.checklist_templates
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- 为 subscriptions 表添加触发器
DROP TRIGGER IF EXISTS update_subscriptions_updated_at ON public.subscriptions;
CREATE TRIGGER update_subscriptions_updated_at
BEFORE UPDATE ON public.subscriptions
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- 8. 创建订阅查询函数
-- ============================================

-- 获取用户的当前有效订阅
CREATE OR REPLACE FUNCTION public.get_active_subscription(p_user_id UUID)
RETURNS TABLE (
    id UUID,
    product_id TEXT,
    status TEXT,
    expiry_date TIMESTAMP WITH TIME ZONE,
    days_remaining INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.id,
        s.product_id,
        s.status,
        s.expiry_date,
        EXTRACT(DAY FROM (s.expiry_date - NOW()))::INTEGER as days_remaining
    FROM public.subscriptions s
    WHERE s.user_id = p_user_id
        AND s.status = 'active'
        AND s.expiry_date > NOW()
    ORDER BY s.expiry_date DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 检查用户是否有有效订阅
CREATE OR REPLACE FUNCTION public.has_active_subscription(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM public.subscriptions
        WHERE user_id = p_user_id
            AND status = 'active'
            AND expiry_date > NOW()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 9. 存储桶策略设置 (手动在 Dashboard 创建存储桶)
-- ============================================

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

-- 报告存储策略
CREATE POLICY "Anyone can view reports"
ON storage.objects FOR SELECT
USING (bucket_id = 'reports');

CREATE POLICY "Authenticated users can create reports"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'reports' AND
    auth.role() = 'authenticated'
);

-- ============================================
-- 10. 完成验证
-- ============================================
-- 显示创建的表及其列数
SELECT
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = 'public' AND table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
    AND table_name IN ('cities', 'checklists', 'checkins', 'checklist_templates', 'subscriptions', 'user_cities')
ORDER BY table_name;
