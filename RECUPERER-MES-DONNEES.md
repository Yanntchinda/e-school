# Récupérer mes données après une mise à jour

**Rien n'est effacé par une mise à jour.** Le logiciel n'enregistre pas ses
données dans son dossier d'installation (qui, lui, est remplacé à chaque
nouvelle version) mais dans un dossier de données séparé :

| Situation | Dossier des données |
|---|---|
| Version actuelle (GestSchool) | `%APPDATA%\GestSchool` |
| Ancienne version (e-School Gestion Bulletins) | `%APPDATA%\e-School Gestion Bulletins` |

Quand le logiciel a changé de nom, il a repris l'ancien dossier. Si un dossier
`GestSchool` **vide** avait déjà été créé auparavant (par un essai de la version
portable, par exemple), le logiciel pouvait démarrer sur ce dossier vide et
paraître « sans données » alors que l'ancien dossier était toujours là, complet.
C'est ce défaut qui est corrigé : le logiciel cherche maintenant la base dans
les deux dossiers et reprend celui qui contient réellement les données.

---

## 1. La solution automatique (recommandée)

1. **Fermez GestSchool** s'il est ouvert.
2. Téléchargez ce fichier :
   [RECUPERER-MES-DONNEES.bat](https://github.com/Yanntchinda/e-school/raw/arena/86c7fea5-e-school/outils/RECUPERER-MES-DONNEES.bat)
3. Double-cliquez dessus.
   Windows peut afficher « Windows a protégé votre PC » : cliquez sur
   **Informations complémentaires** puis **Exécuter quand même**.
   *(Le programme ne fait que lire et copier : il ne supprime rien.)*
4. Lisez le résumé affiché à la fin, puis relancez GestSchool.

Le programme :

- cherche les dossiers de données de toutes les versions du logiciel ;
- en fait une **copie de sécurité** dans un dossier du Bureau
  (`GestSchool-recuperation-date`) ;
- remet l'ancienne base dans le dossier utilisé par GestSchool ;
- fabrique, en plus, un fichier `DONNEES-RECUPEREES_….json` restaurable par le
  logiciel (Paramètres → Restaurer une sauvegarde…) ;
- retrouve les anciennes sauvegardes `.json` (Bureau, Téléchargements,
  Documents, OneDrive) et les copie au même endroit ;
- écrit un `RAPPORT.txt` avec tout ce qu'il a trouvé.

> Si le résumé indique **« Le dossier actuel contient déjà une base : rien n'a
> été remplacé »**, utilisez plutôt le fichier `.json` produit :
> GestSchool → **Paramètres** → **Restaurer une sauvegarde…**

## 2. La solution manuelle (sans aucun programme)

1. Fermez GestSchool.
2. Touche **Windows + R**, tapez `%APPDATA%`, validez.
3. Vous voyez deux dossiers : `GestSchool` et `e-School Gestion Bulletins`.
4. Renommez `GestSchool` en `GestSchool-vide` (il ne doit pas être supprimé).
5. Renommez `e-School Gestion Bulletins` en `GestSchool`.
6. Relancez GestSchool : les classes, élèves, notes et finances reviennent.

Si le dossier `e-School Gestion Bulletins` n'existe pas, passez au point 3.

## 3. Restaurer une sauvegarde `.json`

Si vous avez déjà exporté une sauvegarde (bouton **Sauvegarder toutes les
données…**, ou le fichier déposé automatiquement dans
`Documents\GestSchool-Sauvegardes`) :

GestSchool → **Paramètres** → **Restaurer une sauvegarde…** → choisissez le
fichier `sauvegarde-gestschool_…json`.

## 4. Si rien n'est retrouvé

- Clic droit sur `%APPDATA%` → **Propriétés** → **Versions précédentes** :
  Windows conserve parfois une copie du dossier datant d'avant la mise à jour.
- Cherchez un fichier `sauvegarde-gestschool_*.json` dans Téléchargements,
  Bureau, Documents ou OneDrive.
- Envoyez le dossier `GestSchool-recuperation-…` (ou son `RAPPORT.txt`) pour
  analyse : il contient tout ce qui subsiste sur l'ordinateur.

---

## Ce qui empêche que cela se reproduise

- **Le logiciel retrouve tout seul l'ancien dossier** : au démarrage, il vérifie
  que le dossier du nom actuel contient réellement la base ; sinon il reprend
  l'ancien dossier (copie, sans rien effacer).
- **Sauvegarde automatique quotidienne** : dans l'application Windows, une
  sauvegarde complète est déposée chaque jour dans
  `Documents\GestSchool-Sauvegardes` (40 dernières conservées), sans aucune
  fenêtre. Menu **Aide → Sauvegardes automatiques**.
- **Journal de démarrage** : le fichier `demarrage.log` du dossier de données
  indique quel dossier a été utilisé à chaque lancement.
- La désinstallation du logiciel **ne supprime pas** les données
  (`deleteAppDataOnUninstall: false`).

## Rappel : avant toute manipulation

**Ne réinstallez pas, ne cliquez pas sur « Tout effacer » et ne recréez pas de
comptes** avant d'avoir lancé la récupération ou copié le dossier
`%APPDATA%\e-School Gestion Bulletins` quelque part.
