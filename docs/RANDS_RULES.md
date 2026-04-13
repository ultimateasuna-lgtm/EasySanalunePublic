# Rands Rules

## Attaque de dos

- Le flag `Attaque de dos` peut être posé:
  - côté MJ pour une attaque MJ vers joueur
  - côté joueur lors du choix du mob pour une attaque offensive
- Le flag est transporté sur le protocole.
- L'effet gameplay concret implémenté concerne l'esquive, côté joueur comme côté mob.

## Esquive de dos

- Nouveau champ profil: `Esquive de dos (%)`.
- Nouveau champ MJ par mob: `Esquive de dos (%)`.
- Valeur par défaut: `50`.
- Bornes UI: `0` à `100`.
- Valeur stockée en SavedVariables par profil joueur et par mob MJ.

## Calcul de l'esquive de dos

- Quand la défense choisie est `Esquive` et que l'attaque est marquée `de dos`, on réduit la valeur défensive effective.
- Convention retenue:
  - on applique le pourcentage sur la valeur défensive totale retenue
  - formule: `valeur_effective = floor(valeur_totale * pourcentage / 100)`
- Exemples:
  - `50%` sur `180` -> `90`
  - `75%` sur `180` -> `135`

## Arrondi

- Arrondi utilisé: `floor`.
- Raison: cohérence avec le reste de l'addon qui travaille déjà en entiers et utilise `floor` pour les seuils critiques.

## Notes de maintenance

- Le flag `de dos` est déjà propagé plus largement que son effet actuel.
- Cela prépare une extension future à d'autres défenses ou à d'autres règles de résolution.
