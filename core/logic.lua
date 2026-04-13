local Core = _G.EasySanaluneCore or {}
_G.EasySanaluneCore = Core
local Text = Core.Text or {}

local BASIC_SECTION_NAME = "Fiche basique"

local function trim(text)
  if Text.trim then
    return Text.trim(text)
  end
  local raw = tostring(text or "")
  raw = string.gsub(raw, "^%s+", "")
  raw = string.gsub(raw, "%s+$", "")
  return raw
end

local function sanitize_single_line(text)
  if Text.sanitize_single_line then
    return Text.sanitize_single_line(text)
  end
  local raw = tostring(text or "")
  raw = string.gsub(raw, "[\r\n]", " ")
  return raw
end

local function infer_rand_role_from_name(value)
  local raw = tostring(value or "")
  if Text.normalize_name then
    raw = Text.normalize_name(raw)
  else
    raw = string.lower(trim(raw))
    raw = string.gsub(raw, "[éèêë]", "e")
    raw = string.gsub(raw, "[àâä]", "a")
    raw = string.gsub(raw, "[îï]", "i")
    raw = string.gsub(raw, "[ôö]", "o")
    raw = string.gsub(raw, "[ùûü]", "u")
    raw = string.gsub(raw, "[^%w%s]", "")
    raw = string.gsub(raw, "%s+", " ")
    raw = trim(raw)
  end

  if raw == "soutien" or raw == "support" then
    return "support"
  end
  if raw == "defense physique" or raw == "defense magique" or raw == "esquive" or raw == "dodge" then
    return "defensive"
  end
  return "offensive"
end

local function normalize_rand_role(value, nameFallback)
  local key = string.lower(trim(tostring(value or "")))
  if key == "offensive" or key == "support" or key == "defensive" then
    return key
  end
  return infer_rand_role_from_name(nameFallback)
end

local function is_non_negative_integer(value)
  return value and value >= 0 and math.floor(value) == value
end

function Core.copy_outcomes(outcomes)
  local copied = {}
  if type(outcomes) ~= "table" then
    return copied
  end

  for k, v in pairs(outcomes) do
    local idx = tonumber(k)
    if is_non_negative_integer(idx) then
      local text = sanitize_single_line(v)
      if text ~= "" then
        local safeIdx = idx
        if safeIdx ~= nil then
          copied[safeIdx] = text
        end
      end
    end
  end

  return copied
end

function Core.copy_outcome_ranges(ranges)
  local copied = {}
  if type(ranges) ~= "table" then
    return copied
  end

  for i = 1, #ranges do
    local entry = ranges[i]
    if type(entry) == "table" then
      local minVal = tonumber(entry.min)
      local maxVal = tonumber(entry.max)
      local text = sanitize_single_line(entry.text)
      if is_non_negative_integer(minVal) and is_non_negative_integer(maxVal) and text ~= "" then
        if minVal > maxVal then
          minVal, maxVal = maxVal, minVal
        end
        table.insert(copied, { min = minVal, max = maxVal, text = text })
      end
    end
  end

  return copied
end

function Core.parse_outcome_selector(input)
  local raw = trim(input)
  if raw == "" then
    return nil, nil, nil
  end

  local single = tonumber(raw)
  if is_non_negative_integer(single) then
    return single, single, "single"
  end

  local minVal, maxVal = string.match(raw, "^(%d+)%s*%-%s*(%d+)$")
  minVal = tonumber(minVal)
  maxVal = tonumber(maxVal)
  if is_non_negative_integer(minVal) and is_non_negative_integer(maxVal) then
    if minVal > maxVal then
      minVal, maxVal = maxVal, minVal
    end
    return minVal, maxVal, "range"
  end

  return nil, nil, nil
end

