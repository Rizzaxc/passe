DROP FUNCTION IF EXISTS public.create_lobby_with_location(text,int,text,jsonb,jsonb,text,text,text,text);
ALTER FUNCTION public.create_lobby_with_location(text,int,text,jsonb,jsonb,uuid,text,text,text,text,text) OWNER TO postgres;
