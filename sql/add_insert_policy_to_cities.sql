-- Add INSERT policy for cities table
-- 允许认证用户创建新城市（默认 is_active=false，需要审核）

-- 允许认证用户插入新城市
CREATE POLICY "Allow authenticated users to insert cities"
ON cities FOR INSERT
TO authenticated
WITH CHECK (true);

-- 允许认证用户更新城市（管理员可以审核）
CREATE POLICY "Allow authenticated users to update cities"
ON cities FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- 读取策略保持不变：只显示已审核的城市（is_active = true）
DROP POLICY IF EXISTS "Allow public read access to cities" ON cities;
CREATE POLICY "Allow public read access to cities"
ON cities FOR SELECT
USING (is_active = true);

-- 更新索引以支持更快的查询
DROP INDEX IF EXISTS idx_cities_active_sorted;
CREATE INDEX idx_cities_active_sorted ON cities(is_active, sort_order);
CREATE INDEX idx_cities_name_country ON cities(name, country);
