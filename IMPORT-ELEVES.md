# Importer une liste d'élèves

Deux boutons dans l'application suffisent : **« Télécharger le modèle »** puis
**« Importer »**. Vous pouvez aussi ouvrir **votre propre fichier Excel
(.xlsx)** : une feuille par classe, et tout est importé d'un coup. Les
matricules sont toujours créés par le logiciel — vous ne les saisissez jamais.

## Où ça se trouve

1. Connectez-vous comme administrateur.
2. Ouvrez une classe → onglet **Élèves** → **Importer une liste d'élèves**.
   *(Ou, à la création d'une classe, cochez « Importer ensuite la liste des
   élèves ».)*
3. Cliquez sur **Télécharger le modèle Excel (.xls)**, remplissez-le dans
   Excel, puis rapportez-le avec **Ouvrir un fichier**.

Le bouton **« Importer un classeur Excel »** du tableau de bord ouvre la même
fenêtre : c'est le chemin le plus rapide pour une année complète.

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

La colonne **`SÉRIE`** (`A`, `C`, `D`) est reconnue en plus, à la place que vous
voulez : `ALL` et `ESP` sont ramenés à `A`. La série est enregistrée sur la
fiche de l'élève, où elle reste modifiable (liste des élèves → **Modifier**),
et s'affiche en pastille à côté du nom.

Seul le nom est indispensable. Une colonne vide n'empêche rien : un élève sans
contact est accepté, il pourra être complété plus tard dans sa fiche.

## Votre propre classeur .xlsx

L'application lit directement le fichier tel qu'Excel l'enregistre : pas besoin
de le convertir en CSV.

- **Une feuille = une classe.** Toutes les feuilles sont lues d'un coup ; une
  feuille vide ou sans élève est ignorée.
- **Un titre au-dessus des en-têtes ne gêne pas** : `Classe : 6ème`,
  `CLASSE :2nde`… La feuille est nommée d'après sa ligne de titre ou son
  onglet, et vous pouvez corriger le nom avant de valider.
- **L'ordre des colonnes est libre.** Les en-têtes sont reconnus même avec des
  variantes d'orthographe ou de casse : `N°`, `NOMS ET PENOMS`,
  `NOMS ET PRÉNOMS`, `SEXE`, `SERIE`/`SÉRIE`, `Date de naissance`,
  `Lieu de naissance`, `contact`/`téléphone`.
- **`contact` = téléphone du parent.** Une valeur `-`, `N/A` ou `Néant` devient
  un champ vide, jamais un faux numéro.
- **Séries** : `A` (avec `ALL` ou `ESP`), `C`, `D`. Si la feuille n'a pas de
  colonne de série, aucune série n'est inventée ; `ALL` ou `ESP` peut rester
  dans le nom de la classe (`3e ALL`).
- **Modèle de bulletin** déduit du niveau : `6e`, `5e`, `4e`, `3e` ; `2nde` →
  `2A` (ou `2C`), `1ère` → `1A` (ou `1D`), `Tle` → `TA` (ou `TD`). Vous pouvez
  en changer dans la fenêtre d'import.
- **Rien n'est enregistré avant votre validation.** La fenêtre affiche chaque
  feuille avec son nom, son modèle, le nombre d'élèves et la destination
  (« nouvelle classe » ou « ajoutés à … »). Décochez ce que vous ne voulez pas.
- **Réimporter le même classeur** ne crée ni doublon d'élève ni doublon de
  classe.

## Le fichier fourni

- `modele-import-eleves.xls` — modèle prêt à remplir (3 feuilles :
  **Eleves**, un exemple, le mode d'emploi). C'est le format à garder :
  si Excel propose « Enregistrer sous », choisissez **Classeur Excel 97-2003**.
- `modele-import-eleves.csv` — même structure, en CSV UTF-8 séparé par `;`,
  pour ceux qui préfèrent le tableur d'un autre logiciel.

Les deux se retrouvent aussi dans l'application, bouton par bouton.

## Bon à savoir

- **Aperçu avant import** : chaque nom reconnu est affiché avec son sexe, sa
  série, sa date de naissance, son parent et son téléphone. Rien n'est
  enregistré avant votre confirmation.
- **Doublons ignorés** : un élève déjà présent dans la classe (même nom) est
  barré et n'est pas ajouté. Réimporter le même fichier ne crée pas de doublon.
- **Matricules** : attribués à l'import, tous différents, au format
  `MBI-<année>-<6 caractères>`. Si votre fichier contient déjà un matricule
  libre et valide (cas d'un transfert), il est repris tel quel.
- **Fichiers acceptés** : `.xlsx` (lu directement), `.xls` du modèle, `.csv`
  et `.txt` en UTF-8. Un `.xls` enregistré par un autre logiciel peut être
  illisible : repartez du modèle ou enregistrez en `.xlsx`.
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
