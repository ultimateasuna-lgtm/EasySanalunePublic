# Changelog

## 2026-04-11

- ajout d'un affichage `Actuellement` au survol du personnage avec `PDV`, `Armure`, `Durabilité`, `RDA` et `RDA critique`
- les `PDV` joueur ont une valeur de base de `5` avec un minimum autorisé à `-2`
- le type d'armure joueur et mob peut maintenant être choisi entre `Nue`, `Légère`, `Intermédiaire`, `Lourde` et `Spéciale`
- la modale `Fiche` met maintenant à jour visuellement `Durabilité`, `RDA` et `RDA critique` dès qu'on change d'armure
- les champs dérivés sont grisés pour les armures classiques
- l'armure `Nue` n'a pas de durabilité
- l'armure `Intermédiaire` passe à `3/3`
- l'armure spéciale reste éditable et supporte `infini`
- l'export/import de profil conserve désormais aussi `PDV`, `Armure`, `Durabilité`, `RDA` et `RDA critique`

## 2026-04-06

- ajout du tag MJ `Soutien (indicatif)` sur les mobs
- ajout du bouton `Ajouter groupe/raid` dans la fenêtre MJ
- ajout du bouton `Rafraîchir` pour synchroniser la liste des mobs vers les joueurs ayant l'addon
- ajout d'une popup joueur de sélection de mob pour les rands offensifs
- ajout du flag `Attaque de dos` sur les attaques réseau concernées
- ajout du champ profil `Esquive de dos (%)`
- ajout du champ MJ par mob `Esquive de dos (%)` avec valeur par défaut `50`
- réorganisation de la fiche mob MJ en deux colonnes et ajout des champs `ECrit off` / `ECrit def`
- ajout de l'historique MJ des 5 dernières actions avec relance
- ajout des catégories de buffs `Toutes les réussites crits`, `Réussite crit off`, `Réussite crit def`
- application de la règle `Soutien x2` sur `Toutes les stats` et `Toutes les stats offensives`
- ajout visuel des champs `Echec crit off` et `Echec crit def` dans la fiche
- ajout de la documentation technique et du guide de test dans `docs/`