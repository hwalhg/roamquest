-- Add user_id to checklists table for data isolation
ALTER TABLE checklists ADD COLUMN IF NOT EXISTS user_id TEXT;

-- Add index for user_id queries
CREATE INDEX IF NOT EXISTS idx_checklists_user_id ON checklists(user_id);

-- Update existing records (optional - for existing data)
-- UPDATE checklists SET user_id = 'unknown' WHERE user_id IS NULL;

-- Add user_id to checkins table for data isolation
ALTER TABLE checkins ADD COLUMN IF NOT EXISTS user_id TEXT;

-- Add index for user_id queries
CREATE INDEX IF NOT EXISTS idx_checkins_user_id ON checkins(user_id);

-- Update existing records (optional - for existing data)
-- UPDATE checkins SET user_id = 'unknown' WHERE user_id IS NULL;

-- Verify the columns were added
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name IN ('checklists', 'checkins') AND column_name = 'user_id';
