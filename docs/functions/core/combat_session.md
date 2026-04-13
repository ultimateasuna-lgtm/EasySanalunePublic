# core/combat_session.lua

## Resume

Logique metier, protocole, etat et resolution hors widgets.

## Fonctions

### default_shorten(name)

- Portee: local
- Ligne source: 7
- Role: fonction referencee automatiquement depuis core/combat_session.lua.

### attach_attacker_roll(resolution, session, attackerName, attackerMin, attackerMax, shorten)

- Portee: local
- Ligne source: 11
- Role: fonction referencee automatiquement depuis core/combat_session.lua.

### build_resolution(requestId, req, defenderName, defenderRandType, defMin, defMax, defenderCritDef, mobName, defenderDodgeBackPercent, now)

- Portee: local
- Ligne source: 30
- Role: fonction referencee automatiquement depuis core/combat_session.lua.

### CombatSession.new()

- Portee: global
- Ligne source: 51
- Role: fonction referencee automatiquement depuis core/combat_session.lua.

### CombatSession.next_rand_request_id(session, playerName)

- Portee: global
- Ligne source: 75
- Role: fonction referencee automatiquement depuis core/combat_session.lua.

### CombatSession.next_attack_request_id(session, playerName)

- Portee: global
- Ligne source: 83
- Role: fonction referencee automatiquement depuis core/combat_session.lua.

### CombatSession.add_known_mj(session, mjName, now)

- Portee: global
- Ligne source: 91
- Role: fonction referencee automatiquement depuis core/combat_session.lua.

### CombatSession.add_roll(session, roller, roll, rMin, rMax, now, maxSize)

- Portee: global
- Ligne source: 105
- Role: fonction referencee automatiquement depuis core/combat_session.lua.

### CombatSession.find_roll(session, rollerName, rMin, rMax, afterTime, now, expiry, shorten)

- Portee: global
- Ligne source: 128
- Role: fonction referencee automatiquement depuis core/combat_session.lua.

### CombatSession.start_mj_resolution(session, requestId, state, defenderRandType, defMin, defMax, now, mjName, shorten)

- Portee: global
- Ligne source: 156
- Role: fonction referencee automatiquement depuis core/combat_session.lua.

### CombatSession.start_player_defense_resolution(session, requestId, state, defenderRandType, defMin, defMax, now, defenderName, shorten)

- Portee: global
- Ligne source: 211
- Role: fonction referencee automatiquement depuis core/combat_session.lua.

