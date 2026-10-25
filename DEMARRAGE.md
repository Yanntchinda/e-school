# Démarrer en production

Le logiciel ne contient **aucun compte de test** et **aucune donnée fictive**.
À la première ouverture, il vous demande de créer votre établissement et votre
compte administrateur.

## 1. Première ouverture

1. Ouvrez `index.html` (ou l'application installée). Tous les champs sont
   **vides** : rien n'est pré-rempli, aucune donnée d'exemple n'est proposée.
2. Renseignez le **nom de l'établissement**, la **ville** et l'**année scolaire**.
3. Créez le **compte administrateur** : nom complet, identifiant, mot de passe
   (saisi deux fois), puis une **question secrète** et sa **réponse**. C'est ce
   compte qui gère tout le reste, et la question secrète est le seul moyen de
   récupérer son mot de passe s'il est oublié : choisissez-en une dont la
   réponse ne changera jamais.
4. Vous arrivez sur un espace vide : créez votre première classe, puis importez
   la liste des élèves (voir `IMPORT-ELEVES.md`).

> Conservez l'identifiant et le mot de passe de l'administrateur.

### Mot de passe administrateur oublié

La récupération se fait avec la **question secrète** choisie à l'installation.

1. Page de connexion → espace **Administration** → **« Mot de passe oublié ? »**.
2. Identifiant de l'administrateur (laissez vide s'il n'y a qu'un seul
   administrateur et que vous l'avez aussi oublié).
3. La **question secrète** s'affiche : donnez la réponse. Les accents, les
   majuscules et la ponctuation n'ont pas d'importance.
4. Choisissez un **nouveau mot de passe** : classes, élèves, notes et finances
   sont conservés, rien n'est effacé.

Cinq réponses fausses sont possibles ; au-delà, un **dernier recours** est
proposé sur le même écran (recopier `REINITIALISER`), pour éviter de perdre
l'accès à l'établissement. Définissez alors une nouvelle question secrète.

La question secrète se change à tout moment dans **Mon compte → Question
secrète** (le mot de passe actuel est demandé). Une installation faite avant
cette version n'a pas encore de question : l'application le signale sur le
tableau de bord et la récupération passe provisoirement par le nom de
l'établissement, jusqu'à ce que la question soit définie.

> Cette récupération est **réservée au compte administrateur**. Pour un
> enseignant, un surveillant général ou un économe, l'administrateur
> réinitialise le mot de passe dans **Paramètres → Personnel** (bouton
> « Modifier » du compte). La date de chaque récupération est conservée dans la
> base.

## 2. Créer les autres comptes

Dans **Paramètres → Personnel**, ajoutez un compte par personne :

| Rôle | Ce que la personne peut faire | Espace de connexion |
|---|---|---|
| Enseignant | saisir les notes de ses matières, voir ses classes | **Enseignant** |
| Surveillant général | saisir les absences, retards et consignes | **Surveillant général** |
| Économe | montants dus, versements, reçus, dépenses du quotidien | **Économe** |

Chaque compte a son propre identifiant et son mot de passe. Les enseignants
sont ensuite affectés aux matières dans les paramètres de chaque classe. La page
de connexion propose quatre espaces : Administration, Enseignant, Surveillant
général et Économe ; chaque compte ouvre automatiquement l'espace qui lui
correspond.

## Les dépenses du quotidien (économe)

L'espace **Économe** (et l'administration) a deux onglets : **Frais scolaires
et recettes** et **Dépenses du quotidien**.

- **Saisir une dépense** : le libellé (« Achat de craies ») et le montant
  suffisent ; la date du jour est déjà remplie. Catégorie, mode de paiement,
  référence de la pièce et note sont facultatifs.
- **Le solde se calcule tout seul** : recettes encaissées − dépenses. Il est
  affiché en haut de l'onglet et sur le tableau de bord financier, avec le
  rappel des deux totaux.
- **Modifier** ou **Supprimer** une dépense à tout moment : le solde est
  recalculé aussitôt (la suppression demande une confirmation).
- **Fiche imprimable** : le bouton **Fiche des dépenses (PDF)** ouvre un aperçu
  (période affichée : tout, ce mois-ci, cette année) avec toutes les lignes,
  les totaux et le solde ; **Télécharger le PDF** enregistre le document. Le
  bouton **Fiche** d'une ligne produit le justificatif de cette seule dépense.
- Les dépenses sont comprises dans la **sauvegarde complète**, dans la **base
  partagée** (synchronisées comme les versements) et effacées par « Tout
  effacer ».

## 3. Enregistrer les données

Trois possibilités, au choix dans **Paramètres → Base de données partagée** :

- **Aucune** : tout reste sur cet ordinateur.
- **Mon serveur GestSchool** : un poste du réseau fait office de base commune
  (`server/gestschool-server.py`, aucune installation). Voir `server/README.md`.
- **Supabase** : service hébergé, facultatif.

Dès que la base est connectée, chaque modification part toute seule ; il n'y a
aucun bouton « Envoyer » à cliquer.

## 4. Sauvegarder

**Paramètres → Sauvegarde de toutes les données** produit un fichier unique et
daté contenant élèves, notes, finances, archives, **sessions précédentes**,
comptes et réglages. Il se réimporte sur le même poste ou sur un autre.

Faites-le régulièrement, et **avant** chaque opération importante
(réinitialisation, changement d'ordinateur, fin d'année).

## 4 bis. Supprimer sans perdre : la corbeille

**Rien ne s'efface du premier coup.** Tout élément supprimé — élève, classe,
matière, compte du personnel, versement (et son reçu), dépense, ligne de
discipline, leçons, en-tête ou logo — part dans la **Corbeille**, accessible
dans le menu **Administration** (et par un bouton « Corbeille » dans chaque
section).

- **Restaurer** remet l'élément exactement comme il était : les notes, les
  versements, les reçus et les bulletins reviennent avec lui.
- **Supprimer** (dans la corbeille) efface définitivement, après confirmation.
- Le message affiché après une suppression propose **Annuler** pendant
  quelques secondes.
- **Vider la corbeille** efface tout ce qu'elle contient (les élèves archivés se
  suppriment un par un).
- La corbeille garde les 250 derniers éléments (2,5 Mo maximum) ; au-delà, les
  plus anciens sont effacés et un message le signale.
- L'économe ne voit que les versements et les dépenses ; le surveillant général,
  que la discipline.

La corbeille est comprise dans les sauvegardes `.json`, et « Tout effacer »
télécharge automatiquement une sauvegarde complète avant l'effacement.

## 5. Repartir de zéro

Le logiciel ne crée **aucune donnée de démonstration**, et il n'affiche aucun
écran de « passage en production » : une installation neuve s'ouvre directement
sur la création du compte administrateur.

Pour repartir d'une installation vide (ordinateur récupéré, données d'essai,
changement d'établissement), connectez-vous en administrateur puis allez dans
**Paramètres → Réinitialisation → Tout effacer** :

- les classes, élèves, notes, finances, archives et comptes sont supprimés ;
- le **nom de l'établissement, la ville, l'année, l'en-tête et le logo** sont
  conservés ; vous recréez ensuite votre compte administrateur ;
- si une **base partagée** est connectée, une case à cocher permet de la vider
  en même temps, sinon les données reviendraient à la prochaine synchro.

Une sauvegarde complète est téléchargée automatiquement **avant** l'effacement :
gardez ce fichier, il permet de tout remettre en place (Paramètres → Restaurer
une sauvegarde).

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
