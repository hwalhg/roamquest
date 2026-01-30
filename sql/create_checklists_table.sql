-- Create checklists table
CREATE TABLE IF NOT EXISTS checklists (
  id TEXT PRIMARY KEY,
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

-- Create index on created_at for sorting
CREATE INDEX IF NOT EXISTS idx_checklists_created_at ON checklists(created_at DESC);

-- Create index on city_name for city lookup
CREATE INDEX IF NOT EXISTS idx_checklists_city_name ON checklists(city_name);

-- Enable Row Level Security
ALTER TABLE checklists ENABLE ROW LEVEL SECURITY;

-- For development/testing with web: Allow public access
-- TODO: Implement proper user authentication and row-level security

CREATE POLICY "Allow public read access" ON checklists FOR SELECT USING (true);
CREATE POLICY "Allow public insert access" ON checklists FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update access" ON checklists FOR UPDATE USING (true);
CREATE POLICY "Allow public delete access" ON checklists FOR DELETE USING (true);

-- For production with proper auth, use these policies instead:
/*
-- Add a user_id column first:
ALTER TABLE checklists ADD COLUMN user_id TEXT REFERENCES auth.users(id);

CREATE POLICY "Users can read own checklists"
ON checklists FOR SELECT
USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own checklists"
ON checklists FOR INSERT
WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own checklists"
ON checklists FOR UPDATE
USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own checklists"
ON checklists FOR DELETE
USING (auth.uid()::text = user_id);
*/

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
CREATE TRIGGER update_checklists_updated_at
BEFORE UPDATE ON checklists
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
