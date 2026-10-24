# Importer une liste d'élèves

Deux boutons dans l'application suffisent : **« Télécharger le modèle »** puis
**« Importer »**. Les matricules sont toujours créés par le logiciel — vous ne
les saisissez jamais.

## Où ça se trouve

1. Connectez-vous comme administrateur.
2. Ouvrez une classe → onglet **Élèves** → **Importer une liste d'élèves**.
   *(Ou, à la création d'une classe, cochez « Importer ensuite la liste des
   élèves ».)*
3. Cliquez sur **Télécharger le modèle Excel (.xls)**, remplissez-le dans
   Excel, puis rapportez-le avec **Ouvrir un fichier**.

## Les colonnes du modèle

| Ordre | Colonne | Obligatoire | Format attendu |
|---|---|---|---|
| 1 | `NOM ET PRÉNOMS` | **oui** | `MBALLA Jean Pierre` (mis en majuscules automatiquement) |
| 2 | `SEXE` | non | `M` ou `F` — `Masculin`, `Féminin`, `Fille`, `Garçon` acceptés |
| 3 | `DATE DE NAISSANCE` | non | `12/03/2013`, `12-03-2013` ou `2013-03-12` |
| 4 | `LIEU DE NAISSANCE` | non | `Douala` |
| 5 | `NOM DU PARENT / TUTEUR` | non | `MBALLA Étienne` |
| 6 | `LIEN DE PARENTÉ` | non | `Père`, `Mère`, `Tuteur` ou `Autre` |
| 7 | `TÉLÉPHONE DU PARENT` | non | `6 99 00 11 22` (espaces, `+`, `-` conservés) |
| 8 | `E-MAIL DU PARENT` | non | `parent@exemple.cm` |
| 9 | `MATRICULE (laisser vide)` | non | **à laisser vide** : le logiciel l'attribue |

Seul le nom est indispensable. Une colonne vide n'empêche rien : un élève sans
contact est accepté, il pourra être complété plus tard dans sa fiche.

## Le fichier fourni

- `modele-import-eleves.xls` — modèle prêt à remplir (3 feuilles :
  **Eleves**, un exemple, le mode d'emploi). C'est le format à garder :
  si Excel propose « Enregistrer sous », choisissez **Classeur Excel 97-2003**.
- `modele-import-eleves.csv` — même structure, en CSV UTF-8 séparé par `;`,
  pour ceux qui préfèrent le tableur d'un autre logiciel.

Les deux se retrouvent aussi dans l'application, bouton par bouton.

## Bon à savoir

- **Aperçu avant import** : chaque nom reconnu est affiché avec son sexe, sa
  date de naissance, son parent et son téléphone. Rien n'est enregistré avant
  votre confirmation.
- **Doublons ignorés** : un élève déjà présent dans la classe (même nom) est
  barré et n'est pas ajouté. Réimporter le même fichier ne crée pas de doublon.
- **Matricules** : attribués à l'import, tous différents, au format
  `MBI-<année>-<6 caractères>`. Si votre fichier contient déjà un matricule
  libre et valide (cas d'un transfert), il est repris tel quel.
- **Fichier .xlsx** : Excel enregistre par défaut dans ce format, que
  l'application ne peut pas lire. Enregistrez plutôt en **CSV UTF-8** ou
  gardez le format **.xls** du modèle ; un message vous le rappelle.
- Vous pouvez aussi **coller** la liste directement depuis Excel (un élève par
  ligne). Une liste de noms seuls fonctionne : `NOM Prénom` puis `M`/`F`.

## Sauvegarder tout le programme

Dans **Paramètres → Sauvegarde de toutes les données**, le bouton
**« Sauvegarder toutes les données… »** produit un fichier
`sauvegarde-e-school_<école>_<date>_<heure>.json` contenant :

- les classes, les élèves, les notes, les appréciations et les leçons ;
- les finances (montants dus et versements) ;
- les élèves archivés ;
- **les sessions précédentes** (années clôturées) ;
- les utilisateurs et les réglages (en-tête, logo).

Il se réimporte par **« Restaurer une sauvegarde… »**, sur le même ordinateur
ou sur un autre. La restauration demande confirmation et remplace les données
présentes.
