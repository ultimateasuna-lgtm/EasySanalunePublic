local Core = _G.EasySanaluneCore or {}
_G.EasySanaluneCore = Core

Core.CombatSession = Core.CombatSession or {}
local CombatSession = Core.CombatSession

local function default_shorten(name)
  return tostring(name or "")
end

local function attach_attacker_roll(resolution, session, attackerName, attackerMin, attackerMax, shorten)
  if type(resolution) ~= "table" or type(session) ~= "table" then
    return
  end

  local toShort = shorten or default_shorten
  local attackerShort = toShort(tostring(attackerName or ""))
  for i = 1, #(session.rollBuffer or {}) do
    local entry = session.rollBuffer[i]
    if entry and entry.min == attackerMin and entry.max == attackerMax then
      local entryShort = toShort(tostring(entry.roller or ""))
      if entryShort == attackerShort then
        resolution.attackerRoll = entry
        break
      end
    end
  end
end

local function build_resolution(requestId, req, defenderName, defenderRandType, defMin, defMax, defenderCritDef, mobName, defenderDodgeBackPercent, now)
  return {
    requestId = requestId,
    attacker = req.attacker or req.sender,
    attackerMin = req.min,
    attackerMax = req.max,
    attackerCritOff = req.attackerCritOff,
    defender = tostring(defenderName or ""),
    defenderRandType = defenderRandType,
    defenderMin = defMin or 1,
    defenderMax = defMax or 100,
    defenderCritDef = defenderCritDef,
    defenderDodgeBackPercent = defenderDodgeBackPercent,
    mobName = tostring(mobName or ""),
    isBehindAttack = req.isBehindAttack and true or false,
    startTime = tonumber(now) or 0,
    attackerRoll = nil,
    defenderRoll = nil,
  }
end

function CombatSession.new()
  return {
    knownMJs = {},
    rollBuffer = {},
    pendingMJRequests = {},
    pendingPlayerDefenseRequests = {},
    pendingPlayerResolutions = {},
    pendingResolutions = {},
    syncedMobState = {
      syncId = nil,
      sender = nil,
      activeMobId = nil,
      timestamp = 0,
      expectedCount = 0,
      receivedCount = 0,
      complete = false,
      mobs = {},
    },
    actionHistory = {},
    mjRequestCounter = 0,
    mjAttackRequestCounter = 0,
  }
end

function CombatSession.next_rand_request_id(session, playerName)
  if type(session) ~= "table" then
    return (tostring(playerName or "X") .. "_1")
  end
  session.mjRequestCounter = (tonumber(session.mjRequestCounter) or 0) + 1
  return tostring(playerName or "X") .. "_" .. tostring(session.mjRequestCounter)
end

function CombatSession.next_attack_request_id(session, playerName)
  if type(session) ~= "table" then
    return (tostring(playerName or "MJ") .. "_ATK_1")
  end
  session.mjAttackRequestCounter = (tonumber(session.mjAttackRequestCounter) or 0) + 1
  return tostring(playerName or "MJ") .. "_ATK_" .. tostring(session.mjAttackRequestCounter)
end

function CombatSession.add_known_mj(session, mjName, now)
  if type(session) ~= "table" then
    return
  end
  if type(session.knownMJs) ~= "table" then
    session.knownMJs = {}
  end
  local name = tostring(mjName or "")
  if name == "" then
    return
  end
  session.knownMJs[name] = tonumber(now) or 0
end

function CombatSession.add_roll(session, roller, roll, rMin, rMax, now, maxSize)
  if type(session) ~= "table" then
    return
  end
  if type(session.rollBuffer) ~= "table" then
    session.rollBuffer = {}
  end
  local buffer = session.rollBuffer

  table.insert(buffer, 1, {
    roller = roller,
    roll = roll,
    min = rMin,
    max = rMax,
    time = tonumber(now) or 0,
  })

  local cap = tonumber(maxSize) or 20
  while #buffer > cap do
    table.remove(buffer)
  end
end

function CombatSession.find_roll(session, rollerName, rMin, rMax, afterTime, now, expiry, shorten)
  if type(session) ~= "table" or type(session.rollBuffer) ~= "table" then
    return nil
  end

  local toShort = shorten or default_shorten
  local nowTs = tonumber(now) or 0
  local ttl = tonumber(expiry) or 15
  local minTime = tonumber(afterTime) or 0

  for i = 1, #session.rollBuffer do
    local entry = session.rollBuffer[i]
    if entry
      and entry.roller
      and entry.min == rMin
      and entry.max == rMax
      and (nowTs - (tonumber(entry.time) or 0)) < ttl
      and (tonumber(entry.time) or 0) >= minTime then
      local shortName = toShort(tostring(entry.roller))
      if shortName == rollerName or tostring(entry.roller) == rollerName then
        return entry
      end
    end
  end

  return nil
end

function CombatSession.start_mj_resolution(session, requestId, state, defenderRandType, defMin, defMax, now, mjName, shorten)
  if type(session) ~= "table" then
    return nil
  end
  if type(session.pendingMJRequests) ~= "table" then
    return nil
  end
  if type(session.pendingResolutions) ~= "table" then
    session.pendingResolutions = {}
  end

  local req = session.pendingMJRequests[requestId]
  if not req then
    return nil
  end

  local effectiveMobId = req.selectedMobId
  if effectiveMobId == nil and type(state) == "table" then
    effectiveMobId = state.mj_active_mob_id
  end

  local mobName = ""
  local mobCritDef = nil
  local mobDodgeBackPercent = nil
  if type(state) == "table" and effectiveMobId and type(state.mj_mobs) == "table" then
    local mob = state.mj_mobs[effectiveMobId]
    if mob then
      mobName = tostring(mob.name or "")
      mobCritDef = tonumber(mob.crit_def_success)
      mobDodgeBackPercent = tonumber(mob.dodge_back_percent)
    end
  end
  if mobName == "" then
    mobName = tostring(req.mobName or "")
  end

  local resolution = build_resolution(
    requestId,
    req,
    (mjName or "MJ"),
    defenderRandType,
    defMin,
    defMax,
    mobCritDef,
    mobName,
    mobDodgeBackPercent,
    now
  )
  session.pendingResolutions[requestId] = resolution

  attach_attacker_roll(resolution, session, req.sender, req.min, req.max, shorten)

  return resolution
end

function CombatSession.start_player_defense_resolution(session, requestId, state, defenderRandType, defMin, defMax, now, defenderName, shorten)
  if type(session) ~= "table" then
    return nil
  end
  if type(session.pendingPlayerDefenseRequests) ~= "table" then
    return nil
  end
  if type(session.pendingPlayerResolutions) ~= "table" then
    session.pendingPlayerResolutions = {}
  end

  local req = session.pendingPlayerDefenseRequests[requestId]
  if not req then
    return nil
  end

  local myCritDef = tonumber(state and state.crit_def_success) or nil

  local resolution = build_resolution(
    requestId,
    req,
    (defenderName or "Player"),
    defenderRandType,
    defMin,
    defMax,
    myCritDef,
    req.mobName,
    now
  )
  session.pendingPlayerResolutions[requestId] = resolution

  attach_attacker_roll(resolution, session, req.attacker, req.min, req.max, shorten)

  return resolution
end
