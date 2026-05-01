ALTER TABLE checklist_items
ADD COLUMN IF NOT EXISTS source VARCHAR(32) NOT NULL DEFAULT 'official';

ALTER TABLE checklist_items
ADD COLUMN IF NOT EXISTS spot_latitude DECIMAL(11, 8);

ALTER TABLE checklist_items
ADD COLUMN IF NOT EXISTS spot_longitude DECIMAL(11, 8);

ALTER TABLE checklist_items
ADD COLUMN IF NOT EXISTS checkin_latitude DECIMAL(11, 8);

ALTER TABLE checklist_items
ADD COLUMN IF NOT EXISTS checkin_longitude DECIMAL(11, 8);

UPDATE checklist_items
SET
  spot_latitude = COALESCE(spot_latitude, latitude),
  spot_longitude = COALESCE(spot_longitude, longitude)
WHERE latitude IS NOT NULL
  AND longitude IS NOT NULL;

UPDATE checklist_items
SET
  checkin_latitude = COALESCE(checkin_latitude, latitude),
  checkin_longitude = COALESCE(checkin_longitude, longitude)
WHERE is_completed = true
  AND latitude IS NOT NULL
  AND longitude IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_checklist_items_source
ON checklist_items(source);
