local Core = _G.EasySanaluneCore or {}
_G.EasySanaluneCore = Core
local Text = Core.Text or {}

Core.Protocol = Core.Protocol or {}
local Protocol = Core.Protocol

Protocol.LEGACY_CHANNEL = "easysanalune"
Protocol.CHANNEL = "easysanalune2"

Protocol.TYPES = {
  MJ_ANNOUNCE = "MJ_ANNOUNCE",
  PLAYER_SURVIVAL_REQUEST = "PLAYER_SURVIVAL_REQUEST",
  PLAYER_SURVIVAL_SYNC = "PLAYER_SURVIVAL_SYNC",
  RAND_REQUEST = "RAND_REQUEST",
  RAND_RESOLVE = "RAND_RESOLVE",
  MJ_ATTACK_REQUEST = "MJ_ATTACK_REQUEST",
  MJ_ATTACK_RESOLVE = "MJ_ATTACK_RESOLVE",
  MJ_COMBAT_BANNER = "MJ_COMBAT_BANNER",
  MJ_COMBAT_PLAYERS_SYNC = "MJ_COMBAT_PLAYERS_SYNC",
  MJ_PLAYER_TURN_PLAYED = "MJ_PLAYER_TURN_PLAYED",
  MJ_PLAYER_MOVEMENT = "MJ_PLAYER_MOVEMENT",
  MJ_PLAYER_MOVEMENT_ALERT = "MJ_PLAYER_MOVEMENT_ALERT",
  MJ_RAND_TURN_ALERT = "MJ_RAND_TURN_ALERT",
  MJ_RAND_TURN_DECISION = "MJ_RAND_TURN_DECISION",
  MJ_MOB_SYNC_RESET = "MJ_MOB_SYNC_RESET",
  MJ_MOB_SYNC_ENTRY = "MJ_MOB_SYNC_ENTRY",
  MJ_MOB_SYNC_DONE = "MJ_MOB_SYNC_DONE",
}

local function sanitize_pipe(value)
  if Text.sanitize_pipe then
    return Text.sanitize_pipe(value)
  end
  return string.gsub(tostring(value or ""), "|", "/")
end

