# Fiche

## Champs visuels seulement

- Les champs suivants sont maintenant affichés dans la fiche:
  - `Echec crit off`
  - `Echec crit def`
- Ils sont stockés séparément des seuils de réussite critique.
- Ils ne participent actuellement à aucun calcul de gameplay.
- Ils existent pour préparer une future évolution sans mélanger les sémantiques avec les réussites critiques.

## Champ de profil ajoute

- `Esquive de dos (%)` fait partie de la fiche car il s'agit d'un réglage de profil joueur persistant.

## Champs de survie

- `Actuellement` s'affiche maintenant au survol d'un personnage, dans un petit panneau sur la droite de l'ecran, et non plus dans le mainframe EasySanalune.
- Il affiche : `PDV`, `Armure`, `RDA`, `RDA critique`, `Durabilité`.
- Le panneau reste visible tant que le curseur est encore sur le personnage et attend environ `1` seconde avant son fondu de sortie.
- `PDV` reste modifiable depuis la modale `Fiche`.
- La valeur de base des `PDV` est `5`.
- Les `PDV` peuvent descendre jusqu'à `-2` au minimum.
- `Armure` se choisit parmi 5 états prédéfinis : `Nue`, `Légère`, `Intermédiaire`, `Lourde`, `Spéciale`.
- Dans la modale `Fiche`, changer l'armure met maintenant à jour tout de suite `Durabilité`, `RDA` et `RDA critique`.
- Pour les armures classiques (`Nue`, `Légère`, `Intermédiaire`, `Lourde`), ces champs sont grisés car ils reviennent à leur valeur de base à la confirmation.
- L'armure `Nue` n'a pas de durabilité.
- L'armure `Intermédiaire` utilise `3 / 3`.
- L'armure `Spéciale` laisse `RDA`, `RDA critique` et `Durabilité` configurables, y compris la valeur `infini`.
- Ces valeurs sont persistées par profil joueur.

## Export / import de profil

- Le bouton `Exporter` produit un texte copiable du profil courant.
- Sur un autre personnage, le bouton `Importer` crée un nouveau profil à partir de ce texte.
- L'import restaure les rands exportés avec leurs catégories, leurs issues personnalisées, les réglages de fiche associés (`crit`, `Esquive de dos`, `PDV`, `Armure`) ainsi que les buffs/debuffs et leurs catégories.
- Les catégories de rands et de buffs conservent leur ordre, leur nom et leur état réduit/ouvert.
- Les issues simples (`20 = ...`) et par plage (`40-60 = ...`) sont aussi recopiées à l'import.
- Si le nom existe déjà localement, un suffixe est ajouté pour éviter l'écrasement.
