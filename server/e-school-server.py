#!/usr/bin/env python3
"""Base de données de l'application e-school — serveur autonome.

Sert les deux opérations de synchronisation de l'application :
    POST /pull   {"school":"..."}                 -> instantané complet
    POST /push   {"school":"...","payload":{...}} -> écriture (delta)

Aucune dépendance : Python 3 et son module sqlite3 suffisent. Les données
vivent dans un fichier .db que vous pouvez copier, sauvegarder ou ouvrir avec
n'importe quel outil SQLite.

    python3 server/e-school-server.py                # port 8090, ecole.db
    python3 server/e-school-server.py --port 8090 --db /chemin/ecole.db
    python3 server/e-school-server.py --token secret  # accès protégé

Derrière un nom de domaine, placez-le derrière Nginx/Caddy en HTTPS.
"""
import argparse
import json
import os
import sqlite3
import threading
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse

KINDS = ('users', 'classes', 'subjects', 'students', 'grades', 'remarks',
         'lessons', 'finance', 'archived', 'sessions')

SCHEMA = """
create table if not exists schools (
  id         text primary key,
  json       text not null,
  updated_at text not null
);

/* Une ligne JSON par entité. Le modèle accepte toutes les évolutions de
   l'application sans migration : on ajoute des champs, pas des colonnes. */
create table if not exists records (
  school_id  text not null,
  kind       text not null,
  id         text not null,
  json       text not null,
  updated_at text not null,
  primary key (school_id, kind, id)
);
create index if not exists idx_records_kind on records (school_id, kind);

/* Vues pratiques : les données restent lisibles en SQL classique. */
create view if not exists v_classes as
  select school_id, id, json_extract(json,'$.name') as name
  from records where kind = 'classes';

create view if not exists v_students as
  select school_id, id,
         json_extract(json,'$.class_id') as class_id,
         json_extract(json,'$.name')     as name,
         json_extract(json,'$.mat')      as matricule,
         json_extract(json,'$.sex')      as sexe,
         json_extract(json,'$.parent')   as parent,
         json_extract(json,'$.parent_phone') as telephone_parent
  from records where kind = 'students';

create view if not exists v_grades as
  select school_id, id, json_extract(json,'$.student_id') as student_id,
         json_extract(json,'$.subject_id') as subject_id,
         json_extract(json,'$.seqs') as sequences
  from records where kind = 'grades';

create view if not exists v_finance as
  select school_id, id as student_id,
         json_extract(json,'$.fee') as montant_a_payer,
         json_array_length(json_extract(json,'$.pays')) as nb_versements,
         json_extract(json,'$.pays') as versements
  from records where kind = 'finance';
"""


def now_iso():
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


class Store:
    """Accès SQLite, sérialisé par un verrou (le serveur est multi-thread)."""

    def __init__(self, path):
        self.path = path
        self.lock = threading.Lock()
        self.conn = sqlite3.connect(path, check_same_thread=False)
        self.conn.row_factory = sqlite3.Row
        self.conn.executescript(SCHEMA)
        self.conn.commit()

    # ----- lecture -----
    def pull(self, school_id):
        with self.lock:
            row = self.conn.execute('select json from schools where id=?', (school_id,)).fetchone()
            school = json.loads(row['json']) if row else {}
            out = {'school': school}
            for kind in KINDS:
                rows = self.conn.execute(
                    'select json from records where school_id=? and kind=? order by rowid',
                    (school_id, kind)
                ).fetchall()
                out[kind] = [json.loads(r['json']) for r in rows]
            out['server_time'] = now_iso()
            return out

    # ----- écriture -----
    def push(self, school_id, payload):
        stamp = now_iso()
        written = 0
        with self.lock:
            cur = self.conn.cursor()
            # 1) établissement
            school = payload.get('school')
            if isinstance(school, dict):
                row = cur.execute('select json from schools where id=?', (school_id,)).fetchone()
                merged = json.loads(row['json']) if row else {}
                for k, v in school.items():
                    if v not in (None, ''):
                        merged[k] = v
                cur.execute('insert into schools (id,json,updated_at) values (?,?,?) '
                            'on conflict(id) do update set json=excluded.json, updated_at=excluded.updated_at',
                            (school_id, json.dumps(merged, ensure_ascii=False), stamp))
                written += 1

            # 2) lignes modifiées
            for kind in KINDS:
                rows = payload.get(kind)
                if not isinstance(rows, list):
                    continue
                for item in rows:
                    if not isinstance(item, dict) or not item.get('id'):
                        continue
                    cur.execute(
                        'insert into records (school_id,kind,id,json,updated_at) values (?,?,?,?,?) '
                        'on conflict(school_id,kind,id) do update set '
                        'json=excluded.json, updated_at=excluded.updated_at',
                        (school_id, kind, str(item['id']),
                         json.dumps(item, ensure_ascii=False), stamp))
                    written += 1

            # 3) suppressions
            deleted = payload.get('deleted')
            if isinstance(deleted, dict):
                for kind, ids in deleted.items():
                    if kind not in KINDS or not isinstance(ids, list):
                        continue
                    for rid in ids:
                        cur.execute('delete from records where school_id=? and kind=? and id=?',
                                    (school_id, kind, str(rid)))
                        written += 1
            self.conn.commit()
        return written

    def stats(self):
        with self.lock:
            rows = self.conn.execute(
                'select kind, count(*) as n from records group by kind order by kind').fetchall()
            return {'records': {r['kind']: r['n'] for r in rows},
                    'schools': self.conn.execute('select count(*) as n from schools').fetchone()['n']}


