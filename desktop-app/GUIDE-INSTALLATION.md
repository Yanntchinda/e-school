# Installer e-School sur votre PC Windows

## LA METHODE LA PLUS SIMPLE — 2 minutes, rien a installer

L'installateur est deja construit et pret. **Aucun outil, aucun Node.js, aucune compilation.**

### Telecharger
https://github.com/Yanntchinda/e-school/releases/tag/v1.0.0

Cliquer sur **`e-School-Bulletins-1.0.0-Setup.exe`** (76 Mo).

### Installer
1. Double-cliquer sur le fichier telecharge
2. Si Windows affiche un avertissement bleu : **Informations complementaires** puis **Executer quand meme**
   (normal : l'installateur n'est pas signe numeriquement)
3. Choisir le dossier d'installation (ou garder celui propose)
4. **Installer**, puis **Terminer**

### Resultat
Une icone **e-School Bulletins** apparait :
- sur le **Bureau**
- dans le **menu Demarrer**

Double-clic : l'application s'ouvre dans sa propre fenetre, sans navigateur, comme Word ou Excel.

Details techniques du fichier :

| Propriete | Valeur |
|---|---|
| Nom | `e-School-Bulletins-1.0.0-Setup.exe` |
| Taille | 79 758 352 octets (76,1 Mo) |
| Type | application Windows x64 (NSIS) |
| Empreinte SHA-256 | `87c08b23d8e2694584d8e31663092a33ebc6d5599135e0dde2c1c86528e78a5b` |
| Systeme | Windows 10 et 11, 64 bits |
| Internet | inutile apres installation |

---

## Ou sont mes donnees

```
%APPDATA%\e-School Gestion Bulletins
```

Le menu **Aide → Ou sont mes donnees ?** ouvre ce dossier directement.
Les donnees sont conservees meme si vous desinstallez le programme.

Sauvegarde : menu **Fichier → Exporter une sauvegarde** (Ctrl+S).

---

## Transferer mes donnees actuelles

Le logiciel enregistre tout dans le navigateur ou l'application, jamais dans le fichier HTML.
Passer d'une version a l'autre ne transfere rien automatiquement.

1. **Ancienne version** → menu **Parametres** → **Exporter une sauvegarde complete** → fichier `.json`
2. **Nouvelle version** → ecran de connexion → **Restaurer une sauvegarde existante** → choisir le `.json`
3. Verifier le nombre de classes et d'eleves

A faire tant que l'ancienne version est encore accessible.

---

## Comment cet installateur a ete fabrique

Il est compile automatiquement par **GitHub Actions** sur un serveur Windows officiel,
a partir du dossier `desktop-app` de ce depot. Aucun fichier binaire n'est stocke dans le code source :
l'executable est produit a chaque publication.

Configuration du workflow : `.github/workflows/build-windows.yml`

| Element | Valeur |
|---|---|
| Declencheur | modification du dossier `desktop-app` ou lancement manuel |
| Machine | `windows-latest` |
| Node.js | 20 |
| Commande | `npm run build:win -- --publish never` |
| Resultat | artéfact `installateur-windows` (90 jours) + Release `v1.0.0` |

---

## Reconstruire une nouvelle version (pour plus tard)

### Methode automatique — recommandee

1. Modifier le logiciel dans `e-school/e-school/index.html`
2. Copier dans le dossier de l'application :
   ```bat
   cd desktop-app
   METTRE-A-JOUR-L-APP.bat
   ```
   (ou manuellement : copier `e-school/e-school/index.html` vers `desktop-app/app/index.html`)
3. Changer le numero de version dans `desktop-app/package.json`
4. Envoyer sur GitHub (commit + push)
5. GitHub recompile automatiquement l'installateur
6. Il apparait dans **Releases** — il ne reste qu'a le telecharger

### Methode manuelle, sur votre PC

Si vous preferez compiler vous-meme :

```bat
:: 1. Installer Node.js LTS depuis https://nodejs.org puis redemarrer le PC
cd desktop-app
CONSTRUIRE-L-INSTALLEUR.bat
```

L'installateur se trouve alors dans `dist\installers\`.
Il faut Node.js (gratuit) et une connexion internet la premiere fois.

---

## Autres facons d'utiliser le logiciel

| Methode | Comment | Avantage |
|---|---|---|
| Version portable | dossier `version-portable` → `INSTALLER-SUR-LE-BUREAU.bat` | icone sur le Bureau en 10 s, sans rien installer |
| Fichier unique | double-clic sur `version-portable/e-school.html` | zero installation |
| Application web | ouvrir le lien de l'apercu | accessible depuis n'importe quel appareil |

---

## Depannage

| Symptome | Cause | Solution |
|---|---|---|
| Windows bloque le telechargement | Edge verifie les fichiers peu connus | **Conserver** / **Informations complementaires** |
| Windows bloque l'installateur | Non signe numeriquement | **Executer quand meme** |
| Fenetre blanche au lancement | `app/index.html` absent de l'installation | Reinstaller avec le dernier installateur |
| L'imprimante n'apparait pas | Pilote absent | Installer l'imprimante dans Windows d'abord |
| Donnees perdues apres reinstallation | Dossier `%APPDATA%` efface | Restaurer depuis une sauvegarde `.json` |

---

## Verifications effectuees

| Controle | Etat |
|---|---|
| Workflow GitHub Actions | terminee avec succes |
| Installateur produit | 79 758 352 octets |
| Acces public sans authentification | oui (HTTP 302 vers le fichier) |
| `app/index.html` inclus | oui, 525 115 octets, derniere version |
| Titre de la page dans l'app | `Gestion scolaire` (puis le nom reel de l'etablissement) |
| Impression sans en-tete navigateur | oui (`@page margin: 0`) |
| Emojis | 0 |
| `main.js` | syntaxe valide |
| `app/icon.ico` | 6 tailles (16 a 256 px) |
