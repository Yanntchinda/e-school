-- =====================================================================
-- E-SCHOOL / GESTION DES BULLETINS — SCHÉMA SUPABASE COMPLET
-- À exécuter en une seule fois dans : Supabase → SQL Editor → New query
-- Aucune donnée existante n'est écrasée (script idempotent).
-- =====================================================================

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------
-- 0. Fonction utilitaire : mise à jour automatique de updated_at
-- ---------------------------------------------------------------------
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
 new.updated_at := now();
 return new;
end $$;

-- ---------------------------------------------------------------------
-- 1. ÉTABLISSEMENTS (une ligne par école)
-- ---------------------------------------------------------------------
create table if not exists public.schools (
 id text primary key,
 name text not null default '',
 city text default '',
 year text default '',
 principal text default '',
 header text, -- en-tête des bulletins (image base64)
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 2. UTILISATEURS (connexion interne de l'application : identifiant + mot de passe)
-- ---------------------------------------------------------------------
create table if not exists public.app_users (
 id text primary key,
 school_id text not null references public.schools(id) on delete cascade,
 username text not null,
 name text not null default '',
 phone text default '',
 role text not null default 'prof' check (role in ('admin','prof')),
 salt text default '',
 hash text default '',
 active boolean not null default true,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique (school_id, username)
);

-- ---------------------------------------------------------------------
-- 3. CLASSES
-- ---------------------------------------------------------------------
create table if not exists public.classes (
 id text primary key,
 school_id text not null references public.schools(id) on delete cascade,
 name text not null default '',
 preset_key text default '',
 ord int not null default 0,
 lang text not null default 'fr',
 pp_id text default '',
 pp_name text default '',
 pp_tel text default '',
 locks jsonb not null default '{"1":false,"2":false,"3":false}'::jsonb,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 4. MATIÈRES (une ligne par matière et par classe)
-- ---------------------------------------------------------------------
create table if not exists public.subjects (
 id text primary key,
 school_id text not null references public.schools(id) on delete cascade,
 class_id text not null references public.classes(id) on delete cascade,
 name text not null default '',
 coef numeric(6,2) not null default 1,
 is_opt boolean not null default false,
 group_name text default '',
 teacher_id text default '',
 ord int not null default 0,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 5. ÉLÈVES
-- ---------------------------------------------------------------------
create table if not exists public.students (
 id text primary key,
 school_id text not null references public.schools(id) on delete cascade,
 class_id text not null references public.classes(id) on delete cascade,
 name text not null default '',
 sex text default '',
 mat text default '', -- matricule (permanent)
 dob text default '',
 pob text default '',
 photo text, -- base64 éventuel
 session_tag text not null default 'N', -- N = nouveau, NA = promu, Ancien = redoublant
 ord int not null default 0,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 6. NOTES (1 ligne = 1 élève × 1 matière, 5 séquences possibles)
-- id = '<student_id>:<subject_id>'
-- ---------------------------------------------------------------------
create table if not exists public.grades (
 id text primary key,
 school_id text not null references public.schools(id) on delete cascade,
 student_id text not null references public.students(id) on delete cascade,
 subject_id text not null references public.subjects(id) on delete cascade,
 seqs numeric(4,2)[] not null default '{null,null,null,null,null}',
 updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 7. APPRÉCIATIONS (1 ligne = 1 élève × 1 trimestre)
-- id = '<student_id>:t<trim>'
-- ---------------------------------------------------------------------
create table if not exists public.remarks (
 id text primary key,
 school_id text not null references public.schools(id) on delete cascade,
 student_id text not null references public.students(id) on delete cascade,
 trim int not null check (trim between 1 and 3),
 text text not null default '',
 updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 8. LEÇONS / PROGRESSION DES MATIÈRES
-- id = '<class_id>:<subject_id>'
-- ---------------------------------------------------------------------
create table if not exists public.lessons (
 id text primary key,
 school_id text not null references public.schools(id) on delete cascade,
 class_id text not null references public.classes(id) on delete cascade,
 subject_id text not null references public.subjects(id) on delete cascade,
 planned int not null default 0 check (planned >= 0),
 done int not null default 0 check (done >= 0),
 updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 9. ARCHIVES DE SESSIONS (années clôturées)
-- ---------------------------------------------------------------------
create table if not exists public.archives (
 id text primary key,
 school_id text not null references public.schools(id) on delete cascade,
 year text not null,
 payload jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 10. INDEX (performances)
-- ---------------------------------------------------------------------
create index if not exists idx_users_school on public.app_users (school_id);
create index if not exists idx_classes_school on public.classes (school_id);
create index if not exists idx_subjects_class on public.subjects (class_id);
create index if not exists idx_subjects_teacher on public.subjects (teacher_id);
create index if not exists idx_students_class on public.students (class_id);
create index if not exists idx_grades_student on public.grades (student_id);
create index if not exists idx_grades_subject on public.grades (subject_id);
create index if not exists idx_remarks_student on public.remarks (student_id);
create index if not exists idx_lessons_class on public.lessons (class_id);
create index if not exists idx_lessons_subject on public.lessons (subject_id);
create index if not exists idx_archives_school on public.archives (school_id);

-- ---------------------------------------------------------------------
-- 11. TRIGGERS updated_at
-- ---------------------------------------------------------------------
drop trigger if exists trg_touch_schools on public.schools;
create trigger trg_touch_schools before update on public.schools
 for each row execute function public.touch_updated_at();

drop trigger if exists trg_touch_users on public.app_users;
create trigger trg_touch_users before update on public.app_users
 for each row execute function public.touch_updated_at();

drop trigger if exists trg_touch_classes on public.classes;
create trigger trg_touch_classes before update on public.classes
 for each row execute function public.touch_updated_at();

drop trigger if exists trg_touch_subjects on public.subjects;
create trigger trg_touch_subjects before update on public.subjects
 for each row execute function public.touch_updated_at();

drop trigger if exists trg_touch_students on public.students;
create trigger trg_touch_students before update on public.students
 for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------
-- 12. RPC : APP_PULL — l'application télécharge TOUTES les données de l'école
-- ---------------------------------------------------------------------
create or replace function public.app_pull(p_school text)
returns jsonb
language sql
security definer
set search_path = public
as $$
 select jsonb_build_object(
 'school', (select to_jsonb(s) from public.schools s where s.id = p_school),
 'users', coalesce((select jsonb_agg(to_jsonb(u) order by u.name) from public.app_users u where u.school_id = p_school), '[]'::jsonb),
 'classes', coalesce((select jsonb_agg(to_jsonb(c) order by c.ord, c.name) from public.classes c where c.school_id = p_school), '[]'::jsonb),
 'subjects', coalesce((select jsonb_agg(to_jsonb(x) order by x.ord) from public.subjects x where x.school_id = p_school), '[]'::jsonb),
 'students', coalesce((select jsonb_agg(to_jsonb(x) order by x.ord) from public.students x where x.school_id = p_school), '[]'::jsonb),
 'grades', coalesce((select jsonb_agg(jsonb_build_object('id',g.id,'student_id',g.student_id,'subject_id',g.subject_id,'seqs',to_jsonb(g.seqs))) from public.grades g where g.school_id = p_school), '[]'::jsonb),
 'remarks', coalesce((select jsonb_agg(to_jsonb(x)) from public.remarks x where x.school_id = p_school), '[]'::jsonb),
 'lessons', coalesce((select jsonb_agg(to_jsonb(x)) from public.lessons x where x.school_id = p_school), '[]'::jsonb),
 'server_time', now()
 );
$$;

-- ---------------------------------------------------------------------
-- 13. RPC : APP_PUSH — l'application envoie uniquement les lignes modifiées
-- p_payload = {
-- "school": {...},
-- "users": [...], "classes": [...], "subjects": [...], "students": [...],
-- "grades": [...], "remarks": [...], "lessons": [...],
-- "deleted": { "users":[ids], "classes":[ids], ... }
-- }
-- ---------------------------------------------------------------------
create or replace function public.app_push(p_school text, p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
 r jsonb;
 v_rows int := 0;
begin
 ---------------------------------------------------------------- école
 insert into public.schools (id) values (p_school) on conflict (id) do nothing;

 if p_payload ? 'school' then
 update public.schools s set
 name = coalesce(nullif(p_payload->'school'->>'name',''), s.name),
 city = coalesce(p_payload->'school'->>'city', s.city),
 year = coalesce(nullif(p_payload->'school'->>'year',''), s.year),
 principal = coalesce(p_payload->'school'->>'principal', s.principal),
 header = coalesce(p_payload->'school'->>'header', s.header)
 where s.id = p_school;
 end if;

 ---------------------------------------------------------------- utilisateurs
 for r in select value from jsonb_array_elements(coalesce(p_payload->'users','[]'::jsonb)) loop
 insert into public.app_users (id, school_id, username, name, phone, role, salt, hash)
 values (r->>'id', p_school,
 lower(coalesce(r->>'username','')),
 coalesce(r->>'name',''),
 coalesce(r->>'phone',''),
 coalesce(nullif(r->>'role',''),'prof'),
 coalesce(r->>'salt',''),
 coalesce(r->>'hash',''))
 on conflict (id) do update set
 username = excluded.username,
 name = excluded.name,
 phone = excluded.phone,
 role = excluded.role,
 salt = excluded.salt,
 hash = excluded.hash;
 v_rows := v_rows + 1;
 end loop;

 ---------------------------------------------------------------- classes
 for r in select value from jsonb_array_elements(coalesce(p_payload->'classes','[]'::jsonb)) loop
 insert into public.classes (id, school_id, name, preset_key, ord, lang, pp_id, pp_name, pp_tel, locks)
 values (r->>'id', p_school,
 coalesce(r->>'name',''),
 coalesce(r->>'preset_key',''),
 coalesce((r->>'ord')::int,0),
 coalesce(nullif(r->>'lang',''),'fr'),
 coalesce(r->>'pp_id',''),
 coalesce(r->>'pp_name',''),
 coalesce(r->>'pp_tel',''),
 coalesce(r->'locks','{}'::jsonb))
 on conflict (id) do update set
 name = excluded.name,
 preset_key = excluded.preset_key,
 ord = excluded.ord,
 lang = excluded.lang,
 pp_id = excluded.pp_id,
 pp_name = excluded.pp_name,
 pp_tel = excluded.pp_tel,
 locks = excluded.locks;
 v_rows := v_rows + 1;
 end loop;

 ---------------------------------------------------------------- matières
 for r in select value from jsonb_array_elements(coalesce(p_payload->'subjects','[]'::jsonb)) loop
 insert into public.subjects (id, school_id, class_id, name, coef, is_opt, group_name, teacher_id, ord)
 values (r->>'id', p_school,
 (r->>'class_id'),
 coalesce(r->>'name',''),
 coalesce((r->>'coef')::numeric,1),
 coalesce((r->>'is_opt')::boolean,false),
 coalesce(r->>'group_name',''),
 coalesce(r->>'teacher_id',''),
 coalesce((r->>'ord')::int,0))
 on conflict (id) do update set
 class_id = excluded.class_id,
 name = excluded.name,
 coef = excluded.coef,
 is_opt = excluded.is_opt,
 group_name = excluded.group_name,
 teacher_id = excluded.teacher_id,
 ord = excluded.ord;
 v_rows := v_rows + 1;
 end loop;

 ---------------------------------------------------------------- élèves
 for r in select value from jsonb_array_elements(coalesce(p_payload->'students','[]'::jsonb)) loop
 insert into public.students (id, school_id, class_id, name, sex, mat, dob, pob, photo, session_tag, ord)
 values (r->>'id', p_school,
 (r->>'class_id'),
 coalesce(r->>'name',''),
 coalesce(r->>'sex',''),
 coalesce(r->>'mat',''),
 coalesce(r->>'dob',''),
 coalesce(r->>'pob',''),
 nullif(r->>'photo',''),
 coalesce(nullif(r->>'session_tag',''),'N'),
 coalesce((r->>'ord')::int,0))
 on conflict (id) do update set
 class_id = excluded.class_id,
 name = excluded.name,
 sex = excluded.sex,
 mat = excluded.mat,
 dob = excluded.dob,
 pob = excluded.pob,
 photo = excluded.photo,
 session_tag = excluded.session_tag,
 ord = excluded.ord;
 v_rows := v_rows + 1;
 end loop;

 ---------------------------------------------------------------- notes
 for r in select value from jsonb_array_elements(coalesce(p_payload->'grades','[]'::jsonb)) loop
 insert into public.grades (id, school_id, student_id, subject_id, seqs)
 values (r->>'id', p_school,
 (r->>'student_id'),
 (r->>'subject_id'),
 coalesce((select array_agg(nullif(v,'')::numeric) from jsonb_array_elements_text(coalesce(r->'seqs','[]'::jsonb)) v), '{null,null,null,null,null}'::numeric[]))
 on conflict (id) do update set
 seqs = excluded.seqs;
 v_rows := v_rows + 1;
 end loop;

 ---------------------------------------------------------------- appréciations
 for r in select value from jsonb_array_elements(coalesce(p_payload->'remarks','[]'::jsonb)) loop
 insert into public.remarks (id, school_id, student_id, trim, text)
 values (r->>'id', p_school,
 (r->>'student_id'),
 coalesce((r->>'trim')::int,1),
 coalesce(r->>'text',''))
 on conflict (id) do update set
 text = excluded.text;
 v_rows := v_rows + 1;
 end loop;

 ---------------------------------------------------------------- leçons
 for r in select value from jsonb_array_elements(coalesce(p_payload->'lessons','[]'::jsonb)) loop
 insert into public.lessons (id, school_id, class_id, subject_id, planned, done, updated_at)
 values (r->>'id', p_school,
 (r->>'class_id'),
 (r->>'subject_id'),
 greatest(coalesce((r->>'planned')::int,0),0),
 greatest(coalesce((r->>'done')::int,0),0),
 coalesce(to_timestamp(nullif(r->>'at','')::bigint / 1000), now()))
 on conflict (id) do update set
 planned = excluded.planned,
 done = excluded.done,
 updated_at = excluded.updated_at;
 v_rows := v_rows + 1;
 end loop;

 ---------------------------------------------------------------- suppressions
 if p_payload ? 'deleted' then
 delete from public.lessons where school_id = p_school and id in (select jsonb_array_elements_text(coalesce(p_payload->'deleted'->'lessons','[]'::jsonb)));
 delete from public.remarks where school_id = p_school and id in (select jsonb_array_elements_text(coalesce(p_payload->'deleted'->'remarks','[]'::jsonb)));
 delete from public.grades where school_id = p_school and id in (select jsonb_array_elements_text(coalesce(p_payload->'deleted'->'grades','[]'::jsonb)));
 delete from public.students where school_id = p_school and id in (select jsonb_array_elements_text(coalesce(p_payload->'deleted'->'students','[]'::jsonb)));
 delete from public.subjects where school_id = p_school and id in (select jsonb_array_elements_text(coalesce(p_payload->'deleted'->'subjects','[]'::jsonb)));
 delete from public.classes where school_id = p_school and id in (select jsonb_array_elements_text(coalesce(p_payload->'deleted'->'classes','[]'::jsonb)));
 delete from public.app_users where school_id = p_school and id in (select jsonb_array_elements_text(coalesce(p_payload->'deleted'->'users','[]'::jsonb)));
 end if;

 return jsonb_build_object('ok', true, 'rows', v_rows, 'at', now());
end $$;

-- ---------------------------------------------------------------------
-- 14. SÉCURITÉ (RLS)
--
-- PAR défaut : accès avec la clé « anon » — l'application gère elle-même
-- la connexion (identifiant + mot de passe). Convenable pour un
-- déploiement privé mono-établissement.
--
-- POUR VERROUILLER (recommandé en production publique) :
-- supprimez les politiques « anon_* » ci-dessous, puis décommentez le
-- bloc « MODE SÉCURISÉ » à la fin du fichier (02-securite-auth.sql).
-- ---------------------------------------------------------------------
alter table public.schools enable row level security;
alter table public.app_users enable row level security;
alter table public.classes enable row level security;
alter table public.subjects enable row level security;
alter table public.students enable row level security;
alter table public.grades enable row level security;
alter table public.remarks enable row level security;
alter table public.lessons enable row level security;
alter table public.archives enable row level security;

do $$
declare t text;
begin
 foreach t in array array['schools','app_users','classes','subjects','students','grades','remarks','lessons','archives']
 loop
 execute format('drop policy if exists anon_all_%1$s on public.%1$I', t);
 execute format('create policy anon_all_%1$s on public.%1$I for all to anon, authenticated using (true) with check (true)', t);
 end loop;
end $$;

-- ---------------------------------------------------------------------
-- 15. TEMPS RÉEL (les modifications des professeurs arrivent chez l'admin)
-- ---------------------------------------------------------------------
do $$
begin
 begin execute 'alter publication supabase_realtime add table public.lessons'; exception when others then null; end;
 begin execute 'alter publication supabase_realtime add table public.grades'; exception when others then null; end;
 begin execute 'alter publication supabase_realtime add table public.remarks'; exception when others then null; end;
 begin execute 'alter publication supabase_realtime add table public.students'; exception when others then null; end;
end $$;

-- ---------------------------------------------------------------------
-- 16. VÉRIFICATION FINALE
-- ---------------------------------------------------------------------
select 'Schéma e-school installé ' as resultat,
 (select count(*) from information_schema.tables
 where table_schema='public'
 and table_name in ('schools','app_users','classes','subjects','students','grades','remarks','lessons','archives')) as tables_creees,
 (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname='public' and p.proname in ('app_pull','app_push')) as fonctions_creees;
