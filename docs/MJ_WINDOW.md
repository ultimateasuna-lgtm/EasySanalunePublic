# Fenetre MJ

## Mobs

- Chaque mob dispose d'un champ `Soutien` en colonne gauche.
- L'ordre des rands suit la fiche basique: `Atk phys`, `Atk mag`, `Soutien`, `Déf phys`, `Déf mag`, `Esquive`.
- Chaque mob dispose aussi d'un champ `Dos (%)` en colonne droite sur la ligne `Esquive`.
- Les mobs partagent maintenant le même bloc de survie que les joueurs : `PDV`, `Armure`, `Durabilité`, `RDA`, `RDA critique`.
- Les règles d'armure classiques et spéciale sont identiques côté joueur et côté mob.
- Les champs `RCrit off`, `RCrit def`, `ECrit off` et `ECrit def` sont regroupés en colonne droite.
- Ce champ démarre à `1-100` par défaut.
- Le pourcentage d'esquive de dos démarre à `50` par défaut.
- Les champs `ECrit` des mobs démarrent à `0`.
- Il n'ajoute plus de badge ou de tag dans la liste des mobs MJ.
- Les boutons MJ lisent en priorité les valeurs visibles du formulaire, même avant sauvegarde.

## Attaque du mob vers joueur

- Nouveau bouton `Ajouter groupe/raid`.
- Priorité de remplissage:
  1. Raid connecté
  2. Groupe connecté
  3. Joueur local seul, pour test local
- Les unités offline sont ignorées.
- Le bouton remplace la liste des cibles par l'état courant du groupe.

## Attaque de dos

- La case `Attaque de dos` s'applique aux attaques MJ vers joueur.
- Le flag est transmis sur le protocole et visible dans les popups concernées.
- En défense `Esquive`, une attaque joueur -> mob de dos applique le pourcentage configuré sur le mob sélectionné.

## Synchronisation des mobs

- Nouveau bouton `Rafraîchir`.
- Envoie la liste actuelle des mobs vers les joueurs ayant l'addon.
- La synchro est volontairement minimale: id, nom, indicateur soutien, mob actif.

## Demandes en attente

- Les demandes reçues côté MJ gardent la sélection de mob locale.
- Le menu de sélection de mob reste réutilisable après relance depuis l'historique.

## Historique

- Nouveau bouton `Historique` dans la zone `Demandes en attente`.
- L'historique garde les 5 dernières actions en mémoire de session.
- Une action contient selon le cas:
  - type d'action
  - acteur
  - cible
  - mob
  - plage de jet
  - flag `attaque de dos`
  - texte complet de résolution si disponible
- Le stockage est mémoire uniquement, jamais en SavedVariables.
- Les entrées rejouables exposent un bouton `Relancer`.

## Replay / re-roll

- `Attaque joueur -> MJ`: la relance recrée une demande MJ locale à traiter de nouveau.
- `Attaque MJ -> joueur`: la relance renvoie la même demande au joueur et relance le jet d'attaque.
- Une résolution purement informative reste visible mais n'est pas forcément rejouable.
