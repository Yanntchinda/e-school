# Récupérer mes données (aucun code à écrire)

Vos données ne sont pas effacées par une mise à jour. Le logiciel ne les range
pas dans son dossier d'installation (remplacé à chaque version) mais dans un
dossier de données séparé, qui reste sur l'ordinateur :

| Où vous avez utilisé l'ancienne version | Où sont les données |
|---|---|
| Application installée (icône, menu Démarrer) | `%APPDATA%\e-School Gestion Bulletins` |
| Fichier `.html` ouvert en double-cliquant (Chrome, Edge, Brave) | dans le navigateur |
| Version actuelle | `%APPDATA%\GestSchool` |

---

## Méthode 1 — le menu du logiciel (le plus simple, rien à télécharger)

1. Ouvrez **GestSchool**.
2. Menu **Aide → Récupérer les données d’une ancienne version…**
3. Le logiciel affiche les dossiers de données trouvés (ancien nom, dossier
   actuel, navigateurs). Acceptez celui qui est proposé.
4. Il redémarre tout seul avec ces données.

Rien n'est supprimé : avant de copier, il met le dossier actuel de côté dans
`Documents\GestSchool-Sauvegardes\avant-recuperation-…`.

> Vous préférez les menus ? Cette option est aussi rappelée dans
> **Paramètres → Récupérer les données d’une ancienne version**.

## Méthode 2 — le programme de récupération (si le logiciel ne démarre pas)

1. **Fermez** GestSchool et tous les navigateurs.
2. Téléchargez
   [RECUPERER-MES-DONNEES.bat](https://github.com/Yanntchinda/e-school/releases/download/v1.0.0/RECUPERER-MES-DONNEES.bat)
3. Double-cliquez dessus. Si Windows affiche un avertissement :
   **Informations complémentaires → Exécuter quand même**.
4. Lisez le résumé à la fin, puis rouvrez GestSchool.

Il ne supprime rien et :

- cherche dans l'ancien dossier, le dossier actuel **et** Chrome / Edge / Brave ;
- copie tout ce qu'il trouve dans un dossier du Bureau
  (`GestSchool-recuperation-date`) ;
- **classe toutes les bases trouvées** de la plus complète à la plus vide : un
  ordinateur en contient souvent plusieurs (celle d'avant la mise à jour, et
  celle — vide — écrite après). Le programme écrit un fichier par base :
  `DONNEES-1_LA-PLUS-COMPLETE_…json`, `DONNEES-2_…json`, … ;
- **remet en place la base la plus complète** (et remplace le dossier actuel
  s'il ne contient aucune classe) ;
- retrouve les anciennes sauvegardes `.json` (Bureau, Téléchargements,
  Documents, OneDrive) et les copie au même endroit ;
- dépose un `LISEZ-MOI.txt` et un `RAPPORT.txt` avec tout ce qu'il a trouvé.

> **Si un fichier `.json` ne restaure rien** : c'est presque toujours une base
> vide (le programme prenait autrefois le dossier le plus récent au lieu du plus
> complet). La version actuelle écrit plusieurs fichiers, numérotés du plus
> complet au plus vide. Dans le logiciel, **Paramètres → Importer un fichier de
> récupération (.json)…** affiche, avant toute restauration, le nombre de
> classes, d'élèves et de comptes contenus dans le fichier : si c'est « 0
> classe / 0 élève », choisissez le fichier suivant.

## Méthode 3 — à la main, sans aucun programme

1. Fermez GestSchool. Touche **Windows + R**, tapez `%APPDATA%`, validez.
2. Renommez `GestSchool` en `GestSchool-vide`.
3. Renommez `e-School Gestion Bulletins` en `GestSchool`.
4. Relancez GestSchool.

## Méthode 3 bis — importer un fichier sans rien risquer

**Paramètres → Importer un fichier de récupération (.json)…**

Le logiciel lit le fichier, en extrait **toutes** les bases qu'il contient (un
fichier peut en renfermer plusieurs) et les présente dans un tableau : classes,
élèves, comptes, notes, versements, nom de l'établissement. La plus complète est
proposée en premier. Vous ne restaurez que ce que vous avez vu.

- un fichier vide est signalé en rouge (« aucune classe ni aucun élève ») ;
- une base sans compte administrateur est refusée (elle rendrait le logiciel
  inaccessible) ;
- la restauration remplace les données actuelles, puis renvoie à l'écran de
  connexion.

## Méthode 4 — restaurer une sauvegarde `.json`

Si vous avez déjà exporté une sauvegarde (bouton **Sauvegarder toutes les
données…**, ou le fichier déposé chaque jour dans
`Documents\GestSchool-Sauvegardes`) :

GestSchool → **Paramètres → Restaurer une sauvegarde…** → choisissez le fichier
`sauvegarde-gestschool_…json`.

---

## Si rien n'est retrouvé

- Clic droit sur `%APPDATA%` → **Propriétés** → **Versions précédentes** :
  Windows garde parfois une copie du dossier datant d'avant la mise à jour.
- Cherchez un fichier `sauvegarde-gestschool_*.json` dans Téléchargements, le
  Bureau, Documents ou OneDrive.
- Envoyez le dossier `GestSchool-recuperation-…` (ou son `RAPPORT.txt`) : il
  contient tout ce qui subsiste sur l'ordinateur.

## Comment cela ne se reproduit pas

- Au démarrage, le logiciel vérifie que le dossier du nom actuel contient
  réellement la base ; sinon il reprend l'ancien dossier (copie, sans rien
  effacer). Un dossier `GestSchool` vide ne peut plus masquer vos données.
- **Sauvegarde automatique quotidienne** dans `Documents\GestSchool-Sauvegardes`
  (40 dernières conservées), sans aucune fenêtre. Menu
  **Aide → Sauvegardes automatiques**.
- **Corbeille** : toute suppression est réversible, y compris celle d'une
  classe entière.
- La désinstallation ne supprime pas les données
  (`deleteAppDataOnUninstall: false`).

## Avant toute manipulation

**Ne réinstallez pas, ne cliquez pas sur « Tout effacer » et ne recréez pas de
comptes** avant d'avoir essayé la méthode 1 ou copié le dossier
`%APPDATA%\e-School Gestion Bulletins` quelque part.
