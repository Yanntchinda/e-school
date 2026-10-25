#!/usr/bin/env python3
"""Serveur d'aperçu local de l'application GestSchool (port 8082).

L'application tient dans un seul fichier : e-school/e-school/index.html
Ce serveur le sert à la racine, et retombe sur le dossier parent pour les pages
annexes (apercu-bulletin-visuel.html, bundles, etc.).

Usage :
    python3 tools/preview-server.py                # http://localhost:8082/
    python3 tools/preview-server.py --port 9000
    ESCHOOL_ROOT=/autre/dossier python3 tools/preview-server.py

Sur une machine distante (codespace, conteneur), le serveur écoute sur toutes
les interfaces : l'aperçu est joignable depuis l'extérieur du conteneur.
Aucune dépendance : bibliothèque standard uniquement.
"""
import argparse
import functools
import http.server
import os
import socketserver

# Racine du dépôt, quel que soit le dossier d'où la commande est lancée.
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_PORT = int(os.environ.get('ESCHOOL_PORT', '8082'))


def find_app_root():
    """Dossier qui contient index.html (l'application est un fichier unique).

    On essaie les emplacements connus du dépôt, du plus profond au plus large,
    pour rester juste même si l'arborescence bouge.
    """
    candidates = [
        os.path.join(REPO, 'e-school', 'e-school'),
        os.path.join(REPO, 'e-school'),
        os.path.join(REPO, 'desktop-app', 'app'),
        REPO,
    ]
    for path in candidates:
        if os.path.isfile(os.path.join(path, 'index.html')):
            return path
    return candidates[0]


DEFAULT_ROOT = find_app_root()


class Handler(http.server.SimpleHTTPRequestHandler):
    """Sert la racine de l'application, puis le dossier parent en secours."""

    def translate_path(self, path):
        found = super().translate_path(path)
        if not os.path.exists(found):
            parent = os.path.dirname(self.directory)
            alt = os.path.join(parent, os.path.relpath(found, self.directory))
            if os.path.exists(alt):
                return alt
        return found

    # Jamais de cache : l'aperçu montre toujours la dernière version du fichier.
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

    def log_message(self, fmt, *args):
        pass


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


def main():
    ap = argparse.ArgumentParser(description="Aperçu local de l'application GestSchool")
    ap.add_argument('--port', type=int, default=DEFAULT_PORT)
    ap.add_argument('--root', default=os.environ.get('ESCHOOL_ROOT', DEFAULT_ROOT))
    args = ap.parse_args()

    root = os.path.abspath(args.root)
    index = os.path.join(root, 'index.html')
    if not os.path.isfile(index):
        raise SystemExit(f"index.html introuvable dans {root}")

    handler = functools.partial(Handler, directory=root)
    with Server(('0.0.0.0', args.port), handler) as httpd:
        print(f'GestSchool preview: http://0.0.0.0:{args.port}/ -> {index}', flush=True)
        httpd.serve_forever()


if __name__ == '__main__':
    main()
