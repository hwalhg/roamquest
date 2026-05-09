-- Keep public catalog tables readable by the app, but prevent clients using
-- the anon key from modifying official city/attraction data.
GRANT SELECT ON public.cities TO anon, authenticated;
GRANT SELECT ON public.attractions TO anon, authenticated;

REVOKE INSERT, UPDATE, DELETE ON public.cities FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.attractions FROM anon, authenticated;
