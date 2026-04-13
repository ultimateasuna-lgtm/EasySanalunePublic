# Memoire projet

## Systeme en place

- Documentation de reference: `docs/`
- Doc des fonctions: `docs/functions/`
- Skills executables: `.github/skills/`
- Skills documentes: `docs/skills/`
- Hook de garde de style: `.github/hooks/fingerprint-guard.json`
- Rappel de recherche journalier: `.github/hooks/research-scout-reminder.json`
- Rappel de workflow code: `.github/hooks/coding-workflow-reminder.json`

## Etat courant

- Le projet a recu plusieurs evolutions MJ, sync de mobs, export/import et buffs.
- Le flux joueur permet maintenant un export de profil puis un import sur un autre personnage via le menu profil.
- Cet export/import recopie aussi les categories de rands, leurs issues, les buffs/debuffs et leurs categories pour retrouver le profil plus fidelement.
- La prochaine discipline a maintenir est la synchronisation entre code Lua, docs et memoire projet.
- Les skills `research-scout`, `research-review` et `consolidate-memory` ont maintenant une frontmatter de detection plus fiable.
- Les demandes de code sur le repo doivent declencher automatiquement, cote agent, une evaluation du besoin de recherche puis une mise a jour memoire en fin de tache.
- La couche workflow repo est maintenant posee: instructions workspace, skills, hooks de rappel, garde de style, et generation de reference fonctionnelle.
- `ui/buffs.lua` peut maintenant cibler une stat standard ou un rand existant du profil courant, y compris dans une categorie personnalisee, avec une liste multi scrollable.
- La fiche joueur inclut maintenant `PDV` (valeur par defaut `5`, borne basse `-2`) et un choix d'armure parmi `Nue`, `Légère`, `Intermédiaire`, `Lourde`, `Spéciale`, avec persistance par profil et export/import.
- Une couche de survie commune joueur/mob est en cours d'integration: `Actuellement`, `Durabilité`, `RDA`, `RDA critique`, armures classiques automatiques et armure speciale editable.
- L'affichage `Actuellement` vise maintenant le survol de personnage plutot qu'un panneau dans le mainframe, avec une synchro addon `PLAYER_SURVIVAL_SYNC` pour les autres joueurs.
- Le bloc de survol a maintenant une fermeture plus robuste quand le curseur quitte la cible, y compris si TRP3 gere son propre tooltip.
- Le bloc de survol se re-ancre maintenant au `TRP3_MainTooltip` quand il est present et utilise un fade court a l'apparition/disparition pour coller davantage au ressenti TRP3.
- Suite au test visuel en jeu, le bloc de survol EasySanalune est maintenant force en position fixe sur la droite de l'ecran pour un rendu plus stable que le pseudo-ancrage au tooltip.
- La modale `Fiche` doit garder un apercu immediat coherent des valeurs de survie quand l'armure change; l'armure `Intermediaire` utilise desormais `3/3`.
- Decision issue du research-scout/review du jour: garder l'approche actuelle de contenance visuelle des libelles longs; si besoin apres tests en jeu, affiner encore avec `FontString:SetMaxLines(1)` plutot qu'une refonte plus lourde.
- Decision reseau/chat: ne plus rejoindre automatiquement le canal texte `easysanalune` ni y poster la version, afin d'eviter toute fuite visuelle de payload protocolaire dans le chat joueur.

## Reprise probable

- Verifier en jeu les cas de longues listes de rands dans la modale buffs et confirmer que le rendu reste lisible sur de petits ecrans.
- Verifier en jeu la parite de comportement entre la fiche joueur et la fenetre MJ pour `PDV`, `Armure`, `Durabilité`, `RDA` et `RDA critique`.
- Si un poli supplementaire est encore utile, tester `SetMaxLines(1)` sur les libelles de dropdown avant toute refonte UI plus large.
- Affiner le garde de style uniquement si des faux positifs apparaissent sur des taches reelles.
- Enrichir la generation des docs fonctions uniquement si une documentation plus semantique devient necessaire.

## Routine recommandee

1. Lire les docs du domaine touche.
2. Si le comportement externe ou l'API est incertain, lancer `research-scout` avant de coder.
3. Modifier le code.
4. Si une decision a ete prise ou tranchee, lancer `research-review`.
5. Regenerer la doc des fonctions si necessaire.
6. Mettre a jour la memoire via `fais la memoire` ou en fin de tache si le travail etait significatif.