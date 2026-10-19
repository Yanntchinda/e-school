# Obtenir e-School en .exe sur votre Bureau (Windows)

Deux chemins. **Commencez par le 1**, il donne une vraie application installée.

---

# CHEMIN 1 — L'installateur .exe (recommandé)

Résultat : une icône **e-School Bulletins** sur le Bureau et dans le menu Démarrer,
qui s'ouvre dans sa propre fenêtre, sans navigateur, comme Word ou Excel.

## Étape 1 — Installer Node.js (une seule fois dans la vie du PC)

1. Aller sur **https://nodejs.org**
2. Cliquer sur le bouton vert **LTS**
3. Double-cliquer sur le fichier téléchargé, cliquer **Next** partout (tout est déjà bien réglé)
4. **Redémarrer l'ordinateur**

Vérification : appuyer sur `Windows + R`, taper `cmd`, valider, puis taper :

```
node -v
```

Doit afficher quelque chose comme `v22.14.0`.

> Si le message est *« 'node' n'est pas reconnu »* : Node.js n'est pas installé, ou l'ordinateur n'a pas été redémarré.

## Étape 2 — Récupérer le dossier du programme

Sur la page GitHub du projet :

1. Bouton vert **Code** → **Download ZIP**
2. Clic droit sur le fichier ZIP → **Extraire tout**
3. Aller dans le dossier extrait, puis dans **`desktop-app`**

## Étape 3 — Construire

Double-cliquer sur **`CONSTRUIRE-L-INSTALLEUR.bat`**

Le script enchaîne tout seul :

| Étape affichée | Durée | Ce qu'il fait |
|---|---|---|
| `[OK] Node.js v22 détecté` | instantané | vérifie l'outil |
| `[1/2] Téléchargement des composants` | **3 à 8 min** | télécharge Electron (~150 Mo) |
| `[2/2] Fabrication de l'installateur` | **2 à 5 min** | crée le .exe |

> L'écran peut rester figé plusieurs minutes pendant le téléchargement. **C'est normal**, ne fermez pas la fenêtre.

## Étape 4 — Installer

À la fin, le dossier `dist\installers` s'ouvre avec :

```
e-School-Bulletins-1.0.0-Setup.exe
```

Double-cliquer dessus → **Suivant → Installer → Terminer**.

L'icône **e-School Bulletins** apparaît sur le Bureau.

### L'avertissement bleu de Windows
L'installateur n'est pas signé numériquement (un certificat coûte 200 à 400 € par an).
Si Windows affiche *« Windows a protégé votre ordinateur »* :

> **Informations complémentaires** → **Exécuter quand même**

C'est sans danger : le fichier est fabriqué sur votre propre ordinateur.

---

# CHEMIN 2 — Icône sur le Bureau en 10 secondes (sans rien installer)

Si vous ne voulez pas installer Node.js, ou si le téléchargement échoue.

1. Ouvrir le dossier **`version-portable`**
2. Double-cliquer sur **`INSTALLER-SUR-LE-BUREAU.bat`**
3. Une icône **e-School Bulletins** apparaît sur le Bureau

L'application s'ouvre dans une fenêtre propre, sans barre d'adresse, avec l'icône du logiciel.
Utilise Chrome ou Edge, déjà présents sur tous les PC Windows.

Différence avec le CHEMIN 1 : ce n'est pas un vrai programme compilé, c'est le navigateur
en mode « application ». Le résultat visuel est très proche.

---

# IMPORTANT — à lire avant de changer de méthode : vos données

Le logiciel enregistre tout **dans le navigateur ou l'application**, jamais dans le fichier HTML.
Changer de méthode **ne transfère rien automatiquement**.

Procédure :

1. **Ancienne version** → menu **Paramètres** → **Exporter une sauvegarde complète**
   → un fichier `.json` est téléchargé
2. **Nouvelle version** → écran de connexion → **Restaurer une sauvegarde existante**
   → choisir le `.json`
3. Vérifier : nombre de classes, nombre d'élèves, notes

À faire **tant que l'ancienne version est encore accessible**.

## Où sont mes données dans la version .exe

```
%APPDATA%\e-School Gestion Bulletins
```

Accessible directement par le menu **Aide → Où sont mes données ?** de l'application.
Elles sont conservées même si vous désinstallez le programme.

---

# Mettre à jour l'application plus tard

Après une modification du logiciel :

```bat
cd desktop-app
METTRE-A-JOUR-L-APP.bat        rem copie le nouveau index.html
CONSTRUIRE-L-INSTALLEUR.bat    rem refabrique le .exe
```

Pour changer le numéro de version, modifier `"version": "1.0.0"` dans `package.json`.

---

# Dépannage

| Message | Cause | Solution |
|---|---|---|
| `'node' n'est pas reconnu` | Node.js absent | Installer Node.js LTS, redémarrer le PC |
| Blocage à `[1/2]` | Antivirus / pare-feu | Désactiver l'antivirus, relancer |
| `npm ERR!` avec un code réseau | Pas d'internet ou proxy | Vérifier la connexion, essayer un autre réseau |
| `ERR_ELECTRON_BUILDER` | Chemin avec accents ou espaces | Déplacer le dossier dans `C:\e-school\` |
| Le .exe ne se crée pas | Droits insuffisants | Clic droit sur le .bat → **Exécuter en tant qu'administrateur** |
| Fenêtre blanche au lancement | `app/index.html` manquant | Vérifier qu'il existe et pèse ~515 Ko |
| Windows bloque l'installateur | Non signé | **Informations complémentaires → Exécuter quand même** |
| L'imprimante n'apparaît pas | Pilote absent | Installer l'imprimante dans Windows d'abord |

---

# Vérifications déjà faites sur ce dossier

| Contrôle | État |
|---|---|
| `main.js` — syntaxe | valide |
| `app/index.html` | présent, 526 Ko |
| `app/icon.png` | 1024 × 1024 |
| `app/icon.ico` | 6 tailles : 16 / 32 / 48 / 64 / 128 / 256 px |
| `preload.js` fantôme dans `package.json` | retiré |
| Versions Electron / electron-builder | figées : 31.7.7 / 25.1.8 |
| Menu **Exporter une sauvegarde** | relié à la vraie action de l'application |
| Menu **Imprimer** | relié à l'impression des bulletins |
| Liens externes | ouverts dans le navigateur, pas dans l'app |
| Ouverture multiple | bloquée, une seule fenêtre |
| Scripts `.bat` | 100 % ASCII (aucun problème d'accents) |
| Emojis dans le dépôt | 0 |

> La compilation elle-même **ne peut pas être faite à distance** : elle doit tourner sur votre
> ordinateur Windows, car elle télécharge le moteur Electron et fabrique un exécutable Windows.
