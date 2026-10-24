# Démarrer en production

Le logiciel ne contient **aucun compte de test** et **aucune donnée fictive**.
À la première ouverture, il vous demande de créer votre établissement et votre
compte administrateur.

## 1. Première ouverture

1. Ouvrez `index.html` (ou l'application installée). Tous les champs sont
   **vides** : rien n'est pré-rempli, aucune donnée d'exemple n'est proposée.
2. Renseignez le **nom de l'établissement**, la **ville** et l'**année scolaire**.
3. Créez le **compte administrateur** : nom complet, identifiant, mot de passe
   (saisi deux fois). C'est ce compte qui gère tout le reste.
4. Vous arrivez sur un espace vide : créez votre première classe, puis importez
   la liste des élèves (voir `IMPORT-ELEVES.md`).

> Conservez l'identifiant et le mot de passe de l'administrateur. Aucun mot de
> passe de secours n'est prévu : en cas d'oubli, restaurez une sauvegarde ou
> contactez la personne qui a installé le logiciel.

## 2. Créer les autres comptes

Dans **Paramètres → Personnel**, ajoutez un compte par personne :

| Rôle | Ce que la personne peut faire |
|---|---|
| Enseignant | saisir les notes de ses matières, voir ses classes |
| Surveillant général | saisir les absences, retards et consignes |
| Économe | montants dus, versements, reçus |

Chaque compte a son propre identifiant et son mot de passe. Les enseignants
sont ensuite affectés aux matières dans les paramètres de chaque classe.

## 3. Enregistrer les données

Trois possibilités, au choix dans **Paramètres → Base de données partagée** :

- **Aucune** : tout reste sur cet ordinateur.
- **Mon serveur e-school** : un poste du réseau fait office de base commune
  (`server/e-school-server.py`, aucune installation). Voir `server/README.md`.
- **Supabase** : service hébergé, facultatif.

Dès que la base est connectée, chaque modification part toute seule ; il n'y a
aucun bouton « Envoyer » à cliquer.

## 4. Sauvegarder

**Paramètres → Sauvegarde de toutes les données** produit un fichier unique et
daté contenant élèves, notes, finances, archives, **sessions précédentes**,
comptes et réglages. Il se réimporte sur le même poste ou sur un autre.

Faites-le régulièrement, et **avant** chaque opération importante
(réinitialisation, changement d'ordinateur, fin d'année).

## 5. Si vous arrivez d'une ancienne version de démonstration

Une installation créée par une version précédente affiche une seule fois
l'écran **« Passage en production »** :

- **Effacer et configurer mon établissement** (recommandé) : supprime les
  comptes de test, les élèves fictifs, leurs notes et leurs finances. Le nom,
  la ville, l'année, l'en-tête et le logo sont conservés. Si une base partagée
  est connectée, elle est vidée en même temps pour que les données de test ne
  reviennent pas.
- **Conserver mes données** : si vous avez déjà saisi vos vraies informations.
  Le mode démonstration est simplement désactivé ; supprimez ensuite les
  comptes de test un par un dans **Paramètres → Personnel**.

Un bouton permet de télécharger une sauvegarde avant de choisir.

## En-tête et logo des bulletins

L'établissement importe lui-même le **bandeau** et le **logo** depuis
**Paramètres** ; aucune image n'est fournie par le logiciel. Sans en-tête, les
bulletins s'impriment sans bandeau ; sans logo, le tableau d'honneur s'imprime
sans image. Les deux peuvent être retirés à tout moment.

## Ce qui a été retiré

- Comptes de démonstration (`admin`, professeurs, surveillant, économe) et
  leurs mots de passe.
- Classes, élèves, notes, absences et versements fictifs créés automatiquement.
- Boutons « Charger un exemple », « Ajouter une classe d'exemple »,
  « Réinitialiser les données de démo », « Simuler » les leçons et
  « Saisir à la place des professeurs ».
- Portraits d'exemple livrés avec le logiciel.
- Valeurs pré-remplies de la page d'accueil (« Ming's Bilingual Institute »,
  « Douala », « 2026/2027 »), l'image d'en-tête et le logo de démonstration, la
  pastille « M » du bandeau et le long texte d'introduction.

Seul l'outil de **préparation de la session suivante** (fin d'année) est
conservé : il travaille sur vos vraies données et crée la session suivante.
