-- Create nanoid in extensions schema (canonical location)
CREATE OR REPLACE FUNCTION extensions.nanoid(size integer DEFAULT 10, alphabet text DEFAULT '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'::text) RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
    idBuilder text := '';
    i int := 0;
    bytes bytea;
    alphabetIndex int;
    mask int;
    step int;
BEGIN
    mask := (2 << cast(floor(log(length(alphabet) - 1) / log(2)) as int)) -1;
    step := cast(ceil(1.6 * mask * size / length(alphabet)) AS int);
    while true loop
            bytes := gen_random_bytes(size);
            while i < size loop
                    alphabetIndex := get_byte(bytes, i) & mask;
                    if alphabetIndex < length(alphabet) then
                        idBuilder := idBuilder || substr(alphabet, alphabetIndex, 1);
                        if length(idBuilder) = size then
                            return idBuilder;
                        end if;
                    end if;
                    i = i + 1;
                end loop;
            i := 0;
        end loop;
END
$$;

-- Replace public.nanoid with a thin wrapper so existing column defaults keep working
CREATE OR REPLACE FUNCTION public.nanoid(size integer DEFAULT 10, alphabet text DEFAULT '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'::text) RETURNS text
    LANGUAGE sql STABLE
    AS $$
    SELECT extensions.nanoid(size, alphabet);
$$;

GRANT EXECUTE ON FUNCTION extensions.nanoid(integer, text) TO authenticated, anon, service_role;
