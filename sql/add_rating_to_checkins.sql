-- Add rating column to checkins table
ALTER TABLE checkins ADD COLUMN IF NOT EXISTS rating INTEGER;

-- Add index for rating queries (optional, for filtering/sorting by rating)
CREATE INDEX IF NOT EXISTS idx_checkins_rating ON checkins(rating);

-- Verify the column was added
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'checkins' AND column_name = 'rating';