class Handler(BaseHTTPRequestHandler):
    store = None
    token = ''

    # ----- utilitaires -----
    def _cors(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')

    def _json(self, code, obj):
        body = json.dumps(obj, ensure_ascii=False).encode('utf-8')
        self.send_response(code)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self._cors()
        self.end_headers()
        self.wfile.write(body)

    def _authorized(self):
        if not self.token:
            return True
        hdr = self.headers.get('Authorization', '')
        if hdr.startswith('Bearer ') and hdr[7:].strip() == self.token:
            return True
        q = urlparse(self.path).query
        return ('token=' + self.token) in q

    def _body(self):
        length = int(self.headers.get('Content-Length') or 0)
        if not length:
            return {}
        return json.loads(self.rfile.read(length).decode('utf-8'))

    # ----- routes -----
    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self):
        path = urlparse(self.path).path.rstrip('/') or '/'
        if path in ('/', '/health'):
            return self._json(200, {'ok': True, 'service': 'e-school', 'time': now_iso(),
                                    'stats': self.store.stats()})
        return self._json(404, {'ok': False, 'error': 'route inconnue'})

    def do_POST(self):
        path = urlparse(self.path).path.rstrip('/')
        if path not in ('/pull', '/push'):
            return self._json(404, {'ok': False, 'error': 'route inconnue'})
        if not self._authorized():
            return self._json(401, {'ok': False, 'error': 'jeton invalide'})
        try:
            data = self._body()
        except Exception as e:
            return self._json(400, {'ok': False, 'error': 'JSON invalide : %s' % e})

        school = str(data.get('school') or '').strip()
        if not school:
            return self._json(400, {'ok': False, 'error': 'code d’école manquant'})

        try:
            if path == '/pull':
                return self._json(200, self.store.pull(school))
            n = self.store.push(school, data.get('payload') or {})
            return self._json(200, {'ok': True, 'rows': n})
        except Exception as e:  # pragma: no cover - garde-fou
            return self._json(500, {'ok': False, 'error': str(e)})

    def log_message(self, fmt, *args):
        pass


def main():
    ap = argparse.ArgumentParser(description="Base de données e-school (SQLite)")
    ap.add_argument('--port', type=int, default=int(os.environ.get('ESCHOOL_DB_PORT', '8090')))
    ap.add_argument('--db', default=os.environ.get('ESCHOOL_DB', os.path.join(os.path.dirname(os.path.abspath(__file__)), 'ecole.db')))
    ap.add_argument('--token', default=os.environ.get('ESCHOOL_TOKEN', ''), help='jeton partagé (facultatif)')
    ap.add_argument('--host', default='0.0.0.0')
    args = ap.parse_args()

    Handler.store = Store(args.db)
    Handler.token = args.token.strip()
    srv = ThreadingHTTPServer((args.host, args.port), Handler)
    print(f'e-school base : http://{args.host}:{args.port}/  ·  base {os.path.abspath(args.db)}', flush=True)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == '__main__':
    main()
