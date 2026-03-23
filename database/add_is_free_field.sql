-- ========================================
-- 添加 is_free 字段实现免费景点功能
-- ========================================

-- 1. 为 attractions 表添加 is_free 字段
ALTER TABLE attractions ADD COLUMN IF NOT EXISTS is_free BOOLEAN DEFAULT false;

-- 2. 为 checklist_items 表添加 is_free 字段（继承自 attractions）
ALTER TABLE checklist_items ADD COLUMN IF NOT EXISTS is_free BOOLEAN DEFAULT false;

-- 3. 为 attractions 表创建索引以优化查询
CREATE INDEX IF NOT EXISTS idx_attractions_free ON attractions(city_id, language, is_free);

-- 4. 为 checklist_items 表创建索引
CREATE INDEX IF NOT EXISTS idx_checklist_items_free ON checklist_items(checklist_id, is_free);

-- 5. 更新现有数据：每个城市每分类前 2 个标记为免费
-- 注意：这只是示例，实际免费数量可以根据业务需求调整
UPDATE attractions SET is_free = true
WHERE id IN (
  SELECT id FROM (
    SELECT id, ROW_NUMBER() OVER (
      PARTITION BY city_id, category, language
      ORDER BY sort_order, id
    ) as rn
    FROM attractions
    WHERE is_active = true
  ) t
  WHERE rn <= 2
);

-- 6. 同步 checklist_items 表的 is_free 字段（从 attractions 继承）
-- 对于有关联 attraction_id 的项目，继承其 is_free 状态
UPDATE checklist_items ci
SET is_free = COALESCE((
  SELECT is_free FROM attractions a
  WHERE a.id = ci.attraction_id
), false)
WHERE ci.attraction_id IS NOT NULL;

-- ========================================
-- 说明
-- ========================================
-- is_free 字段：
--   - true: 该景点为免费景点，所有用户都可以打卡
--   - false: 该景点需要订阅才能打卡（或使用免费额度）
--
-- attraction_id 字段：
--   - 可以为 null：用户自定义添加的项目
--   - 不为 null：从 attractions 模板创建的项目
--
-- 免费景点选择逻辑：
--   - 每个城市 (city_id)
--   - 每个分类 (category: landmark, food, experience, hidden)
--   - 每种语言 (language)
--   - 前 2 个景点标记为免费 (rn <= 2)
--
-- 业务逻辑：
--   1. 免费景点 (is_free = true)：所有用户都可以打卡
--   2. 付费景点 (is_free = false)：
--      - Premium 用户：可以打卡
--      - 免费用户：每分类 1 次免费打卡额度
