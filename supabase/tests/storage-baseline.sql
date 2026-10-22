CREATE POLICY "sec04_read_assigned_task_files" ON storage.objects AS PERMISSIVE FOR SELECT TO authenticated USING (((bucket_id = 'task-files'::text) AND (((name ~ '^tasks/[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(png|jpg|jpeg|gif|webp|mp4|webm|mov)$'::text) AND (EXISTS ( SELECT 1
   FROM task_assignments a
  WHERE (((a.task_id)::text = split_part(objects.name, '/'::text, 2)) AND (a.user_id = ( SELECT auth.uid() AS uid)))))) OR ((name ~ '^(images|videos)/[0-9a-f-]{36}-[0-9]+\.[a-z0-9]+$'::text) AND (EXISTS ( SELECT 1
   FROM (task_comments c
     JOIN task_assignments a ON ((a.task_id = c.task_id)))
  WHERE ((a.user_id = ( SELECT auth.uid() AS uid)) AND (((strpos(c.image_url, '/storage/v1/object/public/task-files/'::text) > 0) AND (split_part(c.image_url, '/storage/v1/object/public/task-files/'::text, 2) = objects.name)) OR ((strpos(c.video_url, '/storage/v1/object/public/task-files/'::text) > 0) AND (split_part(c.video_url, '/storage/v1/object/public/task-files/'::text, 2) = objects.name))))))))));
CREATE POLICY "sec04_upload_own_assigned_task_files" ON storage.objects AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (((bucket_id = 'task-files'::text) AND (name ~ '^tasks/[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(png|jpg|jpeg|gif|webp|mp4|webm|mov)$'::text) AND (split_part(name, '/'::text, 3) = (( SELECT auth.uid() AS uid))::text) AND (EXISTS ( SELECT 1
   FROM task_assignments a
  WHERE (((a.task_id)::text = split_part(objects.name, '/'::text, 2)) AND (a.user_id = ( SELECT auth.uid() AS uid)))))));
CREATE POLICY "work_files_insert" ON storage.objects AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((bucket_id <> 'task-files'::text) OR work_can_file(name)));
CREATE POLICY "work_files_read" ON storage.objects AS RESTRICTIVE FOR SELECT TO authenticated USING (((bucket_id <> 'task-files'::text) OR work_can_file(name)));
