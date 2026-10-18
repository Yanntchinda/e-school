# ☁️ Mise en production — Supabase

Guide complet pour brancher l'application sur une base partagée : **ce que saisit un professeur arrive immédiatement chez l'administrateur**.

---

## 0. Pourquoi les statistiques restaient à 0 %

L'application enregistrait tout dans le **navigateur de chaque ordinateur** (`localStorage`).
Un professeur qui saisissait ses leçons les écrivait dans **son** navigateur ; l'administrateur, sur un autre poste, ne voyait donc rien.

La synchronisation Supabase corrige exactement ce point : une seule base, plusieurs postes.

---

## 1. Créer le projet

1. https://supabase.com → **New project**
2. Nom : `e-school` · Mot de passe base : *notez-le* · Région : `Europe` (ou la plus proche)
3. Attendre la fin de la création (~2 min)

## 2. Créer les tables (une seule fois)

1. Menu **SQL Editor** → **New query**
2. Copier **tout** le contenu de `supabase/01-schema.sql`
3. **Run** (Ctrl+Entrée)

Résultat attendu en bas de l'éditeur :

```
Schéma e-school installé ✅   tables_creees: 9   fonctions_creees: 2
```

> Le script est idempotent : vous pouvez le relancer sans perdre de données.

## 3. Récupérer les deux clés

Menu **Project Settings → API** :

| Élément | Où | Usage |
|---|---|---|
| **Project URL** | ex. `https://abcdefgh.supabase.co` | champ « URL du projet » |
| **anon public** | longue chaîne `eyJhbGciOi…` | champ « Clé anon public » |

⚠️ Ne **jamais** utiliser la clé `service_role` dans l'application : elle contourne toute la sécurité.

## 4. Configurer l'application

### Sur le poste administrateur

1. Se connecter en **admin**
2. Menu **Paramètres** → panneau **☁️ Synchronisation Supabase**
3. Renseigner **URL** + **clé anon**
4. Laisser le **code de l'école** se générer (ou le choisir, ex. `sch-ming-douala`)
5. Cliquer **Enregistrer et connecter**
   → l'application teste la connexion, puis **envoie automatiquement les données locales** (classes, élèves, notes, professeurs)
6. Relever le **code de l'école** : il doit être identique partout

### Sur chaque poste professeur

1. Ouvrir la même application (même URL / fichier portable)
2. Paramètres → même **URL**, même **clé anon**, même **code d'école**
3. **Enregistrer et connecter**
4. Se connecter avec son identifiant (`pmballa`, etc.)

> Le premier lancement d'un poste neuf télécharge les données depuis le cloud : les comptes créés par l'admin fonctionnent directement.

## 5. Vérifier que tout remonte

| Test | Attendu |
|---|---|
| Professeur saisit leçons prévues/faites | La barre passe au vert/orange/rouge chez lui |
| Admin → 📚 Leçons | Même valeur, **sans recharger** (temps réel + rafraîchissement 20 s) |
| Admin → Statistiques d'une classe | Progression par matière + TOTAL GÉNÉRAL à jour |
| Badge en haut à droite | `☁️ En ligne` |
| Coupure Internet | `☁️ Hors ligne`, la saisie continue et repart seule au retour |

---

## 6. Structure de la base

| Table | Contenu | Clé |
|---|---|---|
| `schools` | établissement, année, en-tête des bulletins | `id` (code école) |
| `app_users` | comptes admin + professeurs (identifiant, sel + hash) | `id` |
| `classes` | classes, prof. principal, verrous de trimestre | `id` |
| `subjects` | matières, coefficients, professeur affecté | `id` |
| `students` | élèves, matricule permanent, tag NA/Ancien | `id` |
| `grades` | notes, 5 séquences par élève × matière | `student:subject` |
| `remarks` | appréciations par trimestre | `student:tN` |
| `lessons` | leçons prévues / faites par matière | `class:subject` |
| `archives` | années scolaires clôturées | `id` |

Deux fonctions SQL font tout le travail :

- `app_pull(p_school)` → renvoie **toutes** les données de l'école en un objet JSON
- `app_push(p_school, p_payload)` → insère / met à jour **uniquement les lignes modifiées**, puis applique les suppressions

L'application calcule le delta : elle n'envoie que ce qui a changé (une note modifiée = ~100 octets, pas 400 Ko).

---

## 7. Sécurité

Par défaut, `01-schema.sql` autorise la clé `anon` (l'application gère elle-même identifiant + mot de passe).
C'est acceptable pour un déploiement **privé** (URL non diffusée).

Pour un déploiement **public**, exécuter `02-securite-renforcee.sql` :

1. Supabase → **Authentication → Sign In / Providers** → *Allow anonymous sign-ins* : **ON**
2. SQL Editor → exécuter `02-securite-renforcee.sql`
3. Les tables ne sont alors plus lisibles avec la seule clé `anon` : une session est obligatoire (l'application la crée automatiquement)

Pour aller plus loin (comptes nominatifs Supabase Auth + politiques par professeur), voir la section « Durcissement » en fin de document.

---

## 8. Sauvegardes

- **Automatiques** : Supabase → Database → Backups (quotidiennes sur les offres payantes)
- **Manuelles** : Paramètres → *Exporter une sauvegarde complète* (fichier JSON)
- **Export SQL** : SQL Editor →
  ```sql
  select jsonb_pretty(app_pull('VOTRE-CODE-ECOLE'));
  ```

---

## 9. Dépannage

| Symptôme | Cause probable | Solution |
|---|---|---|
| « Connexion impossible » | URL ou clé erronée | Recopier depuis Project Settings → API |
| `function app_pull does not exist` | Script SQL non exécuté | Relancer `01-schema.sql` |
| `permission denied for table …` | Mode sécurisé sans connexion anonyme | Activer *Allow anonymous sign-ins* |
| Les profs voient 0 classe | Code d'école différent de l'admin | Même code partout |
| Les modifications n'arrivent pas | Professeur hors ligne | Le badge reste `Hors ligne` : ça repart au retour du réseau |
| `payload too large` | Envoi de trop de notes d'un coup | Déjà découpé par lots de 600 ; relancer la synchro |

---

## 10. Durcissement (plus tard)

Pour que chaque professeur ne puisse lire **que** ses propres matières au niveau base :

1. Passer les comptes dans **Supabase Auth** (email = `identifiant@votre-ecole.local`)
2. Ajouter une colonne `auth_id uuid` dans `app_users`
3. Remplacer les politiques par :
   ```sql
   create policy prof_lecture on public.lessons for select to authenticated
   using (exists (
     select 1 from public.subjects s
     join public.app_users u on u.id = s.teacher_id
     where s.id = lessons.subject_id and u.auth_id = auth.uid()
   ));
   ```
4. Même principe pour `grades`, puis laisser les politiques admin complètes.

Le mode actuel (clé anon + code école) est le bon compromis pour démarrer rapidement sans casser l'existant.
