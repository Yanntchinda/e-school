# Comment générer l'installateur Windows sur votre ordinateur

Le code est ENTIÈREMENT PRÊT. Vous n'avez qu'à lancer ces 3 commandes sur votre ordinateur pour générer le fichier .exe d'installation :

## Étape 1 : Installer Node.js
Téléchargez Node.js depuis https://nodejs.org/fr (version LTS recommandée) et installez-le.
Redémarrez votre ordinateur après l'installation.

## Étape 2 : Ouvrir un invité de commandes
Ouvrez un invité de commandes (cmd) dans le dossier `desktop-app` de ce projet.

## Étape 3 : Lancer ces commandes
```cmd
npm install
npm run build:win
```

## Étape 4 : Récupérer l'installateur
Le fichier d'installation Windows sera généré ici :
`desktop-app/dist/installiers/e-School Gestion Bulletins Setup 1.0.0.exe`

Lancez ce fichier .exe sur n'importe quel ordinateur Windows pour installer l'application. Un raccourci sera créé sur le bureau.

---

## Version PORTABLE SANS INSTALLATION DISPONIBLE
En attendant la compilation, vous pouvez utiliser la version portable : il suffit de double-cliquer sur `LANCER-E-SCHOOL.bat` dans le dossier `version-portable/`, l'application s'ouvre dans votre navigateur et fonctionne exactement comme l'application installée, sans rien installer.
Toutes vos données sont sauvegardées localement dans le navigateur.
