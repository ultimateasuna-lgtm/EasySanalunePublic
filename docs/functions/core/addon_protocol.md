# core/addon_protocol.lua

## Resume

Logique metier, protocole, etat et resolution hors widgets.

## Fonctions

### sanitize_pipe(value)

- Portee: local
- Ligne source: 23
- Role: fonction referencee automatiquement depuis core/addon_protocol.lua.

### split_message(message)

- Portee: local
- Ligne source: 30
- Role: fonction referencee automatiquement depuis core/addon_protocol.lua.

### Protocol.build_mj_announce(playerName, timestamp, isEnabled)

- Portee: global
- Ligne source: 39
- Role: fonction referencee automatiquement depuis core/addon_protocol.lua.

### Protocol.build_rand_request(requestId, sender, randName, minVal, maxVal, timestamp, critOff, critDef, mobName, attackerReason, mobSyncId, mobId, isBehindAttack)

- Portee: global
- Ligne source: 49
- Role: fonction referencee automatiquement depuis core/addon_protocol.lua.

### Protocol.build_mj_attack_request(requestId, mjName, targetPlayer, attackType, minVal, maxVal, timestamp, critOff, critDef, mobName, isBehindAttack)

- Portee: global
- Ligne source: 68
- Role: fonction referencee automatiquement depuis core/addon_protocol.lua.

### Protocol.build_mj_mob_sync_reset(syncId, senderName, timestamp, activeMobId, expectedCount)

- Portee: global
- Ligne source: 85
- Role: fonction referencee automatiquement depuis core/addon_protocol.lua.

### Protocol.build_mj_mob_sync_entry(syncId, senderName, mobId, mobName, isSupport, isActive)

- Portee: global
- Ligne source: 97
- Role: fonction referencee automatiquement depuis core/addon_protocol.lua.

### Protocol.build_mj_mob_sync_done(syncId, senderName, timestamp, receivedCount)

- Portee: global
- Ligne source: 110
- Role: fonction referencee automatiquement depuis core/addon_protocol.lua.

### Protocol.build_player_survival_request(playerName, timestamp)

- Portee: global
- Ligne source: 121
- Role: fonction referencee automatiquement depuis core/addon_protocol.lua.

### Protocol.build_player_survival_sync(playerName, timestamp, hitPoints, armorType, durabilityCurrent, durabilityMax, durabilityInfinite, rda, rdaCrit)

- Portee: global
- Ligne source: 130
- Role: fonction referencee automatiquement depuis core/addon_protocol.lua.

### Protocol.build_rand_resolve(requestId, senderName, resultText, timestamp)

- Portee: global
- Ligne source: 146
- Role: fonction referencee automatiquement depuis core/addon_protocol.lua.

### Protocol.build_mj_attack_resolve(requestId, senderName, resultText, timestamp)

- Portee: global
- Ligne source: 156
- Role: fonction referencee automatiquement depuis core/addon_protocol.lua.

### Protocol.parse_message(message)

- Portee: global
- Ligne source: 166
- Role: fonction referencee automatiquement depuis core/addon_protocol.lua.

