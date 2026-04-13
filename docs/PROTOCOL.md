# EasySanalune Protocol

## Canal

- Prefix addon: `easysanalune`
- Canaux utilisés: `RAID`, sinon `PARTY`
- Si aucun canal de groupe n'est disponible, aucun message n'est envoyé.
- Si un joueur n'a pas l'addon, le comportement reste silencieux.

## Versioning

- Les messages historiques conservent leur format existant.
- Les messages de synchronisation MJ utilisent une version explicite `1` en deuxième champ.
- Les nouveaux champs réseau sont ajoutés en fin de payload pour préserver la compatibilité des anciens parseurs quand c'est possible.

## Types de messages

### `MJ_ANNOUNCE`

- Format: `MJ_ANNOUNCE|1|playerName|timestamp|isEnabled`
- Usage: annonce de présence MJ et propagation immédiate de l'état de la case `MJ`.
- `isEnabled`: `1` si le joueur est MJ, `0` s'il vient de décocher `MJ`.

### `PLAYER_SURVIVAL_REQUEST`

- Format: `PLAYER_SURVIVAL_REQUEST|1|playerName|timestamp`
- Usage: demande a un joueur de renvoyer son etat `Actuellement` quand il est survole.
- Ce message est utilise en `WHISPER` pour fonctionner meme hors groupe.

### `PLAYER_SURVIVAL_SYNC`

- Format: `PLAYER_SURVIVAL_SYNC|1|playerName|timestamp|hitPoints|armorType|durabilityCurrent|durabilityMax|durabilityInfinite|rda|rdaCrit`
- Usage: partage l'état `Actuellement` d'un joueur pour l'affichage au survol du personnage.
- Peut etre envoye au groupe ou en `WHISPER` en reponse a `PLAYER_SURVIVAL_REQUEST`.
- `durabilityInfinite`: `1` si la durabilité est infinie, sinon `0`.

### `RAND_REQUEST`

- Format actuel:
  `RAND_REQUEST|requestId|sender|randName|min|max|timestamp|critOff|critDef|mobName|attackerReason|mobSyncId|mobId|isBehindAttack`
- Usage: attaque offensive joueur vers MJ.
- `mobName`: nom choisi dans la liste synchronisée.
- `mobSyncId`: identifiant de la dernière synchro MJ utilisée au moment du choix.
- `mobId`: identifiant interne du mob côté MJ.
- `isBehindAttack`: `1` si attaque de dos, sinon `0`.

### `RAND_RESOLVE`

- Format: `RAND_RESOLVE|requestId|senderName|resultText|timestamp`
- Usage: résultat de résolution d'une attaque joueur vers MJ.

### `MJ_ATTACK_REQUEST`

- Format actuel:
  `MJ_ATTACK_REQUEST|requestId|mjName|targetPlayer|attackType|min|max|timestamp|critOff|critDef|mobName|isBehindAttack`
- Usage: attaque MJ vers joueur.
- `attackType`: `ATK_PHY` ou `ATK_MAG`.
- `isBehindAttack`: `1` si attaque de dos, sinon `0`.

### `MJ_ATTACK_RESOLVE`

- Format: `MJ_ATTACK_RESOLVE|requestId|senderName|resultText|timestamp`
- Usage: résultat de défense joueur contre une attaque MJ.

### `MJ_MOB_SYNC_RESET`

- Format: `MJ_MOB_SYNC_RESET|1|syncId|sender|timestamp|activeMobId|expectedCount`
- Usage: démarre une nouvelle synchronisation de la liste des mobs.
- Effet côté joueur: la synchro en cours est remplacée par cette nouvelle source.

### `MJ_MOB_SYNC_ENTRY`

- Format: `MJ_MOB_SYNC_ENTRY|1|syncId|sender|mobId|mobName|isSupport|isActive`
- Usage: envoie une entrée de mob synchronisée.
- `isSupport`: tag purement indicatif.

### `MJ_MOB_SYNC_DONE`

- Format: `MJ_MOB_SYNC_DONE|1|syncId|sender|timestamp|receivedCount`
- Usage: marque la fin de la synchro.
- La dernière synchro complète reçue devient la source utilisée par la popup offensive côté joueur.

## Logique de synchronisation des mobs

- Le bouton `Rafraîchir` côté MJ envoie un cycle `RESET -> ENTRY* -> DONE`.
- La liste synchronisée contient uniquement les données nécessaires au choix de cible côté joueur:
  - `mobId`
  - `mobName`
  - `isSupport`
  - `isActive`
- La synchro est stockée en mémoire de session, pas dans les SavedVariables.
- Politique actuelle: la dernière synchro MJ reçue remplace la précédente.
