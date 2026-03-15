-- Update cities table for city moderation workflow
-- 使用 is_active 单一字段：false 表示未审核，true 表示审核通过

-- Update existing cities to be approved (already in database means they were pre-approved)
UPDATE cities
SET is_active = true
WHERE is_active IS NULL;

-- Update RLS policy to only show approved cities
DROP POLICY IF EXISTS "Anyone can view cities" ON cities;
CREATE POLICY "Anyone can view cities"
ON cities FOR SELECT
USING (is_active = true);

-- Update index for better query performance
DROP INDEX IF EXISTS idx_cities_active_sorted;
CREATE INDEX idx_cities_active_sorted
ON cities(is_active, sort_order);
