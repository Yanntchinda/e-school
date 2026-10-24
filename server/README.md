# Base de données partagée e-school

Deux façons de synchroniser les postes de l'établissement, **au choix** :

| Solution | Ce qu'il faut | Où vont les données |
|---|---|---|
| **Serveur autonome** (fourni ici) | un ordinateur avec Python 3 | un fichier `ecole.db` chez vous |
| **Supabase** (facultatif) | un compte Supabase gratuit | chez Supabase |

Le serveur autonome ne dépend d'aucun service extérieur : pas de compte, pas
d'abonnement, pas d'internet obligatoire si les postes sont sur le même réseau.

---

## 1. Serveur autonome (SQLite)

### Démarrer

```bash
python3 server/e-school-server.py
```

Le serveur écoute sur le port **8090** et écrit la base dans `server/ecole.db`.
Aucune bibliothèque à installer : Python 3 et son module `sqlite3` suffisent.

Options :

```bash
--port 8090              # changer le port
--db /chemin/ecole.db    # choisir l'emplacement de la base
--token secret           # exiger un jeton d'accès (recommandé hors du réseau local)
--host 0.0.0.0           # interface d'écoute (127.0.0.1 pour rester en local)
```

Les mêmes réglages existent en variables d'environnement :
`ESCHOOL_DB_PORT`, `ESCHOOL_DB`, `ESCHOOL_TOKEN`.

### Brancher l'application

1. Ouvrir l'application, se connecter comme **administrateur**.
2. **Paramètres → Base de données partagée**.
3. Choisir « **Mon serveur e-school** ».
4. Adresse : `http://adresse-du-serveur:8090`
   (sur le même ordinateur : `http://localhost:8090`).
5. Jeton : seulement si le serveur a été démarré avec `--token`.
6. Code école : un mot simple, identique sur tous les postes (ex. `st-michel`).
7. Cliquer **Connecter**.

À partir de là, **plus besoin de cliquer** : chaque modification (note,
versement, élève, classe, logo, archivage) est enregistrée localement puis
envoyée au serveur dans les secondes qui suivent. Les autres postes connectés
récupèrent les changements automatiquement.

> Une saisie en cours d'envoi n'est jamais écrasée par une récupération
> automatique : l'application attend que l'écriture locale soit partie.

### Ce qui est synchronisé

Élèves, classes, matières, notes, appréciations, leçons faites, utilisateurs,
**finances** (montant à payer et versements), **élèves archivés**, **sessions
clôturées** et le **logo** de l'établissement.

### Vérifier que ça marche

```bash
curl http://localhost:8090/health
```

```json
{"ok": true, "schools": 1, "rows": 3378}
```

### Lire les données en SQL

Le fichier `.db` s'ouvre avec n'importe quel outil SQLite
(DB Browser for SQLite, `sqlite3` en ligne de commande). Des vues sont prêtes :

| Vue | Contenu |
|---|---|
| `v_students` | nom, matricule, sexe, parent, téléphone |
| `v_classes` | classes |
| `v_grades` | notes par élève et par matière |
| `v_finance` | montant dû, nombre de versements, total versé |

```sql
sqlite3 server/ecole.db \
  "select name, matricule, parent from v_students where class_id = 'cl-6a';"
```

### Sauvegarder

Il suffit de **copier le fichier `.db`** (à faire serveur arrêté, ou avec
`sqlite3 ecole.db ".backup sauvegarde.db"` à chaud). Programmez une copie
quotidienne vers une clé USB ou un disque réseau.

### Mettre le serveur sur internet

Placez-le derrière Nginx ou Caddy avec un certificat HTTPS, et démarrez-le
avec `--token` :

```bash
python3 server/e-school-server.py --host 127.0.0.1 --token "$(openssl rand -hex 16)"
```

L'application envoie le jeton dans l'en-tête `Authorization: Bearer …`.

---

## 2. Supabase (facultatif)

1. Créer un projet sur [supabase.com](https://supabase.com).
2. Ouvrir **SQL Editor** et exécuter le contenu de
   [`../supabase/01-schema.sql`](../supabase/01-schema.sql).
3. Dans l'application : **Paramètres → Base de données partagée →
   Supabase**, puis renseigner l'URL du projet, la clé publique
   (`anon key`) et le code école.

---

## 3. Contrat technique

Les deux solutions exposent les mêmes deux opérations ; n'importe quel autre
serveur (PostgreSQL, MySQL, PHP…) peut les mettre en œuvre.

```http
POST /pull
{"school": "st-michel"}

→ {"school": "...", "users": [...], "classes": [...], "subjects": [...],
   "students": [...], "grades": [...], "remarks": [...], "lessons": [...],
   "finance": [...], "archived": [...], "sessions": [...], "server_time": "..."}
```

```http
POST /push
{"school": "st-michel",
 "payload": {"school": {...}, "students": [...], "finance": [...],
             "deleted": {"students": ["id1"], "finance": ["id2"]}}}

→ {"ok": true, "rows": 12}
```

- `finance` : un enregistrement par élève — `{id, fee, pays:[…]}`.
- `archived` : élève archivé — `{id, at, by, year, class_id, class_name, data, snapshot}`.
- `sessions` : année clôturée — `{id, year, closed_at, payload}`.
- En-tête `Authorization: Bearer <jeton>` si le serveur en exige un.

---

## 4. Mode local (sans base partagée)

Si aucun serveur n'est configuré, l'application fonctionne normalement et
enregistre tout dans le navigateur du poste. **Paramètres → Base de données
partagée → Aucune** revient à ce mode ; les données déjà synchronisées
restent sur le poste.
