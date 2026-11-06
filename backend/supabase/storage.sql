-- Sema photo storage: Supabase Storage secured by Firebase Auth tokens.
-- Run in the Supabase SQL editor (project zytiomskeexcgwjkjicz) after adding
-- Firebase project "sema-campus-alu" under Authentication > Third-Party Auth.
-- Safe to re-run.

-- Public-read bucket for report and profile photos: images only, 5 MB max.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('photos', 'photos', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- The caller's Firebase uid when the request carries a verified ALU Firebase token
-- from the sema-campus-alu project; null otherwise.
create or replace function public.firebase_alu_uid()
returns text
language sql
stable
as $$
  select case
    when auth.jwt() ->> 'iss' = 'https://securetoken.google.com/sema-campus-alu'
     and auth.jwt() ->> 'aud' = 'sema-campus-alu'
     and coalesce((auth.jwt() ->> 'email_verified')::boolean, false)
     and lower(auth.jwt() ->> 'email') ~ '@(alustudent|alueducation)[.]com$'
    then auth.jwt() ->> 'sub'
  end
$$;

-- Owner-only writes: reports/<uid>/... and avatars/<uid>/...
drop policy if exists "sema owner insert" on storage.objects;
drop policy if exists "sema owner select" on storage.objects;
drop policy if exists "sema owner update" on storage.objects;
drop policy if exists "sema owner delete" on storage.objects;

create policy "sema owner insert" on storage.objects for insert to public
  with check (bucket_id = 'photos'
    and (storage.foldername(name))[1] in ('reports', 'avatars')
    and (storage.foldername(name))[2] = public.firebase_alu_uid());

create policy "sema owner select" on storage.objects for select to public
  using (bucket_id = 'photos'
    and (storage.foldername(name))[2] = public.firebase_alu_uid());

create policy "sema owner update" on storage.objects for update to public
  using (bucket_id = 'photos'
    and (storage.foldername(name))[2] = public.firebase_alu_uid())
  with check (bucket_id = 'photos'
    and (storage.foldername(name))[1] in ('reports', 'avatars')
    and (storage.foldername(name))[2] = public.firebase_alu_uid());

create policy "sema owner delete" on storage.objects for delete to public
  using (bucket_id = 'photos'
    and (storage.foldername(name))[2] = public.firebase_alu_uid());
