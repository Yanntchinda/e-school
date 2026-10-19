# Installer e-School sur votre ordinateur

Trois méthodes, de la plus « logiciel » à la plus simple. Choisissez la **méthode A** si vous voulez une vraie application installée avec une icône.

---

## Méthode A — Installateur Windows (.exe) : la vraie application

Résultat : une icône sur le bureau, un programme dans le menu Démarrer, qui s'ouvre comme Word ou Excel, sans navigateur visible.

### Ce qu'il faut, une seule fois
1. **Node.js** — https://nodejs.org → bouton **LTS** → installation en laissant tout par défaut.
   Vérification : ouvrir `cmd` et taper `node -v` → doit afficher `v20.x` ou `v22.x`.
2. Une **connexion internet** pour la première compilation (téléchargement d'Electron, ~150 Mo).

### Construire l'installateur
1. Copier le dossier `desktop-app` sur votre PC (clé USB, ou téléchargement depuis GitHub).
2. Double-cliquer sur **`CONSTRUIRE-L-INSTALLEUR.bat`**.
3. Attendre. Le script installe les composants puis fabrique l'installateur.
   Durée totale : **5 à 12 minutes** la première fois.
4. À la fin, le dossier `dist\installers` s'ouvre avec un fichier du type :
   ```
   e-School Gestion Bulletins Setup 1.0.0.exe
   ```
5. Double-cliquer sur ce fichier → installation → icône **e-School Bulletins**.

### Si Windows affiche un avertissement bleu
L'installateur n'est pas signé numériquement (un certificat coûte 200 à 400 €/an).
Cliquer sur **Informations complémentaires** → **Exécuter quand même**. C'est normal et sans danger.

### Configuration utilisée
| Paramètre | Valeur |
|---|---|
| Nom du programme | e-School Gestion Bulletins |
| Version | 1.0.0 |
| Plateforme | Windows 10 / 11 (64 bits) |
| Icône | `app/icon.ico` (6 tailles : 16 → 256 px) |
| Raccourcis | Bureau + menu Démarrer |
| Dossier d'installation | modifiable pendant l'installation |
| Désinstallation | Panneau de configuration → Programmes |

### Où sont mes données
Dans `%APPDATA%\e-School Gestion Bulletins` — conservées même après désinstallation.
Menu **Aide → Où sont mes données ?** ouvre le dossier directement.

---

## Méthode B — Version portable (aucune installation)

Dossier `version-portable/` : à copier sur une clé USB, fonctionne sur n'importe quel PC Windows.

1. Double-cliquer sur **`LANCER-E-SCHOOL.bat`**
2. L'application s'ouvre dans le navigateur
3. Travailler normalement
4. **`ARRETER-E-SCHOOL.bat`** pour fermer

Nécessite Python (présent sur la plupart des PC ; sinon https://www.python.org → cocher **Add Python to PATH**).

---

## Méthode C — Le plus simple : double-clic sur le fichier HTML

Le fichier `version-portable/e-school.html` contient **tout** le logiciel (code, styles, photo de connexion).
Un double-clic l'ouvre dans le navigateur par défaut. Aucune installation, aucun outil.

Limite : les données restent liées à ce navigateur et au chemin du fichier. Si vous déplacez le fichier, utilisez **Paramètres → Exporter une sauvegarde** pour les transférer.

---

## Très important : transférer vos données existantes

Le logiciel stocke ses données **dans le navigateur ou l'application**, pas dans le fichier HTML.
Passer d'une méthode à une autre **ne transfère rien automatiquement**.

Procédure, dans les deux sens :

1. **Ancienne version** → écran **Paramètres** → **Exporter une sauvegarde complète** → un fichier `.json` est téléchargé
2. **Nouvelle version** → écran de connexion → **Restaurer une sauvegarde existante** → choisir le `.json`
3. Vérifier : nombre de classes, d'élèves, de notes

À faire tant que l'ancienne version est encore accessible.

---

## Compilation en ligne de commande (sans le .bat)

```bash
cd desktop-app
npm install
npm run build:win      # Windows  -> dist/installers/*.exe
npm run build:linux    # Linux    -> AppImage + .deb
npm run build:mac      # macOS    -> .dmg  (doit être lancé depuis un Mac)
```

Lancer l'application sans la compiler :
```bash
npm start
```

Mettre à jour l'application après une modification de `e-school/e-school/index.html` :
```bash
copy ..\e-school\e-school\index.html app\index.html
```

---

## En cas de problème

| Symptôme | Cause | Solution |
|---|---|---|
| `'node' n'est pas reconnu` | Node.js absent ou PATH non mis à jour | Réinstaller Node.js, redémarrer le PC |
| Blocage à `npm install` | Antivirus ou proxy | Désactiver temporairement l'antivirus, relancer |
| `ERR_ELECTRON_BUILDER_CANNOT_EXECUTE` | Chemin avec accents ou espaces | Déplacer le dossier dans `C:\e-school\` |
| L'installateur ne se crée pas | Droits insuffisants | Clic droit sur le .bat → **Exécuter en tant qu'administrateur** |
| Écran blanc au lancement | `app/index.html` manquant | Vérifier qu'il existe et fait ~515 Ko |
| L'imprimante n'est pas proposée | Pilote absent | Installer l'imprimante dans Windows d'abord |

---

## Vérifications déjà effectuées sur ce dossier

| Contrôle | État |
|---|---|
| `main.js` — syntaxe | valide |
| `app/index.html` | présent (526 Ko) |
| `app/icon.png` | présent (1024 × 1024) |
| `app/icon.ico` | généré (16/32/48/64/128/256 px) |
| `preload.js` fantôme dans `package.json` | retiré |
| Menu **Exporter une sauvegarde** | branché sur l'action réelle de l'application |
| Menu **Imprimer** | branché sur l'impression de l'application |
| Lien externe cliqué | ouvert dans le navigateur, pas dans l'app |
| Instance multiple | bloquée (une seule fenêtre) |
