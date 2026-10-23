-- A station key configures a shared device; it is separate from employee PINs.
BEGIN;
-- Non-superuser postgres needs the target owner to have CREATE during ownership transfer.
-- Both grant and revoke are in this transaction; the role retains no CREATE afterwards.
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_create_station(p_name text,p_token text DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE token text:=nullif(btrim(p_token),''); station_id uuid;
BEGIN
 PERFORM public.work_assert_admin();
 IF p_name IS NULL OR length(btrim(p_name)) NOT BETWEEN 1 AND 100 THEN
  RAISE EXCEPTION 'Introduce un nombre de punto de entre 1 y 100 caracteres';
 END IF;
 IF token IS NULL THEN RETURN public.work_create_credential('station',btrim(p_name),NULL); END IF;
 IF length(token) NOT BETWEEN 8 AND 128 OR token ~ '[[:cntrl:]]' THEN
  RAISE EXCEPTION 'La clave del punto debe tener entre 8 y 128 caracteres, sin saltos de línea';
 END IF;
 INSERT INTO public.work_stations(name,token_hash)
 VALUES(btrim(p_name),public.work_hash(token)) RETURNING id INTO station_id;
 INSERT INTO public.work_station_keys(station_id,token) VALUES(station_id,token);
 RETURN jsonb_build_object('id',station_id,'token',token,'kind','station');
EXCEPTION WHEN unique_violation THEN
 RAISE EXCEPTION 'No se pudo utilizar esa clave. Elige una diferente';
END $$;
ALTER FUNCTION public.work_create_station(text,text) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_create_station(text,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.work_create_station(text,text) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
