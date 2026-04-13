# Buff Rules

## Regle speciale Soutien x2

- La multiplication par 2 s'applique uniquement aux buffs/debuffs portant sur:
  - `Toutes les stats`
  - `Toutes les stats offensives`
- Cette règle ne s'applique pas:
  - aux buffs ciblant directement `Soutien`
  - aux buffs défensifs
  - aux autres catégories de critique
- Le multiplicateur impacte:
  - le calcul effectif
  - l'affichage effectif du rand `Soutien`

## Nouvelles categories crit

- Nouvelles catégories de buff/debuff:
  - `Toutes les réussites crits`
  - `Réussite crit off`
  - `Réussite crit def`

## Application sur les seuils crit

- Les valeurs de `réussite crit` modifient le seuil de critique, pas le résultat du rand.
- Convention retenue:
  - buff positif: réduit le seuil, donc rend le critique plus facile
  - debuff négatif: augmente le seuil, donc rend le critique plus difficile
- Formule:
  - `seuil_effectif = max(1, seuil_base - bonus_crit)`
- `Toutes les réussites crits` s'applique aux seuils off et def.
- `Réussite crit off` s'ajoute seulement au seuil offensif.
- `Réussite crit def` s'ajoute seulement au seuil défensif.

## Portee

- Ces modificateurs sont locaux au profil courant.
- Un buff/debuff peut viser soit une stat standard, soit un rand existant précis du profil courant, y compris un rand personnalisé ajouté dans une catégorie.
- En mode `Appliquer a plusieurs stats`, la sélection passe par une liste déroulante scrollable au lieu d'une grille fixe.
- Pour les attaques offensives joueur vers MJ, les seuils critiques ajustés sont intégrés dans le payload envoyé.
- Pour la défense joueur contre MJ, l'ajustement se fait localement au moment de la résolution.
