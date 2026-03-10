-- ============================================
-- Fix checklists table structure
-- ============================================

-- Drop existing checklists table
DROP TABLE IF EXISTS public.checklists CASCADE;

-- Recreate checklists table with correct structure
CREATE TABLE public.checklists (
    id TEXT PRIMARY KEY,
    user_id UUID DEFAULT auth.uid(),
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

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_checklists_user_id ON public.checklists(user_id);
CREATE INDEX IF NOT EXISTS idx_checklists_city_name ON public.checklists(city_name, country);
CREATE INDEX IF NOT EXISTS idx_checklists_created_at ON public.checklists(created_at DESC);

-- Enable RLS
ALTER TABLE public.checklists ENABLE ROW LEVEL SECURITY;

-- Allow guests to create checklists
CREATE POLICY "Guests can create checklists"
ON public.checklists FOR INSERT
WITH CHECK (user_id IS NULL);

-- Allow authenticated users to create own checklists
CREATE POLICY "Users can create own checklists"
ON public.checklists FOR INSERT
WITH CHECK (user_id = auth.uid());

-- Allow users to view own checklists
CREATE POLICY "Users can view own checklists"
ON public.checklists FOR SELECT
USING (auth.uid() IS NULL OR user_id = auth.uid());

-- Allow users to update own checklists
CREATE POLICY "Users can update own checklists"
ON public.checklists FOR UPDATE
USING (auth.uid() IS NULL OR user_id = auth.uid());

-- Allow users to delete own checklists
CREATE POLICY "Users can delete own checklists"
ON public.checklists FOR DELETE
USING (auth.uid() IS NULL OR user_id = auth.uid());

SELECT 'Checklists table structure fixed successfully' as status;
