local Core = _G.EasySanaluneCore or {}
_G.EasySanaluneCore = Core

Core.Resolution = Core.Resolution or {}
local Resolution = Core.Resolution

function Resolution.compute(attackRoll, defendRoll, critOff, critDef)
  local diff = attackRoll - defendRoll
  local hit = diff > 0
  local critCount = 0
  local defCritCount = 0
  local CRIT_CAP = 5

  if hit then
    if critOff and critOff > 0 then
      critCount = math.min(CRIT_CAP, math.floor(diff / critOff))
    end
  else
    local defDiff = -diff
    if critDef and critDef > 0 then
      defCritCount = math.min(CRIT_CAP, math.floor(defDiff / critDef))
    end
  end

  return hit, diff, critCount, defCritCount
end

function Resolution.extract_bonus_from_label(text)
  local raw = tostring(text or "")
  local bonus = string.match(raw, "%(([%+%-]%d+)%)")
  return tonumber(bonus) or 0
end

local function format_roll_segment(baseRoll, totalRoll)
  local baseValue = tonumber(baseRoll) or 0
  local totalValue = tonumber(totalRoll)
  if not totalValue or totalValue == baseValue then
    return tostring(baseRoll)
  end

  local bonus = totalValue - baseValue
  return string.format("%d (%+d) => %d", baseValue, bonus, totalValue)
end

function Resolution.format_text(attacker, mobName, attackRoll, defendRoll, attackTotal, defendTotal, hit, diff, critCount, defCritCount, attackReason, defenseReason)
  local result = hit and "TOUCHÉ" or "ÉCHOUÉ"
  local sign = diff > 0 and "+" or ""

  local atkSegment = format_roll_segment(attackRoll, attackTotal)
  local defSegment = format_roll_segment(defendRoll, defendTotal)

  local text = string.format(
    "Résolution: %s attaque %s : %s vs %s => %s (diff %s%d)",
    attacker,
    (mobName ~= "" and mobName or "Mob"),
    atkSegment,
    defSegment,
    result,
    sign,
    diff
  )

  if hit and critCount >= 1 then
    if critCount == 1 then
      text = text .. " => réussite critique"
    elseif critCount == 2 then
      text = text .. " => double réussite critique"
    elseif critCount == 3 then
      text = text .. " => triple réussite critique"
    else
      text = text .. " => réussite critique x" .. critCount
    end
  elseif not hit and defCritCount >= 1 then
    if defCritCount == 1 then
      text = text .. " => réussite défensive critique"
    elseif defCritCount == 2 then
      text = text .. " => double réussite défensive critique"
    elseif defCritCount == 3 then
      text = text .. " => triple réussite défensive critique"
    else
      text = text .. " => réussite défensive critique x" .. defCritCount
    end
  end

  local reasonSegments = {}
  local attackReasonText = tostring(attackReason or "")
  local defenseReasonText = tostring(defenseReason or "")
  if attackReasonText ~= "" then
    reasonSegments[#reasonSegments + 1] = attackReasonText
  end
  if defenseReasonText ~= "" then
    reasonSegments[#reasonSegments + 1] = defenseReasonText
  end
  if #reasonSegments > 0 then
    text = text .. " [" .. table.concat(reasonSegments, " | ") .. "]"
  end

  return text
end