function Core.parse_command(input)
  local raw = tostring(input or "")
  raw = string.gsub(raw, "|c%x%x%x%x%x%x%x%x", "")
  raw = string.gsub(raw, "|r", "")
  raw = string.gsub(raw, "–", "-")
  raw = string.gsub(raw, "—", "-")
  raw = string.gsub(raw, "−", "-")
  raw = string.gsub(raw, "‐", "-")
  raw = string.gsub(raw, "‑", "-")
  raw = string.gsub(raw, "‒", "-")
  raw = string.gsub(raw, "﹣", "-")
  raw = string.gsub(raw, "－", "-")

  local min, max = string.match(raw, "^%s*(%d+)%s*%-%s*(%d+)%s*$")
  if not min or not max then
    min, max = string.match(string.lower(raw), "^%s*/?rand%s+(%d+)%s+(%d+)%s*$")
  end
  if not min or not max then
    min, max = string.match(raw, "^%D*(%d+)%D+(%d+)%D*$")
  end
  if min and max then
    min = tonumber(min)
    max = tonumber(max)
    if is_non_negative_integer(min) and is_non_negative_integer(max) then
      if min > max then
        min, max = max, min
      end
      return min, max, 0
    end
  end
  return nil, nil, nil
end

local function normalize_entry(entry)
  if not entry then
    return
  end

  if entry.type == "section" then
    if entry.expanded == nil then
      entry.expanded = true
    end
    if type(entry.items) ~= "table" then
      entry.items = {}
    end
    for i = 1, #entry.items do
      local item = entry.items[i]
      if item then
        if item.type == "section" then
          item.type = "rand"
          item.items = nil
          item.expanded = nil
        elseif item.type == nil then
          item.type = "rand"
        end
      end
    end
  else
    if entry.type == nil then
      entry.type = "rand"
    end
    entry.rand_role = normalize_rand_role(entry.rand_role, entry.name)
    if entry.icon ~= nil then
      local iconType = type(entry.icon)
      if iconType ~= "string" and iconType ~= "number" then
        entry.icon = nil
      elseif iconType == "string" and entry.icon == "" then
        entry.icon = nil
      end
    end
    entry.outcomes = Core.copy_outcomes(entry.outcomes)
    entry.outcome_ranges = Core.copy_outcome_ranges(entry.outcome_ranges)
  end
end

local function rand_key(entry)
  local name = tostring(entry and entry.name or "")
  local info = tostring(entry and entry.info or "")
  local command = tostring(entry and entry.command or "")
  return name .. "|" .. info .. "|" .. command
end

