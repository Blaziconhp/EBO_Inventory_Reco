-- Run this once in the Supabase SQL Editor for the EBO Variance Report.
-- The browser app uses only the public anon/publishable key. Never put a service_role key in index.html.
-- The primary email below is the only account allowed to upload, save, replace, or delete data.

create table if not exists public.variance_reports (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  report_name text not null,
  reconciliation_month text not null default 'Legacy',
  category text not null default 'FG' check (category in ('FG', 'Sample', 'Others')),
  source_files jsonb not null default '[]'::jsonb,
  raw_sheets jsonb not null default '{}'::jsonb,
  summary jsonb not null default '{}'::jsonb,
  consolidated jsonb not null default '[]'::jsonb,
  ebo_detail jsonb not null default '[]'::jsonb,
  price_master jsonb not null default '[]'::jsonb,
  source_data jsonb not null default '[]'::jsonb,
  checks jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.variance_reports add column if not exists raw_sheets jsonb not null default '{}'::jsonb;
alter table public.variance_reports add column if not exists updated_at timestamptz not null default now();
alter table public.variance_reports add column if not exists reconciliation_month text not null default 'Legacy';
create index if not exists variance_reports_reconciliation_month_idx on public.variance_reports (reconciliation_month, updated_at desc);
alter table public.variance_reports enable row level security;

drop policy if exists "Users can read their variance reports" on public.variance_reports;
drop policy if exists "All authenticated users can read the current variance report" on public.variance_reports;
create policy "All authenticated users can read the current variance report"
  on public.variance_reports for select to authenticated
  using (auth.role() = 'authenticated');

drop policy if exists "Users can save their variance reports" on public.variance_reports;
drop policy if exists "Primary user can save the variance report" on public.variance_reports;
create policy "Primary user can save the variance report"
  on public.variance_reports for insert to authenticated
  with check (lower(coalesce(auth.jwt()->>'email', '')) = 'harsh.p@boheco.com');

drop policy if exists "Primary user can update the variance report" on public.variance_reports;
create policy "Primary user can update the variance report"
  on public.variance_reports for update to authenticated
  using (lower(coalesce(auth.jwt()->>'email', '')) = 'harsh.p@boheco.com')
  with check (lower(coalesce(auth.jwt()->>'email', '')) = 'harsh.p@boheco.com');

drop policy if exists "Users can delete their variance reports" on public.variance_reports;
drop policy if exists "Primary user can delete the variance report" on public.variance_reports;
create policy "Primary user can delete the variance report"
  on public.variance_reports for delete to authenticated
  using (lower(coalesce(auth.jwt()->>'email', '')) = 'harsh.p@boheco.com');

insert into storage.buckets (id, name, public)
values ('variance-reports', 'variance-reports', false)
on conflict (id) do update set public = excluded.public;

drop policy if exists "Users can upload their variance files" on storage.objects;
drop policy if exists "Primary user can upload variance files" on storage.objects;
create policy "Primary user can upload variance files"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'variance-reports'
    and (storage.foldername(name))[1] = auth.uid()::text
    and lower(coalesce(auth.jwt()->>'email', '')) = 'harsh.p@boheco.com'
  );

drop policy if exists "Primary user can update variance files" on storage.objects;
create policy "Primary user can update variance files"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'variance-reports'
    and (storage.foldername(name))[1] = auth.uid()::text
    and lower(coalesce(auth.jwt()->>'email', '')) = 'harsh.p@boheco.com'
  )
  with check (
    bucket_id = 'variance-reports'
    and (storage.foldername(name))[1] = auth.uid()::text
    and lower(coalesce(auth.jwt()->>'email', '')) = 'harsh.p@boheco.com'
  );

drop policy if exists "Users can read their variance files" on storage.objects;
drop policy if exists "All authenticated users can read variance files" on storage.objects;
create policy "All authenticated users can read variance files"
  on storage.objects for select to authenticated
  using (bucket_id = 'variance-reports' and auth.role() = 'authenticated');

drop policy if exists "Users can delete their variance files" on storage.objects;
drop policy if exists "Primary user can delete variance files" on storage.objects;
create policy "Primary user can delete variance files"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'variance-reports'
    and (storage.foldername(name))[1] = auth.uid()::text
    and lower(coalesce(auth.jwt()->>'email', '')) = 'harsh.p@boheco.com'
  );
