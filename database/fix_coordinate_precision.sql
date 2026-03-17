-- ========================================
-- Fix coordinate precision issue
-- Problem: DECIMAL(10,8) only allows 2 integer digits (±99.99999999)
-- Solution: Change to DECIMAL(11,8) to allow 3 integer digits (±999.99999999)
-- This fixes longitude values like -122.4194, -74.0060, etc.
-- ========================================

-- Fix cities table
ALTER TABLE cities
ALTER COLUMN latitude TYPE DECIMAL(11, 8),
ALTER COLUMN longitude TYPE DECIMAL(11, 8);

-- Fix checklist_items table
ALTER TABLE checklist_items
ALTER COLUMN latitude TYPE DECIMAL(11, 8),
ALTER COLUMN longitude TYPE DECIMAL(11, 8);
