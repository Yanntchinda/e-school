-- =====================================================================
--  GestSchool — REQUÊTES UTILES (facultatives)
--  À coller dans Supabase → SQL Editor pour contrôler le système.
-- =====================================================================

-- 1. Vue d'ensemble de la base -----------------------------------------
select
  (select count(*) from public.classes)   as classes,
  (select count(*) from public.subjects)  as matieres,
  (select count(*) from public.students)  as eleves,
  (select count(*) from public.app_users) as comptes,
  (select count(*) from public.grades)    as lignes_de_notes,
  (select count(*) from public.lessons)   as lignes_de_lecons;

-- 2. Progression des leçons par matière (ce que voit l'administrateur) --
select c.name                as classe,
       s.name                as matiere,
       coalesce(u.name,'Non attribué') as enseignant,
       l.planned             as prevues,
       l.done                as faites,
       case when l.planned > 0
            then round(l.done::numeric * 100 / l.planned, 1)
            else 0 end       as pct
from public.lessons l
join public.classes  c on c.id = l.class_id
join public.subjects s on s.id = l.subject_id
left join public.app_users u on u.id::text = s.teacher_id
order by c.ord, s.ord;

-- 3. Avancement global de l'établissement ------------------------------
select sum(planned) as total_prevues,
       sum(done)    as total_faites,
       case when sum(planned) > 0
            then round(sum(done)::numeric * 100 / sum(planned), 1)
            else 0 end as avancement_global_pct
from public.lessons;

-- 4. Matières en retard (< 50 %) avec le nom du professeur -------------
select c.name as classe, s.name as matiere, u.name as enseignant,
       l.done || '/' || l.planned as avancement
from public.lessons l
join public.classes  c on c.id = l.class_id
join public.subjects s on s.id = l.subject_id
left join public.app_users u on u.id::text = s.teacher_id
where l.planned > 0 and (l.done::numeric / l.planned) < 0.5
order by (l.done::numeric / l.planned) asc;

-- 5. Nombre de notes saisies par professeur ----------------------------
select u.name as enseignant,
       count(g.id) as lignes_de_notes,
       count(*) filter (where g.seqs[1] is not null) as avec_sequence_1
from public.subjects s
join public.app_users u on u.id::text = s.teacher_id
left join public.grades g on g.subject_id = s.id
group by u.name
order by lignes_de_notes desc;

-- 6. Élèves sans aucune note (à relancer) ------------------------------
select c.name as classe, st.name as eleve
from public.students st
join public.classes c on c.id = st.class_id
left join public.grades g on g.student_id = st.id
where g.id is null
order by c.ord, st.ord;

-- 7. Dernières modifications (qui a touché quoi et quand) --------------
select 'leçons' as table_, count(*) as lignes, max(updated_at) as derniere_modif from public.lessons
union all
select 'notes',   count(*), max(updated_at) from public.grades
union all
select 'élèves',  count(*), max(updated_at) from public.students;

-- 8. Vérifier que le temps réel est actif ------------------------------
select tablename
from pg_publication_tables
where pubname = 'supabase_realtime'
order by tablename;

-- 9. Sauvegarde complète en JSON (à conserver) -------------------------
-- select jsonb_pretty(public.app_pull('VOTRE-CODE-ECOLE'));

-- 10. Remise à zéro des leçons (début d'année) -------------------------
-- update public.lessons set planned = 0, done = 0;
