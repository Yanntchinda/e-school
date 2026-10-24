# e-School — Application de bureau Windows

## Telecharger et installer (le plus simple)

https://github.com/Yanntchinda/e-school/releases/tag/v1.0.0

Deux fichiers, au choix :

| Fichier | Usage |
|---|---|
| `e-School-Bulletins-1.0.0-Setup.exe` | installateur : icone sur le Bureau et dans le menu Demarrer |
| `e-School-Bulletins-1.0.0-Portable.exe` | un seul fichier, **sans installation** (cle USB, poste partage) |

Double-cliquer, puis suivre l'assistant pour la version Setup.
Aucun outil a installer. Guide complet : [GUIDE-INSTALLATION.md](GUIDE-INSTALLATION.md).

## Contenu du dossier

```
desktop-app/
  main.js                       fenetre et menus de l'application
  package.json                  configuration et cibles de compilation
  CONSTRUIRE-L-INSTALLEUR.bat   compilation locale en un double-clic (Windows)
                                (produit Setup.exe et Portable.exe)
  METTRE-A-JOUR-L-APP.bat       recopie le logiciel web dans app/
  GUIDE-INSTALLATION.md         guide detaille
  app/
    index.html                  le logiciel complet (autonome)
    icon.png                    1024 x 1024
    icon.ico                    icone Windows, 6 tailles
```

## Reconstruire l'installateur

Automatiquement : envoyer les modifications sur GitHub, la compilation se fait toute seule
(`.github/workflows/build-windows.yml`), puis le fichier apparait dans **Releases**.

Sur votre PC : installer Node.js LTS, puis double-cliquer sur `CONSTRUIRE-L-INSTALLEUR.bat`.

## Donnees

Enregistrees dans `%APPDATA%\e-School Gestion Bulletins`.
Menu **Aide -> Ou sont mes donnees ?** pour les retrouver.
Sauvegarde : menu **Fichier -> Exporter une sauvegarde** (Ctrl+S).
Aucune connexion internet n'est necessaire a l'utilisation.