local function ensure_basic_section(chars)
  local basicSection = nil
  local basicIndex = nil
  local duplicateIndexes = {}

  for i = 1, #chars do
    local entry = chars[i]
    if entry and entry.type == "section" and (entry.is_fixed or trim(entry.name) == BASIC_SECTION_NAME) then
      if not basicSection then
        basicSection = entry
        basicIndex = i
      else
        if type(basicSection.items) ~= "table" then
          basicSection.items = {}
        end
        if type(entry.items) == "table" then
          for j = 1, #entry.items do
            basicSection.items[#basicSection.items + 1] = entry.items[j]
          end
        end
        duplicateIndexes[#duplicateIndexes + 1] = i
      end
    end
  end

  for i = #duplicateIndexes, 1, -1 do
    table.remove(chars, duplicateIndexes[i])
  end

  if not basicSection then
    basicSection = {
      type = "section",
      name = BASIC_SECTION_NAME,
      is_fixed = true,
      expanded = true,
      items = {},
    }
    table.insert(chars, 1, basicSection)
    return basicSection
  end

  basicSection.type = "section"
  basicSection.name = BASIC_SECTION_NAME
  basicSection.is_fixed = true
  if basicSection.expanded == nil then
    basicSection.expanded = true
  end
  if type(basicSection.items) ~= "table" then
    basicSection.items = {}
  end

  if basicIndex and basicIndex ~= 1 then
    table.remove(chars, basicIndex)
    table.insert(chars, 1, basicSection)
  end

  return basicSection
end

function Core.normalize_chars(chars)
  if type(chars) ~= "table" then
    return
  end

  for i = 1, #chars do
    normalize_entry(chars[i])
  end

  local basicSection = ensure_basic_section(chars)
  local seenDefaults = {}

  for i = 1, #basicSection.items do
    local item = basicSection.items[i]
    if item and item.is_default then
      seenDefaults[rand_key(item)] = true
    end
  end

  local i = #chars
  while i >= 1 do
    local entry = chars[i]
    if entry ~= basicSection then
      if entry and entry.type == "rand" and entry.is_default then
        local key = rand_key(entry)
        if not seenDefaults[key] then
          table.insert(basicSection.items, entry)
          seenDefaults[key] = true
        end
        table.remove(chars, i)
      elseif entry and entry.type == "section" and type(entry.items) == "table" then
        local j = #entry.items
        while j >= 1 do
          local item = entry.items[j]
          if item and item.type ~= "section" and item.is_default then
            local key = rand_key(item)
            if not seenDefaults[key] then
              table.insert(basicSection.items, item)
              seenDefaults[key] = true
            end
            table.remove(entry.items, j)
          end
          j = j - 1
        end
      end
    end
    i = i - 1
  end
end

function Core.deep_clone_chars(list)
  local copy = {}
  if not list then
    return copy
  end

  for i = 1, #list do
    local c = list[i]
    if c then
      if c.type == "section" then
        copy[i] = {
          type = "section",
          name = c.name,
          is_fixed = c.is_fixed,
          expanded = c.expanded,
          items = Core.deep_clone_chars(c.items or {}),
        }
      else
        copy[i] = {
          type = "rand",
          name = c.name,
          info = c.info,
          command = c.command,
          rand_role = c.rand_role,
          icon = c.icon,
          is_default = c.is_default,
          outcomes = Core.copy_outcomes(c.outcomes),
          outcome_ranges = Core.copy_outcome_ranges(c.outcome_ranges),
        }
      end
    end
  end

  return copy
end

local function deep_copy(value)
  if type(value) ~= "table" then
    return value
  end

  local result = {}
  for k, v in pairs(value) do
    result[deep_copy(k)] = deep_copy(v)
  end
  return result
end

local function copy_buffs(list)
  local copy = {}
  if type(list) ~= "table" then
    return copy
  end

  local function copy_entry(entry)
    if type(entry) ~= "table" then
      return nil
    end

    if entry.type == "section" then
      local section = {
        type = "section",
        name = sanitize_single_line(entry.name or ""),
        is_fixed = entry.is_fixed and true or false,
        expanded = entry.expanded ~= false,
        items = copy_buffs(entry.items or {}),
      }
      return section
    end

    return {
      title = sanitize_single_line(entry.title or ""),
      stat = sanitize_single_line(entry.stat or ""),
      stats = type(entry.stats) == "table" and deep_copy(entry.stats) or nil,
      value = tonumber(entry.value) or 0,
      values = type(entry.values) == "table" and deep_copy(entry.values) or nil,
      active = entry.active and true or false,
    }
  end

  for i = 1, #list do
    local copied = copy_entry(list[i])
    if copied then
      copy[#copy + 1] = copied
    end
  end

  return copy
end

local DEFAULT_SURVIVAL_HIT_POINTS = 5
local MIN_SURVIVAL_HIT_POINTS = -2
local DEFAULT_SURVIVAL_ARMOR_TYPE = "nue"
local DEFAULT_SURVIVAL_DURABILITY_MAX = 5

local CLASSIC_ARMOR_RULES = {
  nue = { rda = 0, rda_crit = 0, degraded = "nue", durability_max = 5 },
  legere = { rda = 1, rda_crit = 0, degraded = "nue", durability_max = 5 },
  intermediaire = { rda = 1, rda_crit = 1, degraded = "legere", durability_max = 3 },
  lourde = { rda = 2, rda_crit = 0, degraded = "intermediaire", durability_max = 5 },
}

local function clamp_integer(value, defaultValue, minValue, maxValue)
  local numericValue = tonumber(value)
  if numericValue == nil then
    numericValue = defaultValue
  end
  numericValue = math.floor(tonumber(numericValue) or tonumber(defaultValue) or 0)
  if minValue ~= nil and numericValue < minValue then
    numericValue = minValue
  end
  if maxValue ~= nil and numericValue > maxValue then
    numericValue = maxValue
  end
  return numericValue
end

function Core.normalize_armor_type(value)
  local raw = tostring(value or "")
  raw = string.gsub(raw, "^%s+", "")
  raw = string.gsub(raw, "%s+$", "")
  raw = string.lower(raw)
  raw = string.gsub(raw, "[éèêë]", "e")

  if raw == "" or raw == "nue" or raw == "nu" then
    return "nue"
  end
  if raw == "legere" or raw == "leger" or raw == "light" then
    return "legere"
  end
  if raw == "intermediaire" or raw == "intermediare" or raw == "medium" then
    return "intermediaire"
  end
  if raw == "lourde" or raw == "heavy" then
    return "lourde"
  end
  if raw == "special" or raw == "speciale" or raw == "speciales" then
    return "special"
  end

  return DEFAULT_SURVIVAL_ARMOR_TYPE
end

function Core.parse_durability_input(value, fallbackCurrent, fallbackMax, fallbackInfinite)
  local raw = trim(value)
  if raw == "" then
    return fallbackCurrent, fallbackMax, fallbackInfinite and true or false, true
  end

  local lowered = string.lower(raw)
  lowered = string.gsub(lowered, "[éèêë]", "e")
  if raw == "∞" or lowered == "inf" or lowered == "infinite" or lowered == "infini" then
    return nil, nil, true, true
  end

  local currentText, maxText = string.match(raw, "^(%-?%d+)%s*/%s*(%-?%d+)$")
  local currentValue = tonumber(currentText)
  local maxValue = tonumber(maxText)
  if currentValue and maxValue then
    maxValue = math.floor(maxValue)
    currentValue = math.floor(currentValue)
    if maxValue < 1 then
      return nil, nil, false, false
    end
    if currentValue < 0 then
      currentValue = 0
    elseif currentValue > maxValue then
      currentValue = maxValue
    end
    return currentValue, maxValue, false, true
  end

  return nil, nil, false, false
end

function Core.normalize_survival_data(entity)
  if type(entity) ~= "table" then
    return entity
  end

  entity.hit_points = clamp_integer(entity.hit_points, DEFAULT_SURVIVAL_HIT_POINTS, MIN_SURVIVAL_HIT_POINTS, nil)

  local armorType = Core.normalize_armor_type(entity.armor_type)
  entity.armor_type = armorType

  if armorType == "special" then
    local isInfinite = entity.durability_infinite and true or false
    entity.durability_infinite = isInfinite

    if isInfinite then
      entity.durability_current = nil
      entity.durability_max = nil
    else
      local durabilityMax = clamp_integer(entity.durability_max, DEFAULT_SURVIVAL_DURABILITY_MAX, 1, nil)
      local durabilityCurrent = clamp_integer(entity.durability_current, durabilityMax, 0, durabilityMax)
      entity.durability_max = durabilityMax
      entity.durability_current = durabilityCurrent
    end

    entity.rda = clamp_integer(entity.rda, 0, 0, nil)
    entity.rda_crit = clamp_integer(entity.rda_crit, 0, 0, nil)
    return entity
  end

  if armorType == "nue" then
    entity.durability_infinite = false
    entity.durability_current = nil
    entity.durability_max = nil
    entity.rda = 0
    entity.rda_crit = 0
    return entity
  end

  entity.durability_infinite = false

  local rules = CLASSIC_ARMOR_RULES[armorType] or CLASSIC_ARMOR_RULES[DEFAULT_SURVIVAL_ARMOR_TYPE]
  local durabilityMax = tonumber(rules.durability_max) or DEFAULT_SURVIVAL_DURABILITY_MAX
  entity.durability_max = durabilityMax

  local durabilityCurrent = clamp_integer(
    entity.durability_current,
    durabilityMax,
    0,
    durabilityMax
  )
  if durabilityCurrent <= 0 then
    armorType = rules.degraded or DEFAULT_SURVIVAL_ARMOR_TYPE
    entity.armor_type = armorType
    rules = CLASSIC_ARMOR_RULES[armorType] or CLASSIC_ARMOR_RULES[DEFAULT_SURVIVAL_ARMOR_TYPE]
    durabilityMax = tonumber(rules.durability_max) or DEFAULT_SURVIVAL_DURABILITY_MAX
    entity.durability_max = durabilityMax
    durabilityCurrent = durabilityMax
  end

  entity.durability_current = durabilityCurrent
  entity.rda = rules.rda
  entity.rda_crit = rules.rda_crit
  return entity
end

function Core.get_survival_snapshot(source)
  local snapshot = {}
  if type(source) == "table" then
    snapshot.hit_points = source.hit_points
    snapshot.armor_type = source.armor_type
    snapshot.durability_current = source.durability_current
    snapshot.durability_max = source.durability_max
    snapshot.durability_infinite = source.durability_infinite
    snapshot.rda = source.rda
    snapshot.rda_crit = source.rda_crit
  end
  return Core.normalize_survival_data(snapshot)
end

function Core.format_durability_text(source)
  local snapshot = Core.get_survival_snapshot(source)
  if Core.normalize_armor_type(snapshot.armor_type) == "nue" then
    return "-"
  end
  if snapshot.durability_infinite then
    return "infini"
  end
  return string.format(
    "%d / %d",
    tonumber(snapshot.durability_current) or 0,
    tonumber(snapshot.durability_max) or DEFAULT_SURVIVAL_DURABILITY_MAX
  )
end

function Core.apply_durability_loss(entity, amount)
  if type(entity) ~= "table" then
    return {
      degraded = false,
      armor_type = DEFAULT_SURVIVAL_ARMOR_TYPE,
      durability_current = DEFAULT_SURVIVAL_DURABILITY_MAX,
      durability_max = DEFAULT_SURVIVAL_DURABILITY_MAX,
      durability_infinite = false,
      rda = 0,
      rda_crit = 0,
    }
  end

  Core.normalize_survival_data(entity)

  local loss = clamp_integer(amount, 0, 0, nil)
  local previousArmorType = entity.armor_type

  if loss > 0 and not entity.durability_infinite then
    if entity.armor_type == "special" then
      local durabilityCurrent = clamp_integer(entity.durability_current, DEFAULT_SURVIVAL_DURABILITY_MAX, 0, nil)
      entity.durability_current = math.max(0, durabilityCurrent - loss)
    else
      local durabilityCurrent = clamp_integer(
        entity.durability_current,
        DEFAULT_SURVIVAL_DURABILITY_MAX,
        0,
        DEFAULT_SURVIVAL_DURABILITY_MAX
      )
      entity.durability_current = durabilityCurrent - loss
    end
    Core.normalize_survival_data(entity)
  end

  return {
    degraded = previousArmorType ~= entity.armor_type,
    armor_type = entity.armor_type,
    durability_current = entity.durability_current,
    durability_max = entity.durability_max,
    durability_infinite = entity.durability_infinite,
    rda = entity.rda,
    rda_crit = entity.rda_crit,
  }
end

function Core.prepare_state(savedState, defaultState)
  local DEFAULT_CRIT_THRESHOLD = 70
  local DEFAULT_DODGE_BACK_PERCENT = 50
  local DEFAULT_HIT_POINTS = 5
  local DEFAULT_ARMOR_TYPE = "nue"
  local state

  if type(savedState) == "table" and savedState.pos_x ~= nil then
    state = savedState
  else
    state = deep_copy(defaultState or {})
  end

  if state.profile_mode == nil then
    state.profile_mode = state.mj_mode and true or false
  end
  if state.mj_mode ~= nil then
    state.mj_mode = nil
  end

  if state.mj_enabled == nil then
    state.mj_enabled = false
  end
  if state.resolution_private_print == nil then
    state.resolution_private_print = true
  end
  if type(state.mj_mobs) ~= "table" then
    state.mj_mobs = {}
  end
  for mobId, mob in pairs(state.mj_mobs) do
    if type(mob) ~= "table" then
      state.mj_mobs[mobId] = nil
    else
      local dodgeBackPercent = tonumber(mob.dodge_back_percent)
      if dodgeBackPercent == nil then
        mob.dodge_back_percent = 50
      else
        dodgeBackPercent = math.floor(dodgeBackPercent)
        if dodgeBackPercent < 0 then
          dodgeBackPercent = 0
        elseif dodgeBackPercent > 100 then
          dodgeBackPercent = 100
        end
        mob.dodge_back_percent = dodgeBackPercent
      end

      local critOffFailureVisual = tonumber(mob.crit_off_failure_visual)
      if critOffFailureVisual == nil then
        mob.crit_off_failure_visual = 0
      else
        critOffFailureVisual = math.floor(critOffFailureVisual)
        if critOffFailureVisual < 0 then
          critOffFailureVisual = 0
        end
        mob.crit_off_failure_visual = critOffFailureVisual
      end

      local critDefFailureVisual = tonumber(mob.crit_def_failure_visual)
      if critDefFailureVisual == nil then
        mob.crit_def_failure_visual = 0
      else
        critDefFailureVisual = math.floor(critDefFailureVisual)
        if critDefFailureVisual < 0 then
          critDefFailureVisual = 0
        end
        mob.crit_def_failure_visual = critDefFailureVisual
      end

      Core.normalize_survival_data(mob)
    end
  end
  if state.mj_active_mob_id == nil then
    state.mj_active_mob_id = nil
  end
  if type(state.mj_player_targets) ~= "table" then
    state.mj_player_targets = {}
  end
  do
    local cleanTargets = {}
    local seenTargets = {}
    for i = 1, #state.mj_player_targets do
      local name = tostring(state.mj_player_targets[i] or "")
      name = string.gsub(name, "^%s+", "")
      name = string.gsub(name, "%s+$", "")
      if name ~= "" then
        local key = string.lower(name)
        if not seenTargets[key] then
          seenTargets[key] = true
          cleanTargets[#cleanTargets + 1] = name
        end
      end
    end
    state.mj_player_targets = cleanTargets

    local selectedTarget = tostring(state.mj_selected_target or "")
    selectedTarget = string.gsub(selectedTarget, "^%s+", "")
    selectedTarget = string.gsub(selectedTarget, "%s+$", "")
    if selectedTarget == "" then
      state.mj_selected_target = cleanTargets[1]
    else
      local found = false
      local selectedKey = string.lower(selectedTarget)
      for i = 1, #cleanTargets do
        if string.lower(cleanTargets[i]) == selectedKey then
          found = true
          break
        end
      end
      state.mj_selected_target = found and selectedTarget or cleanTargets[1]
    end
  end

  local playerName = UnitName("player") or "Profil 1"
  if state.profiles == nil then
    state.profiles = { playerName }
  end
  if type(state.profiles) ~= "table" then
    state.profiles = { playerName }
  end
  if #state.profiles < 1 then
    state.profiles = { playerName }
  end
  if state.profiles[1] == "Profil 1" then
    state.profiles[1] = playerName
  end
  if tostring(state.profiles[1] or "") == "" then
    state.profiles[1] = playerName
  end
  if state.profile_index == nil or state.profile_index < 1 then
    state.profile_index = 1
  end
  if state.profile_index > #state.profiles then
    state.profile_index = #state.profiles
  end

  if state.profile_chars == nil then
    state.profile_chars = {}
  end
  if state.profile_chars[state.profile_index] == nil then
    if type(state.CHARS) == "table" then
      state.profile_chars[state.profile_index] = state.CHARS
    elseif defaultState and defaultState.CHARS then
      state.profile_chars[state.profile_index] = Core.deep_clone_chars(defaultState.CHARS)
    else
      state.profile_chars[state.profile_index] = {}
    end
  end
  state.CHARS = state.profile_chars[state.profile_index]

  if state.profile_buffs == nil then
    state.profile_buffs = {}
  end
  if type(state.profile_buffs) ~= "table" then
    state.profile_buffs = {}
  end
  if state.profile_buffs[state.profile_index] == nil then
    if type(state.buffs) == "table" then
      state.profile_buffs[state.profile_index] = copy_buffs(state.buffs)
    elseif defaultState and type(defaultState.buffs) == "table" then
      state.profile_buffs[state.profile_index] = copy_buffs(defaultState.buffs)
    else
      state.profile_buffs[state.profile_index] = {}
    end
  end
  state.profile_buffs[state.profile_index] = copy_buffs(state.profile_buffs[state.profile_index])
  state.buffs = state.profile_buffs[state.profile_index]

  -- Buff window visibility is transient UI state: always start closed after reload.
  state.buffs_visible = false
  if state.buff_dim_w == nil then
    state.buff_dim_w = 280
  end
  if state.buff_dim_h == nil then
    state.buff_dim_h = 320
  end

  if state.profile_crit_off_success == nil then
    state.profile_crit_off_success = {}
  end
  if state.profile_crit_def_success == nil then
    state.profile_crit_def_success = {}
  end
  if state.profile_crit_off_failure_visual == nil then
    state.profile_crit_off_failure_visual = {}
  end
  if state.profile_crit_def_failure_visual == nil then
    state.profile_crit_def_failure_visual = {}
  end
  if state.profile_dodge_back_percent == nil then
    state.profile_dodge_back_percent = {}
  end
  if state.profile_hit_points == nil then
    state.profile_hit_points = {}
  end
  if state.profile_armor_type == nil then
    state.profile_armor_type = {}
  end
  if state.profile_durability_current == nil then
    state.profile_durability_current = {}
  end
  if state.profile_durability_max == nil then
    state.profile_durability_max = {}
  end
  if state.profile_durability_infinite == nil then
    state.profile_durability_infinite = {}
  end
  if state.profile_rda == nil then
    state.profile_rda = {}
  end
  if state.profile_rda_crit == nil then
    state.profile_rda_crit = {}
  end

  if state.profile_crit_off_success[state.profile_index] == nil and state.crit_off_success ~= nil then
    state.profile_crit_off_success[state.profile_index] = state.crit_off_success
  end
  if state.profile_crit_def_success[state.profile_index] == nil and state.crit_def_success ~= nil then
    state.profile_crit_def_success[state.profile_index] = state.crit_def_success
  end
  if state.profile_crit_off_failure_visual[state.profile_index] == nil and state.crit_off_failure_visual ~= nil then
    state.profile_crit_off_failure_visual[state.profile_index] = tonumber(state.crit_off_failure_visual) or 0
  end
  if state.profile_crit_def_failure_visual[state.profile_index] == nil and state.crit_def_failure_visual ~= nil then
    state.profile_crit_def_failure_visual[state.profile_index] = tonumber(state.crit_def_failure_visual) or 0
  end
  if state.profile_dodge_back_percent[state.profile_index] == nil and state.dodge_back_percent ~= nil then
    state.profile_dodge_back_percent[state.profile_index] =
      tonumber(state.dodge_back_percent) or DEFAULT_DODGE_BACK_PERCENT
  end
  if state.profile_hit_points[state.profile_index] == nil and state.hit_points ~= nil then
    state.profile_hit_points[state.profile_index] = tonumber(state.hit_points) or DEFAULT_HIT_POINTS
  end
  if state.profile_armor_type[state.profile_index] == nil and state.armor_type ~= nil then
    state.profile_armor_type[state.profile_index] = tostring(state.armor_type)
  end
  if state.profile_durability_current[state.profile_index] == nil and state.durability_current ~= nil then
    state.profile_durability_current[state.profile_index] =
      tonumber(state.durability_current) or DEFAULT_SURVIVAL_DURABILITY_MAX
  end
  if state.profile_durability_max[state.profile_index] == nil and state.durability_max ~= nil then
    state.profile_durability_max[state.profile_index] =
      tonumber(state.durability_max) or DEFAULT_SURVIVAL_DURABILITY_MAX
  end
  if state.profile_durability_infinite[state.profile_index] == nil and state.durability_infinite ~= nil then
    state.profile_durability_infinite[state.profile_index] = state.durability_infinite and true or false
  end
  if state.profile_rda[state.profile_index] == nil and state.rda ~= nil then
    state.profile_rda[state.profile_index] = tonumber(state.rda) or 0
  end
  if state.profile_rda_crit[state.profile_index] == nil and state.rda_crit ~= nil then
    state.profile_rda_crit[state.profile_index] = tonumber(state.rda_crit) or 0
  end

  if state.profile_crit_off_success[state.profile_index] == nil then
    state.profile_crit_off_success[state.profile_index] = DEFAULT_CRIT_THRESHOLD
  end
  if state.profile_crit_def_success[state.profile_index] == nil then
    state.profile_crit_def_success[state.profile_index] = DEFAULT_CRIT_THRESHOLD
  end
  if state.profile_crit_off_failure_visual[state.profile_index] == nil then
    state.profile_crit_off_failure_visual[state.profile_index] = 0
  end
  if state.profile_crit_def_failure_visual[state.profile_index] == nil then
    state.profile_crit_def_failure_visual[state.profile_index] = 0
  end
  if state.profile_dodge_back_percent[state.profile_index] == nil then
    state.profile_dodge_back_percent[state.profile_index] = DEFAULT_DODGE_BACK_PERCENT
  end
  if state.profile_hit_points[state.profile_index] == nil then
    state.profile_hit_points[state.profile_index] = DEFAULT_HIT_POINTS
  end
  if state.profile_armor_type[state.profile_index] == nil
    or tostring(state.profile_armor_type[state.profile_index]) == "" then
    state.profile_armor_type[state.profile_index] = DEFAULT_ARMOR_TYPE
  end
  if state.profile_durability_current[state.profile_index] == nil then
    state.profile_durability_current[state.profile_index] = DEFAULT_SURVIVAL_DURABILITY_MAX
  end
  if state.profile_durability_max[state.profile_index] == nil then
    state.profile_durability_max[state.profile_index] = DEFAULT_SURVIVAL_DURABILITY_MAX
  end
  if state.profile_durability_infinite[state.profile_index] == nil then
    state.profile_durability_infinite[state.profile_index] = false
  end
  if state.profile_rda[state.profile_index] == nil then
    state.profile_rda[state.profile_index] = 0
  end
  if state.profile_rda_crit[state.profile_index] == nil then
    state.profile_rda_crit[state.profile_index] = 0
  end

  state.crit_off_success = state.profile_crit_off_success[state.profile_index]
  state.crit_def_success = state.profile_crit_def_success[state.profile_index]
  state.crit_off_failure_visual = tonumber(state.profile_crit_off_failure_visual[state.profile_index]) or 0
  state.crit_def_failure_visual = tonumber(state.profile_crit_def_failure_visual[state.profile_index]) or 0
  state.dodge_back_percent =
    tonumber(state.profile_dodge_back_percent[state.profile_index]) or DEFAULT_DODGE_BACK_PERCENT
  state.hit_points = tonumber(state.profile_hit_points[state.profile_index]) or DEFAULT_HIT_POINTS
  state.armor_type = tostring(state.profile_armor_type[state.profile_index] or DEFAULT_ARMOR_TYPE)
  state.durability_current =
    tonumber(state.profile_durability_current[state.profile_index]) or DEFAULT_SURVIVAL_DURABILITY_MAX
  state.durability_max = tonumber(state.profile_durability_max[state.profile_index]) or DEFAULT_SURVIVAL_DURABILITY_MAX
  state.durability_infinite = state.profile_durability_infinite[state.profile_index] and true or false
  state.rda = tonumber(state.profile_rda[state.profile_index]) or 0
  state.rda_crit = tonumber(state.profile_rda_crit[state.profile_index]) or 0

  Core.normalize_survival_data(state)
  state.profile_hit_points[state.profile_index] = state.hit_points
  state.profile_armor_type[state.profile_index] = state.armor_type
  state.profile_durability_current[state.profile_index] = state.durability_current
  state.profile_durability_max[state.profile_index] = state.durability_max
  state.profile_durability_infinite[state.profile_index] = state.durability_infinite and true or false
  state.profile_rda[state.profile_index] = state.rda
  state.profile_rda_crit[state.profile_index] = state.rda_crit

  Core.normalize_chars(state.CHARS)

  return state
end
