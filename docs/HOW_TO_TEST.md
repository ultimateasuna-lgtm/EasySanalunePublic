# How To Test

## 1. Sync mobs MJ + 1 joueur

- Ouvrir EasySanalune sur un personnage MJ et un personnage joueur.
- Côté MJ, créer au moins 2 mobs dont un avec `Soutien (indicatif)`.
- Cliquer sur `Rafraîchir`.
- Vérifier côté joueur que la popup offensive propose les mobs synchronisés et affiche le tag soutien.

## 2. Attaque offensif -> popup mobs

- Côté joueur, utiliser un rand offensif.
- Vérifier qu'aucun `/rand` automatique ne part avant le choix du mob.
- Vérifier que la popup de sélection s'ouvre.
- Choisir un mob et valider.
- Vérifier qu'un seul `RandomRoll` part après validation.
- Vérifier côté MJ que la demande apparaît avec le bon joueur, le bon rand et le bon mob.

## 3. Historique + relance

- Générer au moins 2 actions MJ:
  - une attaque joueur vers MJ
  - une attaque MJ vers joueur
- Ouvrir `Historique` côté MJ.
- Vérifier la présence des détails utiles et du timestamp session.
- Cliquer sur `Relancer` sur une entrée rejouable.
- Vérifier que la demande ou l'attaque est recréée correctement.

## 4. Buffs soutien x2

- Ajouter un buff `Toutes les stats` de `+20`.
- Vérifier que `Soutien` gagne `+40` en calcul et en affichage.
- Supprimer ce buff puis ajouter `Toutes les stats offensives` de `+20`.
- Vérifier à nouveau `+40` sur `Soutien`.
- Ajouter ensuite un buff direct `Soutien` de `+20`.
- Vérifier que cette fois le bonus reste `+20`.
- Créer aussi un rand personnalisé dans une nouvelle catégorie, puis cibler ce rand depuis un buff/debuff.
- Vérifier que seul ce rand personnalisé reçoit le bonus affiché.

## 5. Buffs crit

- Ajouter un buff `Réussite crit off` puis déclencher une attaque offensive joueur.
- Vérifier que le seuil critique transmis ou appliqué devient plus favorable.
- Ajouter un buff `Réussite crit def` puis déclencher une défense joueur.
- Vérifier l'effet sur le seuil défensif.

## 6. Esquive de dos 50% et 75%

- Dans la fiche joueur, régler `Esquive de dos (%)` à `50`.
- Côté MJ, lancer une attaque `de dos` et répondre avec `Esquive` côté joueur.
- Vérifier que la valeur défensive effective est divisée par 2, avec arrondi `floor`.
- Refaire avec `75`.
- Vérifier qu'un jet de `180` devient `135`.

## 7. Export / import inter-personnage

- Sur un personnage A, ouvrir le menu profil puis cliquer sur `Exporter`.
- Copier le texte exporté.
- Sur un personnage B, ouvrir le menu profil puis cliquer sur `Importer`.
- Coller le texte puis valider.
- Vérifier qu'un nouveau profil est créé automatiquement.
- Vérifier que les rands et les réglages de fiche importés sont bien présents.
- Vérifier aussi que les catégories de rands sont récupérées dans le même ordre, avec les bons rands à l'intérieur.
- Vérifier que les issues personnalisées des rands sont bien présentes après import, y compris les entrées simples et les plages.
- Vérifier enfin que les buffs/debuffs sont récupérés avec les mêmes catégories, dans le même ordre, avec les mêmes valeurs et états actif/inactif.
