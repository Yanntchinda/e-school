-- =====================================================================
-- e-school — MODE SÉCURISÉ (optionnel mais recommandé si l'URL est publique)
-- À exécuter APRÈS 01-schema.sql, uniquement quand vous êtes prêt.
--
-- Ce script supprime l'accès direct avec la clé « anon » et exige une
-- session Supabase (même anonyme) pour lire/écrire.
--
-- ÉTAPES PRÉALABLES, DANS LE TABLEAU DE BORD SUPABASE :
-- Authentication → Sign In / Providers → « Allow anonymous sign-ins » : ON
-- Authentication → Settings → « Enable email provider » peut rester OFF.
--
-- L'application tente automatiquement une connexion anonyme au démarrage
-- (fonction Cloud.connect → client.auth.signInAnonymously()).
-- =====================================================================

-- 1. On retire les politiques permissives créées par 01-schema.sql
do $$
declare t text;
begin
 foreach t in array array['schools','app_users','classes','subjects','students','grades','remarks','lessons','archives']
 loop
 execute format('drop policy if exists anon_all_%1$s on public.%1$I', t);
 end loop;
end $$;

-- 2. Uniquement les sessions authentifiées (y compris anonymes)
do $$
declare t text;
begin
 foreach t in array array['schools','app_users','classes','subjects','students','grades','remarks','lessons','archives']
 loop
 execute format('drop policy if exists auth_all_%1$s on public.%1$I', t);
 execute format('create policy auth_all_%1$s on public.%1$I for all to authenticated using (true) with check (true)', t);
 end loop;
end $$;

-- 3. On interdit totalement l'accès anonyme (clé anon seule)
revoke all on all tables in schema public from anon;

-- 4. Vérification
select 'Mode sécurisé activé (connexion anonyme requise)' as resultat;
