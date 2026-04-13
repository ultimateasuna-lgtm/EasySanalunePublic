local Core = _G.EasySanaluneCore or {}
_G.EasySanaluneCore = Core
local Text = Core.Text or {}

Core.MJ = Core.MJ or {}
local MJ = Core.MJ

local function trim(s)
  if Text.trim then
    return Text.trim(s)
  end
  return (tostring(s or "")):match("^%s*(.-)%s*$")
end

local function sanitize_single_line(value)
  if Text.sanitize_single_line then
    return Text.sanitize_single_line(value)
  end
  local raw = tostring(value or "")
  return string.gsub(raw, "[\r\n]", " ")
end

local function encode_export_field(value)
  local encoded = sanitize_single_line(value)
  encoded = string.gsub(encoded, ",", "{M}")
  encoded = string.gsub(encoded, ":", "{C}")
  return encoded
end

local function decode_export_field(value)
  local decoded = tostring(value or "")
  decoded = string.gsub(decoded, "{C}", ":")
  decoded = string.gsub(decoded, "{M}", ",")
  return decoded
end

local function split_export_fields(value)
  local fields = {}
  local raw = tostring(value or "") .. ":"
  for part in raw:gmatch("([^:]*)%:") do
    fields[#fields + 1] = decode_export_field(part)
  end
  return fields
end

local RAND_KEY_MATCH = {
  PHY_DEF = { "défense physique", "defense physique", "def phys", "déf phys" },
  MAG_DEF = { "défense magique", "defense magique", "def mag", "déf mag" },
  DODGE = { "esquive", "dodge" },
  ATK_PHY = { "attaque physique", "atk phy", "att phys" },
  ATK_MAG = { "attaque magique", "atk mag", "att mag" },
}

local DEFENSE_RAND_NAME_BY_TYPE = {
  PHY_DEF = "Défense physique",
  MAG_DEF = "Défense magique",
  DODGE = "Esquive",
}

function MJ.next_mob_id(state)
  local maxId = 0
  if type(state) == "table" and type(state.mj_mobs) == "table" then
    for id in pairs(state.mj_mobs) do
      local n = tonumber(id)
      if n and n > maxId then
        maxId = n
      end
    end
  end
  return maxId + 1
end

function MJ.deserialize_profile(text)
  if not text or trim(text) == "" then
    return nil
  end

  local lines = {}
  for line in text:gmatch("[^\n]+") do
    lines[#lines + 1] = line
  end
  if lines[1] ~= "EASYSANALUNE_EXPORT_V1" and lines[1] ~= "EASYSANALUNE_EXPORT_V2" then
    return nil
  end

  local result = {
    profileName = "",
    rands = {},
    chars = {},
    critOff = nil,
    critDef = nil,
    critOffFailureVisual = 0,
    critDefFailureVisual = 0,
    dodgeBackPercent = 50,
    hitPoints = 5,
    armorType = "nue",
    durabilityCurrent = 5,
    durabilityMax = 5,
    durabilityInfinite = false,
    rda = 0,
    rdaCrit = 0,
    buffs = {},
  }

  local currentCharSection = nil
  local currentCharEntry = nil
  local currentBuffSection = nil
  local currentBuffEntry = nil

  local function ensure_char_section()
    if currentCharSection then
      return currentCharSection
    end

    currentCharSection = {
      type = "section",
      name = "Fiche basique",
      is_fixed = true,
      expanded = true,
      items = {},
    }
    result.chars[#result.chars + 1] = currentCharSection
    return currentCharSection
  end

  local function ensure_buff_section()
    if currentBuffSection then
      return currentBuffSection
    end

    currentBuffSection = {
      type = "section",
      name = "Buffs",
      is_fixed = true,
      expanded = true,
      items = {},
    }
    result.buffs[#result.buffs + 1] = currentBuffSection
    return currentBuffSection
  end

  for i = 2, #lines do
    local line = lines[i]
    if line == "END" then
      break
    end
    local prefix, rest = line:match("^([%u_]+):(.*)")
    if prefix == "PROFILE" then
      result.profileName = decode_export_field(rest or "")
    elseif prefix == "CRIT_OFF" then
      result.critOff = tonumber(rest)
    elseif prefix == "CRIT_DEF" then
      result.critDef = tonumber(rest)
    elseif prefix == "CRIT_OFF_FAIL" then
      result.critOffFailureVisual = tonumber(rest) or 0
    elseif prefix == "CRIT_DEF_FAIL" then
      result.critDefFailureVisual = tonumber(rest) or 0
    elseif prefix == "DODGE_BACK" then
      result.dodgeBackPercent = tonumber(rest) or 50
    elseif prefix == "HIT_POINTS" then
      result.hitPoints = tonumber(rest) or 5
    elseif prefix == "ARMOR_TYPE" then
      result.armorType = trim(rest)
      if result.armorType == "" then
        result.armorType = "nue"
      end
    elseif prefix == "DURABILITY_CURRENT" then
      result.durabilityCurrent = tonumber(rest) or 5
    elseif prefix == "DURABILITY_MAX" then
      result.durabilityMax = tonumber(rest) or 5
    elseif prefix == "DURABILITY_INFINITE" then
      result.durabilityInfinite = tostring(rest or "0") == "1"
    elseif prefix == "RDA" then
      result.rda = tonumber(rest) or 0
    elseif prefix == "RDA_CRIT" then
      result.rdaCrit = tonumber(rest) or 0
    elseif prefix == "RAND" then
      local fields = split_export_fields(rest)
      local name = fields[1]
      local cmd = fields[2]
      if name and cmd then
        result.rands[#result.rands + 1] = {
          name = name,
          command = cmd,
        }
      end
    elseif prefix == "CHAR_SECTION" then
      local fields = split_export_fields(rest)
      currentCharSection = {
        type = "section",
        name = trim(fields[1] or "") ~= "" and tostring(fields[1]) or "Fiche basique",
        is_fixed = tostring(fields[2] or "0") == "1",
        expanded = tostring(fields[3] or "1") ~= "0",
        items = {},
      }
      result.chars[#result.chars + 1] = currentCharSection
      currentCharEntry = nil
    elseif prefix == "CHAR_RAND" then
      local fields = split_export_fields(rest)
      local name = trim(fields[1] or "")
      if name ~= "" then
        currentCharEntry = {
          type = "rand",
          name = name,
          command = tostring(fields[2] or ""),
          info = tostring(fields[3] or fields[2] or ""),
          rand_role = trim(fields[4] or ""),
          is_default = tostring(fields[5] or "0") == "1",
          icon = trim(fields[6] or ""),
        }
        if currentCharEntry.rand_role == "" then
          currentCharEntry.rand_role = nil
        end
        if currentCharEntry.icon == "" then
          currentCharEntry.icon = nil
        end
        ensure_char_section().items[#ensure_char_section().items + 1] = currentCharEntry
      else
        currentCharEntry = nil
      end
    elseif prefix == "CHAR_OUTCOME" then
      local fields = split_export_fields(rest)
      local rollValue = tonumber(fields[1])
      local outcomeText = tostring(fields[2] or "")
      if currentCharEntry and rollValue and outcomeText ~= "" then
        currentCharEntry.outcomes = currentCharEntry.outcomes or {}
        currentCharEntry.outcomes[rollValue] = outcomeText
      end
    elseif prefix == "CHAR_RANGE" then
      local fields = split_export_fields(rest)
      local minValue = tonumber(fields[1])
      local maxValue = tonumber(fields[2])
      local rangeText = tostring(fields[3] or "")
      if currentCharEntry and minValue and maxValue and rangeText ~= "" then
        currentCharEntry.outcome_ranges = currentCharEntry.outcome_ranges or {}
        currentCharEntry.outcome_ranges[#currentCharEntry.outcome_ranges + 1] = {
          min = minValue,
          max = maxValue,
          text = rangeText,
        }
      end
    elseif prefix == "BUFF_SECTION" then
      local fields = split_export_fields(rest)
      currentBuffSection = {
        type = "section",
        name = trim(fields[1] or "") ~= "" and tostring(fields[1]) or "Buffs",
        is_fixed = tostring(fields[2] or "0") == "1",
        expanded = tostring(fields[3] or "1") ~= "0",
        items = {},
      }
      result.buffs[#result.buffs + 1] = currentBuffSection
      currentBuffEntry = nil
    elseif prefix == "BUFF" then
      local fields = split_export_fields(rest)
      local stats = {}
      local rawStats = tostring(fields[5] or "")
      if rawStats ~= "" then
        for part in rawStats:gmatch("([^,]+)") do
          stats[#stats + 1] = decode_export_field(part)
        end
      end

      currentBuffEntry = {
        title = tostring(fields[1] or ""),
        stat = tostring(fields[2] or ""),
        stats = stats,
        value = tonumber(fields[3]) or 0,
        active = tostring(fields[4] or "1") ~= "0",
      }
      ensure_buff_section().items[#ensure_buff_section().items + 1] = currentBuffEntry
    elseif prefix == "BUFF_VALUE" then
      local fields = split_export_fields(rest)
      local key = tostring(fields[1] or "")
      if currentBuffEntry and key ~= "" then
        currentBuffEntry.values = currentBuffEntry.values or {}
        currentBuffEntry.values[key] = tonumber(fields[2]) or 0
      end
    end
  end

  return result
end

function MJ.import_parsed_profile_as_mob(state, parsed, fallbackName, fallbackNotes)
  if type(state) ~= "table" or type(parsed) ~= "table" then
    return nil
  end

  if type(state.mj_mobs) ~= "table" then
    state.mj_mobs = {}
  end

  local importedName = tostring(fallbackName or "Mob importé")
  if parsed.profileName and parsed.profileName ~= "" then
    importedName = parsed.profileName
  end

  local mob = {
    name = importedName,
    notes = tostring(fallbackNotes or "Importé"),
    rands = {
      PHY_DEF = "1-100",
      MAG_DEF = "1-100",
      DODGE = "1-100",
      ATK_PHY = "1-100",
      ATK_MAG = "1-100",
    },
    crit_off_success = parsed.critOff,
    crit_def_success = parsed.critDef,
    crit_off_failure_visual = tonumber(parsed.critOffFailureVisual) or 0,
    crit_def_failure_visual = tonumber(parsed.critDefFailureVisual) or 0,
    dodge_back_percent = tonumber(parsed.dodgeBackPercent) or 50,
    hit_points = tonumber(parsed.hitPoints) or 5,
    armor_type = tostring(parsed.armorType or "nue"),
    durability_current = tonumber(parsed.durabilityCurrent) or 5,
    durability_max = tonumber(parsed.durabilityMax) or 5,
    durability_infinite = parsed.durabilityInfinite and true or false,
    rda = tonumber(parsed.rda) or 0,
    rda_crit = tonumber(parsed.rdaCrit) or 0,
  }

  for _, r in ipairs(parsed.rands or {}) do
    local lower = tostring(r.name or ""):lower()
    for key, patterns in pairs(RAND_KEY_MATCH) do
      for _, pat in ipairs(patterns) do
        if lower:find(pat, 1, true) then
          mob.rands[key] = tostring(r.command or "1-100")
          break
        end
      end
    end
  end

  if Core and Core.normalize_survival_data then
    Core.normalize_survival_data(mob)
  end

  local newId = MJ.next_mob_id(state)
  state.mj_mobs[newId] = mob
  state.mj_active_mob_id = newId
  return newId
end

function MJ.serialize_profile(state)
  if type(state) ~= "table" then
    return ""
  end

  local profileName = ""
  if state.profiles and state.profile_index then
    profileName = tostring(state.profiles[state.profile_index] or "")
  end

  local lines = {
    "EASYSANALUNE_EXPORT_V2",
    "PROFILE:" .. encode_export_field(profileName),
    "CRIT_OFF:" .. tostring(state.crit_off_success or ""),
    "CRIT_DEF:" .. tostring(state.crit_def_success or ""),
    "CRIT_OFF_FAIL:" .. tostring(state.crit_off_failure_visual or 0),
    "CRIT_DEF_FAIL:" .. tostring(state.crit_def_failure_visual or 0),
    "DODGE_BACK:" .. tostring(state.dodge_back_percent or 50),
    "HIT_POINTS:" .. tostring(state.hit_points or 5),
    "ARMOR_TYPE:" .. encode_export_field(state.armor_type or "nue"),
    "DURABILITY_CURRENT:" .. tostring(state.durability_current or 5),
    "DURABILITY_MAX:" .. tostring(state.durability_max or 5),
    "DURABILITY_INFINITE:" .. tostring(state.durability_infinite and 1 or 0),
    "RDA:" .. tostring(state.rda or 0),
    "RDA_CRIT:" .. tostring(state.rda_crit or 0),
  }

  local chars = state.CHARS or {}
  local defaultCharSectionWritten = false

  local function ensure_default_char_section_line()
    if defaultCharSectionWritten then
      return
    end
    lines[#lines + 1] = table.concat({ "CHAR_SECTION", encode_export_field("Fiche basique"), "1", "1" }, ":")
    defaultCharSectionWritten = true
  end

  local function append_char_entry(entry)
    if type(entry) ~= "table" or entry.type == "section" then
      return
    end

    local name = encode_export_field(entry.name)
    local command = encode_export_field(entry.command)
    local info = encode_export_field(entry.info ~= nil and entry.info or entry.command)
    local randRole = encode_export_field(entry.rand_role)
    local icon = encode_export_field(entry.icon)

    lines[#lines + 1] = table.concat({
      "CHAR_RAND",
      name,
      command,
      info,
      randRole,
      entry.is_default and "1" or "0",
      icon,
    }, ":")
    lines[#lines + 1] = "RAND:" .. name .. ":" .. command

    if type(entry.outcomes) == "table" then
      local keys = {}
      for key in pairs(entry.outcomes) do
        local numericKey = tonumber(key)
        if numericKey then
          keys[#keys + 1] = numericKey
        end
      end
      table.sort(keys)
      for idx = 1, #keys do
        local key = keys[idx]
        local text = tostring(entry.outcomes[key] or "")
        if text ~= "" then
          lines[#lines + 1] = table.concat({
            "CHAR_OUTCOME",
            tostring(key),
            encode_export_field(text),
          }, ":")
        end
      end
    end

    if type(entry.outcome_ranges) == "table" then
      for idx = 1, #entry.outcome_ranges do
        local range = entry.outcome_ranges[idx]
        if type(range) == "table" then
          local minValue = tonumber(range.min)
          local maxValue = tonumber(range.max)
          local text = tostring(range.text or "")
          if minValue and maxValue and text ~= "" then
            lines[#lines + 1] = table.concat({
              "CHAR_RANGE",
              tostring(minValue),
              tostring(maxValue),
              encode_export_field(text),
            }, ":")
          end
        end
      end
    end
  end

  for i = 1, #chars do
    local entry = chars[i]
    if type(entry) == "table" and entry.type == "section" then
      lines[#lines + 1] = table.concat({
        "CHAR_SECTION",
        encode_export_field(entry.name),
        entry.is_fixed and "1" or "0",
        entry.expanded == false and "0" or "1",
      }, ":")
      if entry.is_fixed then
        defaultCharSectionWritten = true
      end
      for j = 1, #(entry.items or {}) do
        append_char_entry(entry.items[j])
      end
    elseif type(entry) == "table" then
      ensure_default_char_section_line()
      append_char_entry(entry)
    end
  end

  local buffs = nil
  if type(state.profile_buffs) == "table" and state.profile_index ~= nil then
    buffs = state.profile_buffs[state.profile_index]
  end
  if type(buffs) ~= "table" then
    buffs = state.buffs or {}
  end

  local defaultSectionWritten = false
  local function ensure_default_buff_section_line()
    if defaultSectionWritten then
      return
    end
    lines[#lines + 1] = table.concat({ "BUFF_SECTION", encode_export_field("Buffs"), "1", "1" }, ":")
    defaultSectionWritten = true
  end

  local function append_buff_entry(entry)
    if type(entry) ~= "table" or entry.type == "section" then
      return
    end

    local statsJoined = ""
    if type(entry.stats) == "table" and #entry.stats > 0 then
      local encodedStats = {}
      for idx = 1, #entry.stats do
        encodedStats[#encodedStats + 1] = encode_export_field(entry.stats[idx])
      end
      statsJoined = table.concat(encodedStats, ",")
    end

    lines[#lines + 1] = table.concat({
      "BUFF",
      encode_export_field(entry.title),
      encode_export_field(entry.stat),
      tostring(tonumber(entry.value) or 0),
      entry.active == false and "0" or "1",
      statsJoined,
    }, ":")

    if type(entry.values) == "table" then
      local keys = {}
      for key in pairs(entry.values) do
        keys[#keys + 1] = tostring(key)
      end
      table.sort(keys)
      for idx = 1, #keys do
        local key = keys[idx]
        lines[#lines + 1] = table.concat({
          "BUFF_VALUE",
          encode_export_field(key),
          tostring(tonumber(entry.values[key]) or 0),
        }, ":")
      end
    end
  end

  for i = 1, #buffs do
    local section = buffs[i]
    if type(section) == "table" and section.type == "section" then
      lines[#lines + 1] = table.concat({
        "BUFF_SECTION",
        encode_export_field(section.name),
        section.is_fixed and "1" or "0",
        section.expanded == false and "0" or "1",
      }, ":")
      if section.is_fixed then
        defaultSectionWritten = true
      end
      for j = 1, #(section.items or {}) do
        append_buff_entry(section.items[j])
      end
    elseif type(section) == "table" then
      ensure_default_buff_section_line()
      append_buff_entry(section)
    end
  end

  lines[#lines + 1] = "END"
  return table.concat(lines, "\n")
end

function MJ.get_defense_rand_name(defenderRandType)
  return DEFENSE_RAND_NAME_BY_TYPE[defenderRandType] or "Esquive"
end