local function split_message(message)
  local parts = {}
  local raw = tostring(message or "") .. "|"
  for part in raw:gmatch("([^|]*)|") do
    parts[#parts + 1] = part
  end
  return parts
end

function Protocol.build_mj_announce(playerName, timestamp, isEnabled, supportsPlayerSurvival)
  return table.concat({
    Protocol.TYPES.MJ_ANNOUNCE,
    "1",
    tostring(playerName or "Unknown"),
    tostring(timestamp or 0),
    isEnabled == false and "0" or "1",
    supportsPlayerSurvival == false and "0" or "1",
  }, "|")
end

function Protocol.build_rand_request(requestId, sender, randName, minVal, maxVal, timestamp, critOff, critDef, mobName, attackerReason, mobSyncId, mobId, isBehindAttack, critOffFailure, comboWithRequestId, comboWithSender, noDodgeAttack, noDefenseAttack)
  return table.concat({
    Protocol.TYPES.RAND_REQUEST,
    tostring(requestId or ""),
    tostring(sender or "Unknown"),
    sanitize_pipe(randName),
    tostring(minVal or 1),
    tostring(maxVal or 100),
    tostring(timestamp or 0),
    tostring(tonumber(critOff) or 0),
    tostring(tonumber(critDef) or 0),
    sanitize_pipe(mobName),
    sanitize_pipe(attackerReason),
    sanitize_pipe(mobSyncId),
    tostring(mobId or ""),
    isBehindAttack and "1" or "0",
    tostring(tonumber(critOffFailure) or 0),
    sanitize_pipe(comboWithRequestId),
    sanitize_pipe(comboWithSender),
    noDodgeAttack and "1" or "0",
    noDefenseAttack and "1" or "0",
  }, "|")
end

function Protocol.build_mj_attack_request(requestId, mjName, targetPlayer, attackType, minVal, maxVal, timestamp, critOff, critDef, mobName, isBehindAttack, critOffFailure, comboWithRequestId, comboWithSender, noDodgeAttack, noDefenseAttack)
  return table.concat({
    Protocol.TYPES.MJ_ATTACK_REQUEST,
    tostring(requestId or ""),
    tostring(mjName or "MJ"),
    tostring(targetPlayer or ""),
    sanitize_pipe(attackType),
    tostring(minVal or 1),
    tostring(maxVal or 100),
    tostring(timestamp or 0),
    tostring(tonumber(critOff) or 0),
    tostring(tonumber(critDef) or 0),
    sanitize_pipe(mobName),
    isBehindAttack and "1" or "0",
    tostring(tonumber(critOffFailure) or 0),
    sanitize_pipe(comboWithRequestId),
    sanitize_pipe(comboWithSender),
    noDodgeAttack and "1" or "0",
    noDefenseAttack and "1" or "0",
  }, "|")
end

function Protocol.build_mj_mob_sync_reset(syncId, senderName, timestamp, activeMobId, expectedCount)
  return table.concat({
    Protocol.TYPES.MJ_MOB_SYNC_RESET,
    "1",
    tostring(syncId or ""),
    tostring(senderName or "MJ"),
    tostring(timestamp or 0),
    tostring(activeMobId or ""),
    tostring(expectedCount or 0),
  }, "|")
end

function Protocol.build_mj_mob_sync_entry(syncId, senderName, mobId, mobName, isSupport, isActive)
  return table.concat({
    Protocol.TYPES.MJ_MOB_SYNC_ENTRY,
    "1",
    tostring(syncId or ""),
    tostring(senderName or "MJ"),
    tostring(mobId or ""),
    sanitize_pipe(mobName),
    isSupport and "1" or "0",
    isActive and "1" or "0",
  }, "|")
end

function Protocol.build_mj_mob_sync_done(syncId, senderName, timestamp, receivedCount)
  return table.concat({
    Protocol.TYPES.MJ_MOB_SYNC_DONE,
    "1",
    tostring(syncId or ""),
    tostring(senderName or "MJ"),
    tostring(timestamp or 0),
    tostring(receivedCount or 0),
  }, "|")
end

function Protocol.build_player_survival_request(playerName, timestamp)
  return table.concat({
    Protocol.TYPES.PLAYER_SURVIVAL_REQUEST,
    "1",
    tostring(playerName or "Unknown"),
    tostring(timestamp or 0),
  }, "|")
end

function Protocol.build_player_survival_sync(playerName, timestamp, hitPoints, armorType, durabilityCurrent, durabilityMax, durabilityInfinite, rda, rdaCrit, displayName)
  return table.concat({
    Protocol.TYPES.PLAYER_SURVIVAL_SYNC,
    "1",
    tostring(playerName or "Unknown"),
    tostring(timestamp or 0),
    tostring(tonumber(hitPoints) or 5),
    sanitize_pipe(armorType),
    durabilityCurrent == nil and "" or tostring(tonumber(durabilityCurrent) or ""),
    durabilityMax == nil and "" or tostring(tonumber(durabilityMax) or ""),
    durabilityInfinite and "1" or "0",
    tostring(tonumber(rda) or 0),
    tostring(tonumber(rdaCrit) or 0),
    sanitize_pipe(tostring(displayName or "")),
  }, "|")
end

function Protocol.build_rand_resolve(requestId, senderName, resultText, timestamp)
  return table.concat({
    Protocol.TYPES.RAND_RESOLVE,
    tostring(requestId or ""),
    tostring(senderName or "MJ"),
    sanitize_pipe(resultText),
    tostring(timestamp or 0),
  }, "|")
end

function Protocol.build_mj_attack_resolve(requestId, senderName, resultText, timestamp)
  return table.concat({
    Protocol.TYPES.MJ_ATTACK_RESOLVE,
    tostring(requestId or ""),
    tostring(senderName or "Player"),
    sanitize_pipe(resultText),
    tostring(timestamp or 0),
  }, "|")
end

function Protocol.build_mj_combat_banner(action, senderName, roundNumber, side, timestamp, playStartSound, turnDuration)
  return table.concat({
    Protocol.TYPES.MJ_COMBAT_BANNER,
    "1",
    sanitize_pipe(action),
    tostring(senderName or "MJ"),
    tostring(tonumber(roundNumber) or 1),
    sanitize_pipe(side),
    tostring(timestamp or 0),
    playStartSound and "1" or "0",
    tostring(math.max(1, math.floor(tonumber(turnDuration) or 6))),
  }, "|")
end

function Protocol.build_mj_combat_players_sync(senderName, roundNumber, side, playersCsv, timestamp)
  return table.concat({
    Protocol.TYPES.MJ_COMBAT_PLAYERS_SYNC,
    "1",
    tostring(senderName or "MJ"),
    tostring(tonumber(roundNumber) or 1),
    sanitize_pipe(side),
    sanitize_pipe(playersCsv),
    tostring(timestamp or 0),
  }, "|")
end

function Protocol.build_mj_player_turn_played(playerName, roundNumber, side, timestamp)
  return table.concat({
    Protocol.TYPES.MJ_PLAYER_TURN_PLAYED,
    "1",
    tostring(playerName or "Unknown"),
    tostring(tonumber(roundNumber) or 1),
    sanitize_pipe(side),
    tostring(timestamp or 0),
  }, "|")
end

function Protocol.build_mj_player_movement(playerName, roundNumber, side, remainingPercent, budgetPercent, rolled, exceeded, timestamp)
  return table.concat({
    Protocol.TYPES.MJ_PLAYER_MOVEMENT,
    "1",
    tostring(playerName or "Unknown"),
    tostring(tonumber(roundNumber) or 1),
    sanitize_pipe(side),
    tostring(math.floor(tonumber(remainingPercent) or 0)),
    tostring(math.floor(tonumber(budgetPercent) or 100)),
    rolled and "1" or "0",
    exceeded and "1" or "0",
    tostring(timestamp or 0),
  }, "|")
end

function Protocol.build_mj_player_movement_alert(playerName, roundNumber, side, movedPercent, budgetPercent, timestamp)
  return table.concat({
    Protocol.TYPES.MJ_PLAYER_MOVEMENT_ALERT,
    "1",
    tostring(playerName or "Unknown"),
    tostring(tonumber(roundNumber) or 1),
    sanitize_pipe(side),
    tostring(math.floor(tonumber(movedPercent) or 0)),
    tostring(math.floor(tonumber(budgetPercent) or 100)),
    tostring(timestamp or 0),
  }, "|")
end

function Protocol.build_mj_rand_turn_alert(approvalId, sender, randName, minVal, maxVal, randRole, timestamp)
  return table.concat({
    Protocol.TYPES.MJ_RAND_TURN_ALERT,
    "1",
    tostring(approvalId or ""),
    tostring(sender or "Unknown"),
    sanitize_pipe(randName),
    tostring(minVal or 1),
    tostring(maxVal or 100),
    sanitize_pipe(randRole),
    tostring(timestamp or 0),
  }, "|")
end

function Protocol.build_mj_rand_turn_decision(approvalId, mjName, approved, timestamp)
  return table.concat({
    Protocol.TYPES.MJ_RAND_TURN_DECISION,
    "1",
    tostring(approvalId or ""),
    tostring(mjName or "MJ"),
    approved and "1" or "0",
    tostring(timestamp or 0),
  }, "|")
end

function Protocol.parse_message(message)
  local parts = split_message(message)
  if #parts < 1 then
    return nil
  end

  local msgType = parts[1]
  if not msgType or msgType == "" then
    return nil
  end

  local parsed = {
    type = msgType,
    parts = parts,
  }

  if msgType == Protocol.TYPES.MJ_ANNOUNCE then
    parsed.version = parts[2]
    parsed.playerName = parts[3]
    parsed.timestamp = tonumber(parts[4])
    parsed.isEnabled = parts[5] ~= "0"
    parsed.supportsPlayerSurvival = parts[6] == "1"
    return parsed
  end

  if msgType == Protocol.TYPES.PLAYER_SURVIVAL_REQUEST then
    parsed.version = parts[2]
    parsed.playerName = parts[3]
    parsed.timestamp = tonumber(parts[4])
    return parsed
  end

  if msgType == Protocol.TYPES.PLAYER_SURVIVAL_SYNC then
    parsed.version = parts[2]
    parsed.playerName = parts[3]
    parsed.timestamp = tonumber(parts[4])
    parsed.hitPoints = tonumber(parts[5])
    parsed.armorType = parts[6] or "nue"
    parsed.durabilityCurrent = tonumber(parts[7])
    parsed.durabilityMax = tonumber(parts[8])
    parsed.durabilityInfinite = parts[9] == "1"
    parsed.rda = tonumber(parts[10]) or 0
    parsed.rdaCrit = tonumber(parts[11]) or 0
    parsed.displayName = parts[12] or ""
    return parsed
  end

  if msgType == Protocol.TYPES.RAND_REQUEST then
    parsed.requestId = parts[2]
    parsed.sender = parts[3]
    parsed.randName = parts[4]
    parsed.min = tonumber(parts[5])
    parsed.max = tonumber(parts[6])
    parsed.timestamp = tonumber(parts[7])

    if tonumber(parts[8]) ~= nil then
      parsed.attackerCritOff = tonumber(parts[8])
      parsed.attackerCritDef = tonumber(parts[9])
      parsed.mobName = parts[10] or ""
      parsed.attackerReason = parts[11] or ""
      parsed.mobSyncId = parts[12] or ""
      parsed.mobId = tonumber(parts[13])
      parsed.isBehindAttack = parts[14] == "1"
      parsed.attackerCritOffFailure = tonumber(parts[15]) or 0
      parsed.comboWithRequestId = parts[16] or ""
      parsed.comboWithSender = parts[17] or ""
      parsed.noDodgeAttack = parts[18] == "1"
      parsed.noDefenseAttack = parts[19] == "1"
    else
      parsed.attackerCritOff = nil
      parsed.attackerCritDef = nil
      parsed.mobName = parts[8] or ""
      parsed.attackerReason = parts[9] or ""
      parsed.mobSyncId = parts[10] or ""
      parsed.mobId = tonumber(parts[11])
      parsed.isBehindAttack = parts[12] == "1"
      parsed.attackerCritOffFailure = 0
      parsed.comboWithRequestId = ""
      parsed.comboWithSender = ""
      parsed.noDodgeAttack = false
      parsed.noDefenseAttack = false
    end
    return parsed
  end

  if msgType == Protocol.TYPES.RAND_RESOLVE then
    parsed.requestId = parts[2]
    parsed.sender = parts[3]
    parsed.resultText = parts[4]
    parsed.timestamp = tonumber(parts[5])
    return parsed
  end

  if msgType == Protocol.TYPES.MJ_ATTACK_REQUEST then
    parsed.requestId = parts[2]
    parsed.mjName = parts[3]
    parsed.target = parts[4]
    parsed.attackType = parts[5]
    parsed.min = tonumber(parts[6])
    parsed.max = tonumber(parts[7])
    parsed.timestamp = tonumber(parts[8])

    if tonumber(parts[9]) ~= nil then
      parsed.attackerCritOff = tonumber(parts[9])
      parsed.attackerCritDef = tonumber(parts[10])
      parsed.mobName = parts[11] or ""
      parsed.isBehindAttack = parts[12] == "1"
      parsed.attackerCritOffFailure = tonumber(parts[13]) or 0
      parsed.comboWithRequestId = parts[14] or ""
      parsed.comboWithSender = parts[15] or ""
      parsed.noDodgeAttack = parts[16] == "1"
      parsed.noDefenseAttack = parts[17] == "1"
    else
      parsed.attackerCritOff = nil
      parsed.attackerCritDef = nil
      parsed.mobName = parts[9] or ""
      parsed.isBehindAttack = parts[10] == "1"
      parsed.attackerCritOffFailure = 0
      parsed.comboWithRequestId = parts[11] or ""
      parsed.comboWithSender = parts[12] or ""
      parsed.noDodgeAttack = false
      parsed.noDefenseAttack = false
    end
    return parsed
  end

  if msgType == Protocol.TYPES.MJ_MOB_SYNC_RESET then
    local hasVersion = parts[2] == "1"
    parsed.version = hasVersion and parts[2] or nil
    parsed.syncId = hasVersion and parts[3] or parts[2]
    parsed.sender = hasVersion and parts[4] or parts[3]
    parsed.timestamp = tonumber(hasVersion and parts[5] or parts[4])
    parsed.activeMobId = tonumber(hasVersion and parts[6] or parts[5])
    parsed.expectedCount = tonumber(hasVersion and parts[7] or parts[6]) or 0
    return parsed
  end

  if msgType == Protocol.TYPES.MJ_MOB_SYNC_ENTRY then
    local hasVersion = parts[2] == "1"
    parsed.version = hasVersion and parts[2] or nil
    parsed.syncId = hasVersion and parts[3] or parts[2]
    parsed.sender = hasVersion and parts[4] or parts[3]
    parsed.mobId = tonumber(hasVersion and parts[5] or parts[4])
    parsed.mobName = (hasVersion and parts[6] or parts[5]) or ""
    parsed.isSupport = (hasVersion and parts[7] or parts[6]) == "1"
    parsed.isActive = (hasVersion and parts[8] or parts[7]) == "1"
    return parsed
  end

  if msgType == Protocol.TYPES.MJ_MOB_SYNC_DONE then
    local hasVersion = parts[2] == "1"
    parsed.version = hasVersion and parts[2] or nil
    parsed.syncId = hasVersion and parts[3] or parts[2]
    parsed.sender = hasVersion and parts[4] or parts[3]
    parsed.timestamp = tonumber(hasVersion and parts[5] or parts[4])
    parsed.receivedCount = tonumber(hasVersion and parts[6] or parts[5]) or 0
    return parsed
  end

  if msgType == Protocol.TYPES.MJ_ATTACK_RESOLVE then
    parsed.requestId = parts[2]
    parsed.sender = parts[3]
    parsed.resultText = parts[4]
    parsed.timestamp = tonumber(parts[5])
    return parsed
  end

  if msgType == Protocol.TYPES.MJ_COMBAT_BANNER then
    parsed.version = parts[2]
    parsed.action = parts[3] or ""
    parsed.sender = parts[4] or ""
    parsed.round = tonumber(parts[5]) or 1
    parsed.side = parts[6] or "enemy"
    parsed.timestamp = tonumber(parts[7])
    parsed.playStartSound = parts[8] == "1"
    parsed.turnDuration = math.max(1, math.floor(tonumber(parts[9]) or 6))
    return parsed
  end

  if msgType == Protocol.TYPES.MJ_COMBAT_PLAYERS_SYNC then
    parsed.version = parts[2]
    parsed.sender = parts[3]
    parsed.round = tonumber(parts[4])
    parsed.side = parts[5]
    parsed.playersCsv = parts[6] or ""
    parsed.timestamp = tonumber(parts[7])
    return parsed
  end

  if msgType == Protocol.TYPES.MJ_PLAYER_TURN_PLAYED then
    parsed.version = parts[2]
    parsed.playerName = parts[3]
    parsed.round = tonumber(parts[4])
    parsed.side = parts[5]
    parsed.timestamp = tonumber(parts[6])
    return parsed
  end

  if msgType == Protocol.TYPES.MJ_PLAYER_MOVEMENT then
    parsed.version = parts[2]
    parsed.playerName = parts[3]
    parsed.round = tonumber(parts[4])
    parsed.side = parts[5]
    parsed.remainingPercent = tonumber(parts[6]) or 0
    parsed.budgetPercent = tonumber(parts[7]) or 100
    parsed.rolled = parts[8] == "1"
    parsed.exceeded = parts[9] == "1"
    parsed.timestamp = tonumber(parts[10])
    return parsed
  end

  if msgType == Protocol.TYPES.MJ_PLAYER_MOVEMENT_ALERT then
    parsed.version = parts[2]
    parsed.playerName = parts[3]
    parsed.round = tonumber(parts[4])
    parsed.side = parts[5]
    parsed.movedPercent = tonumber(parts[6]) or 0
    parsed.budgetPercent = tonumber(parts[7]) or 100
    parsed.timestamp = tonumber(parts[8])
    return parsed
  end

  if msgType == Protocol.TYPES.MJ_RAND_TURN_ALERT then
    parsed.version = parts[2]
    parsed.approvalId = parts[3]
    parsed.sender = parts[4]
    parsed.randName = parts[5]
    parsed.min = tonumber(parts[6])
    parsed.max = tonumber(parts[7])
    parsed.randRole = parts[8]
    parsed.timestamp = tonumber(parts[9])
    return parsed
  end

  if msgType == Protocol.TYPES.MJ_RAND_TURN_DECISION then
    parsed.version = parts[2]
    parsed.approvalId = parts[3]
    parsed.mjName = parts[4]
    parsed.approved = parts[5] == "1"
    parsed.timestamp = tonumber(parts[6])
    return parsed
  end

  return parsed
end
