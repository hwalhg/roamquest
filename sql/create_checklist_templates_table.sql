-- Create checklist_templates table for pre-maintained city checklists
CREATE TABLE IF NOT EXISTS checklist_templates (
  id TEXT PRIMARY KEY,
  city_name TEXT NOT NULL,
  country TEXT NOT NULL,
  country_code TEXT NOT NULL,
  language TEXT NOT NULL DEFAULT 'en',
  items JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(city_name, country, language)
);

-- Create index on city_name for quick lookup
CREATE INDEX IF NOT EXISTS idx_checklist_templates_city ON checklist_templates(city_name, country);

-- Create index on is_active
CREATE INDEX IF NOT EXISTS idx_checklist_templates_active ON checklist_templates(is_active);

-- Enable Row Level Security
ALTER TABLE checklist_templates ENABLE ROW LEVEL SECURITY;

-- For development/testing with web: Allow public read access
CREATE POLICY "Allow public read access on checklist_templates"
ON checklist_templates FOR SELECT USING (true);

-- Allow insert (for AI generation)
CREATE POLICY "Allow public insert access on checklist_templates"
ON checklist_templates FOR INSERT WITH CHECK (true);

-- Allow update (for AI regeneration)
CREATE POLICY "Allow public update access on checklist_templates"
ON checklist_templates FOR UPDATE USING (true);

-- Function to update updated_at timestamp
CREATE TRIGGER update_checklist_templates_updated_at
BEFORE UPDATE ON checklist_templates
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Comment for documentation
COMMENT ON TABLE checklist_templates IS 'Pre-maintained checklist templates for each city, shared by all users';
COMMENT ON COLUMN checklist_templates.is_active IS 'Whether this template is active/enabled';
COMMENT ON COLUMN checklist_templates.items IS 'JSON array of checklist items with title, location, category, etc.';
