# e-School — Application de bureau

Application installable pour Windows, Mac et Linux, basée sur la version web du logiciel.

## Guide complet

**Lisez [GUIDE-INSTALLATION.md](GUIDE-INSTALLATION.md)** — il contient les trois méthodes d'installation,
la procédure de compilation, le transfert des données et les solutions aux problèmes courants.

## Démarrage rapide (Windows)

1. Installer **Node.js LTS** : https://nodejs.org
2. Double-cliquer sur **`CONSTRUIRE-L-INSTALLEUR.bat`**
3. L'installateur apparaît dans `dist\installers\`
4. Le lancer, puis ouvrir **e-School Bulletins** depuis le bureau

## Commandes

```bash
npm install          # composants (une seule fois)
npm start            # lancer sans compiler
npm run build:win    # installateur Windows  -> dist/installers/*.exe
npm run build:linux  # AppImage + .deb
npm run build:mac    # .dmg (depuis un Mac)
```

## Structure

```
desktop-app/
├─ main.js                       fenêtre + menus de l'application
├─ package.json                  configuration et cibles de compilation
├─ CONSTRUIRE-L-INSTALLEUR.bat   compilation en un double-clic (Windows)
├─ METTRE-A-JOUR-L-APP.bat       recopie le logiciel web dans app/
├─ GUIDE-INSTALLATION.md         guide détaillé
└─ app/
   ├─ index.html                 le logiciel complet (autonome)
   ├─ icon.png                   1024 × 1024
   └─ icon.ico                   icône Windows 6 tailles
```

## Données

Enregistrées localement dans `%APPDATA%\e-School Gestion Bulletins`.
Aucune connexion internet n'est nécessaire à l'utilisation.
Sauvegarde : menu **Fichier → Exporter une sauvegarde** (Ctrl+S).

## Fonctionnalités

- Gestion des classes, élèves et enseignants
- Saisie des notes par trimestre et par professeur
- Bulletins imprimables sur une seule page A4
- Calcul des moyennes, rangs et mentions
- Passage à la nouvelle année scolaire avec répartition automatique
- Archivage des années précédentes en lecture seule
- Module Leçons avec statistiques par professeur
- Import / export des sauvegardes
