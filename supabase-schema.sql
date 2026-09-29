-- Run this once in the Supabase SQL Editor for the EBO Variance Report.
-- The browser app uses only the public anon key. Never put a service_role key in index.html.

create table if not exists public.variance_reports (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  report_name text not null,
  category text not null default 'FG' check (category in ('FG', 'Sample', 'Others')),
  source_files jsonb not null default '[]'::jsonb,
  summary jsonb not null default '{}'::jsonb,
  consolidated jsonb not null default '[]'::jsonb,
  ebo_detail jsonb not null default '[]'::jsonb,
  price_master jsonb not null default '[]'::jsonb,
  source_data jsonb not null default '[]'::jsonb,
  checks jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.variance_reports enable row level security;

drop policy if exists "Users can read their variance reports" on public.variance_reports;
create policy "Users can read their variance reports"
  on public.variance_reports for select to authenticated
  using (user_id = auth.uid());

drop policy if exists "Users can save their variance reports" on public.variance_reports;
create policy "Users can save their variance reports"
  on public.variance_reports for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists "Users can delete their variance reports" on public.variance_reports;
create policy "Users can delete their variance reports"
  on public.variance_reports for delete to authenticated
  using (user_id = auth.uid());

insert into storage.buckets (id, name, public)
values ('variance-reports', 'variance-reports', false)
on conflict (id) do update set public = excluded.public;

drop policy if exists "Users can upload their variance files" on storage.objects;
create policy "Users can upload their variance files"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'variance-reports'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users can read their variance files" on storage.objects;
create policy "Users can read their variance files"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'variance-reports'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users can delete their variance files" on storage.objects;
create policy "Users can delete their variance files"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'variance-reports'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
