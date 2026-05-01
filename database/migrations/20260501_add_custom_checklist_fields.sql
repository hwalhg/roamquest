ALTER TABLE checklists
ADD COLUMN IF NOT EXISTS source VARCHAR(32) NOT NULL DEFAULT 'city';

ALTER TABLE checklists
ADD COLUMN IF NOT EXISTS title VARCHAR(255);

ALTER TABLE checklists
ADD COLUMN IF NOT EXISTS description TEXT;

UPDATE checklists c
SET title = COALESCE(c.title, cities.name)
FROM cities
WHERE c.city_id = cities.id
  AND c.title IS NULL;

UPDATE checklists
SET title = COALESCE(title, 'Custom Checklist');

CREATE INDEX IF NOT EXISTS idx_checklists_source
ON checklists(source);
