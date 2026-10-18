# e-School - Application de bureau de gestion des bulletins scolaires

Application desktop installable pour Windows, Mac et Linux, basée sur la version web du logiciel de gestion des notes et bulletins.

## 🚀 Installation pour les utilisateurs finaux

### Windows
Téléchargez le fichier `.exe` depuis le dossier `dist/installers/`, lancez-le et suivez l'assistant d'installation.
- Raccourci créé sur le bureau et dans le menu Démarrer
- Fonctionne sur Windows 10 et 11 (64 bits)

### macOS
Téléchargez le fichier `.dmg`, ouvrez-le et glissez l'application dans votre dossier Applications.

### Linux
- Utilisez le fichier `.AppImage` : rendez-le exécutable et lancez-le (pas d'installation nécessaire)
- Ou le paquet `.deb` pour Debian/Ubuntu : `sudo apt install ./e-school-bulletins.deb`

## 💾 Données
Toutes les données (classes, élèves, notes) sont enregistrées **localement sur votre ordinateur** dans le dossier de l'application. Aucune connexion internet n'est nécessaire.

### Sauvegardes
Utilisez le menu `Fichier > Exporter une sauvegarde` régulièrement pour conserver une copie de vos données sur une clé USB.

## 🛠️ Pour compiler l'application depuis les sources

### Prérequis
- Node.js 18+

### Commandes
```bash
# Installer les dépendances
npm install

# Lancer l'application en mode développement
npm start

# Générer l'installateur Windows (.exe)
npm run build:win

# Générer l'installateur macOS (.dmg)
npm run build:mac

# Générer les installateurs Linux (.AppImage / .deb)
npm run build:linux
```

Les installateurs générés se trouvent dans le dossier `dist/installers/`.

## Fonctionnalités
- Gestion des classes, élèves et enseignants
- Saisie des notes par trimestre
- Génération automatique des bulletins imprimables
- Calcul des moyennes et rangs
- Passage automatique à la nouvelle année scolaire avec répartition des élèves
- Archivage des années précédentes consultables
- Gestion des matières et coefficients
- Import/export des sauvegardes
- Photos des élèves sur les bulletins
