local UI = _G.EasySanaluneUI
if not UI then
  return
end

local BUFF_WINDOW_MIN_W = 300
local BUFF_WINDOW_MIN_H = 220
local BUFF_STATS_FONT_SIZE = 12
local BUFF_ICON_BUTTON_SIZE = 16
local BUFF_CLOSE_BUTTON_SIZE = BUFF_ICON_BUTTON_SIZE
local BUFF_SYMBOL_FONT_SIZE = 10
local BUFF_CLOSE_LABEL_OFFSET_X = 0
local BUFF_CLOSE_LABEL_OFFSET_Y = 0
local BUFF_X_LABEL_OFFSET_X = 1
local BUFF_X_LABEL_OFFSET_Y = 1
local BUFF_CARET_LABEL_OFFSET_X = 1
local BUFF_CARET_LABEL_OFFSET_Y = 0
local BUFF_CATEGORY_ROW_HEIGHT = 24
local BUFF_CATEGORY_ICON_BUTTON_SIZE = BUFF_ICON_BUTTON_SIZE
local BUFF_CATEGORY_ADD_BUTTON_WIDTH = 16
local BUFF_ROW_ICON_BUTTON_SIZE = BUFF_ICON_BUTTON_SIZE
local BUFF_ROW_HEIGHT = 48
local BUFF_RESET_BUTTON_WIDTH = 52
local BUFF_SECTION_EDIT_BUTTON_WIDTH = 56
local BUFF_ROW_EDIT_BUTTON_WIDTH = 58
local BUFF_ROW_VALUE_RIGHT_WITH_ACTIONS = -133
local BUFF_ROW_TEXT_RIGHT_WITH_ACTIONS = -190

local INTERNALS = UI._internals or {}
---@type EasySanaluneCore|nil
local Core = rawget(_G, "EasySanaluneCore")
local Text = (Core and Core.Text) or {}

UI.Buffs = UI.Buffs or {}

local sanitize_stats_list
local RESET_BUFFS_POPUP_KEY = "EASYSANALUNE_RESET_BUFFS_CONFIRM"

local function L_get(key, ...)
  if INTERNALS.l_get then return INTERNALS.l_get(key, ...) end
  return select("#",...) > 0 and string.format(tostring(key),...) or tostring(key)
end

local function L_print(key, ...)
  if INTERNALS.l_print then
    INTERNALS.l_print(key, ...)
  end
end

local function L_get_fallback(key, fallback)
  local value = L_get(key)
  if value == nil then
    return fallback
  end

  value = tostring(value)
  if value == tostring(key) or value == "" then
    return fallback
  end

  return value
end

---@return EasySanaluneState|nil
local function get_state()                     return INTERNALS.getState          and INTERNALS.getState()               end
---@return any
local function get_stdui()                     return INTERNALS.getStdUi          and INTERNALS.getStdUi()               end
local function apply_panel_theme(w, s, n)       if INTERNALS.apply_panel_theme    then INTERNALS.apply_panel_theme(w, s, n)    end end
local function apply_button_theme(w, p)        if INTERNALS.apply_button_theme   then INTERNALS.apply_button_theme(w, p)   end end
local function apply_checkbox_theme(w)         if INTERNALS.apply_checkbox_theme then INTERNALS.apply_checkbox_theme(w)     end end
local function apply_editbox_theme(w)          if INTERNALS.apply_editbox_theme  then INTERNALS.apply_editbox_theme(w)     end end
local function style_font_string(w, a)         if INTERNALS.style_font_string    then INTERNALS.style_font_string(w, a)    end end
local function make_modal_draggable(m, k)      if INTERNALS.make_modal_draggable then INTERNALS.make_modal_draggable(m, k)  end end
local function apply_modal_position(m, k)      if INTERNALS.apply_modal_position then INTERNALS.apply_modal_position(m, k)  end end
local function parse_command(v)
  if INTERNALS.parse_command then
    return INTERNALS.parse_command(v)
  end
end

local function trim(text)
  if Text.trim then
    return Text.trim(text)
  end
  local raw = tostring(text or "")
  raw = string.gsub(raw, "^%s+", "")
  raw = string.gsub(raw, "%s+$", "")
  return raw
end

local function sanitize_line(text)
  if Text.sanitize_single_line then
    return trim(Text.sanitize_single_line(text))
  end
  local raw = tostring(text or "")
  raw = string.gsub(raw, "[\r\n]", " ")
  return trim(raw)
end

local function apply_font_size(fs, size)
  if not fs or not size or not fs.SetFont then
    return
  end

  local fontPath, _, flags
  if fs.GetFont then
    fontPath, _, flags = fs:GetFont()
  end

  if (not fontPath) and GameFontNormal and GameFontNormal.GetFont then
    fontPath, _, flags = GameFontNormal:GetFont()
  end

  if fontPath then
    fs:SetFont(fontPath, size, flags)
  end
end

local function apply_centered_symbol_label(button, symbol)
  if not button then
    return
  end

  local baseText = button.text or button.label or button:GetFontString()
  if baseText then
    baseText:SetText("")
  end

  if not button.esCenteredSymbolLabel then
    button.esCenteredSymbolLabel = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  end

  local label = button.esCenteredSymbolLabel
  local offsetX = BUFF_CLOSE_LABEL_OFFSET_X
  local offsetY = BUFF_CLOSE_LABEL_OFFSET_Y
  if symbol == "x" then
    offsetX = offsetX + BUFF_X_LABEL_OFFSET_X
    offsetY = offsetY + BUFF_X_LABEL_OFFSET_Y
  elseif symbol == "^" or symbol == "v" then
    offsetX = offsetX + BUFF_CARET_LABEL_OFFSET_X
    offsetY = offsetY + BUFF_CARET_LABEL_OFFSET_Y
  end

  label:ClearAllPoints()
  label:SetPoint("CENTER", button, "CENTER", offsetX, offsetY)
  label:SetText(symbol or "")
  if label.SetRotation then
    pcall(label.SetRotation, label, 0)
  end
  style_font_string(label, true)
  apply_font_size(label, BUFF_SYMBOL_FONT_SIZE)
  if label.SetJustifyH then
    label:SetJustifyH("CENTER")
  end
  if label.SetJustifyV then
    label:SetJustifyV("MIDDLE")
  end
end

local STAT_OPTIONS = {
  { key = "all_stats", label = L_get("buff_stat_all_stats"), aliases = { "toutes les stats", "all", "all stats" } },
  { key = "all_offensive_stats", label = L_get("buff_stat_all_offensive"), aliases = { "toutes les stats offensives", "stats offensives", "offensives" } },
  { key = "all_defensive_stats", label = L_get("buff_stat_all_defensive"), aliases = { "toutes les stats defensives", "toutes les stats défensives", "stats defensives", "stats défensives", "defensives", "défensives" } },
  { key = "all_crit_success", label = L_get("buff_stat_all_crit_success"), aliases = { "toutes les reussites crits", "toutes les réussites crits", "all crit", "all crit success" } },
  { key = "crit_off_success", label = L_get("buff_stat_crit_off_success"), aliases = { "reussite crit off", "réussite crit off", "crit off" } },
  { key = "crit_def_success", label = L_get("buff_stat_crit_def_success"), aliases = { "reussite crit def", "réussite crit def", "crit def" } },
  { key = "attaque_physique", label = L_get("buff_stat_atk_phy"), aliases = { "attaque physique" } },
  { key = "attaque_magique", label = L_get("buff_stat_atk_mag"), aliases = { "attaque magique" } },
  { key = "soutien", label = L_get("buff_stat_support"), aliases = { "soutien" } },
  { key = "defense_physique", label = L_get("buff_stat_def_phy"), aliases = { "defense physique", "défense physique" } },
  { key = "defense_magique", label = L_get("buff_stat_def_mag"), aliases = { "defense magique", "défense magique" } },
  { key = "esquive", label = L_get("buff_stat_dodge"), aliases = { "esquive" } },
}

local AGGREGATE_STAT_KEYS = {
  all_stats = true,
  all_offensive_stats = true,
  all_defensive_stats = true,
  all_crit_success = true,
}

local MULTI_STAT_OPTIONS = {}
for i = 1, #STAT_OPTIONS do
  local option = STAT_OPTIONS[i]
  if not AGGREGATE_STAT_KEYS[option.key] then
    MULTI_STAT_OPTIONS[#MULTI_STAT_OPTIONS + 1] = option
  end
end

local function normalize_name(value)
  if Text.normalize_name then
    return Text.normalize_name(value)
  end
  local raw = string.lower(trim(tostring(value or "")))
  raw = string.gsub(raw, "[éèêë]", "e")
  raw = string.gsub(raw, "[àâä]", "a")
  raw = string.gsub(raw, "[îï]", "i")
  raw = string.gsub(raw, "[ôö]", "o")
  raw = string.gsub(raw, "[ùûü]", "u")
  raw = string.gsub(raw, "[^%w%s]", "")
  raw = string.gsub(raw, "%s+", " ")
  return trim(raw)
end

local function find_stat_option(value, optionList)
  local normalized = normalize_name(value)
  local list = optionList or STAT_OPTIONS
  if normalized == "" then
    return nil, nil
  end

  for i = 1, #list do
    local option = list[i]
    if option.key == value then
      return option, i
    end
    if normalize_name(option.label) == normalized then
      return option, i
    end
    for j = 1, #(option.aliases or {}) do
      if normalize_name(option.aliases[j]) == normalized then
        return option, i
      end
    end
  end

  return nil, nil
end

local function get_current_rand_target_options()
  local STATE = get_state()
  local out = {}
  local seen = {}

  local function add_target(sectionName, entry)
    if type(entry) ~= "table" or entry.type == "section" then
      return
    end

    local name = sanitize_line(entry.name or "")
    if name == "" then
      return
    end

    if find_stat_option(name, STAT_OPTIONS) then
      return
    end

    local normalized = normalize_name(name)
    if normalized == "" or seen[normalized] then
      return
    end
    seen[normalized] = true

    local sectionLabel = sanitize_line(sectionName or "")
    local label = sectionLabel ~= "" and (sectionLabel .. " > " .. name) or name
    out[#out + 1] = {
      key = name,
      label = label,
      aliases = { name },
    }
  end

  local function walk_entries(list, currentSectionName)
    if type(list) ~= "table" then
      return
    end

    for i = 1, #list do
      local entry = list[i]
      if type(entry) == "table" then
        if entry.type == "section" then
          walk_entries(entry.items or {}, sanitize_line(entry.name or ""))
        else
          add_target(currentSectionName, entry)
        end
      end
    end
  end

  walk_entries(STATE and STATE.CHARS or {}, "")

  table.sort(out, function(a, b)
    return normalize_name(a.label) < normalize_name(b.label)
  end)

  return out
end

local function build_single_target_options()
  local options = {}
  for i = 1, #STAT_OPTIONS do
    options[#options + 1] = STAT_OPTIONS[i]
  end

  local customTargets = get_current_rand_target_options()
  for i = 1, #customTargets do
    options[#options + 1] = customTargets[i]
  end

  return options
end

local function build_multi_target_options()
  local options = {}
  for i = 1, #MULTI_STAT_OPTIONS do
    options[#options + 1] = MULTI_STAT_OPTIONS[i]
  end

  local customTargets = get_current_rand_target_options()
  for i = 1, #customTargets do
    options[#options + 1] = customTargets[i]
  end

  return options
end

local function resolve_target_key(value)
  local raw = sanitize_line(value or "")
  if raw == "" then
    return nil
  end

  local option = find_stat_option(raw, STAT_OPTIONS)
  return option and option.key or raw
end

local function get_stat_option_index(statKey)
  local _, index = find_stat_option(statKey, STAT_OPTIONS)
  return index or 1
end

local function get_stat_option_by_rand_name(randName)
  local option = find_stat_option(randName, STAT_OPTIONS)
  return option
end

local function format_range(minVal, maxVal)
  return tostring(minVal) .. "-" .. tostring(maxVal)
end

sanitize_stats_list = function(stats)
  local out = {}
  local seen = {}
  if type(stats) ~= "table" then
    return out
  end

  for i = 1, #stats do
    local raw = sanitize_line(stats[i] or "")
    if raw ~= "" then
      local key = resolve_target_key(raw)
      local option = key and find_stat_option(key, STAT_OPTIONS) or nil
      local seenKey = option and option.key or normalize_name(key)
      if key and seenKey ~= "" and not seen[seenKey] then
        seen[seenKey] = true
        out[#out + 1] = key
      end
    end
  end

  return out
end

local function get_entry_stat_keys(entry)
  local keys = sanitize_stats_list(entry and entry.stats)
  if #keys > 0 then
    return keys
  end

  local fallbackKey = resolve_target_key(entry and entry.stat or "")
  if fallbackKey then
    return { fallbackKey }
  end

  return {}
end

local function format_entry_stats_label(entry)
  local keys = get_entry_stat_keys(entry)
  if #keys == 0 then
    local option = STAT_OPTIONS[1]
    return option and option.label or ""
  end

  local labels = {}
  for i = 1, #keys do
    local option = find_stat_option(keys[i], STAT_OPTIONS)
    labels[#labels + 1] = option and option.label or tostring(keys[i] or "")
  end

  if #labels == 0 then
    local option = STAT_OPTIONS[1]
    return option and option.label or ""
  end

  return table.concat(labels, ", ")
end

local function get_entry_value_text(entry)
  local hasPerStatValues = type(entry and entry.values) == "table"
  if not hasPerStatValues then
    return string.format("%+d", tonumber(entry and entry.value) or 0)
  end

  local keys = get_entry_stat_keys(entry)
  if #keys == 0 then
    return string.format("%+d", tonumber(entry and entry.value) or 0)
  end

  local sharedValue = nil
  for i = 1, #keys do
    local key = keys[i]
    local rawValue = entry.values[key]
    local numericValue = rawValue ~= nil and tonumber(rawValue) or tonumber(entry and entry.value) or 0
    if sharedValue == nil then
      sharedValue = numericValue
    elseif sharedValue ~= numericValue then
      return "..."
    end
  end

  return string.format("%+d", sharedValue or 0)
end

local BASE_STAT_KEYS = {
  "attaque_physique",
  "attaque_magique",
  "soutien",
  "defense_physique",
  "defense_magique",
  "esquive",
}

local function get_option_label_by_key(key)
  local option = find_stat_option(key, STAT_OPTIONS)
  return option and option.label or tostring(key or "")
end

local function get_exact_entry_stat_labels(entry)
  local keys = get_entry_stat_keys(entry)
  local labels = {}
  local seen = {}

  local function add_key(key)
    if seen[key] then
      return
    end
    seen[key] = true
    labels[#labels + 1] = get_option_label_by_key(key)
  end

  for i = 1, #keys do
    local key = keys[i]
    if key == "all_stats" then
      for j = 1, #BASE_STAT_KEYS do
        add_key(BASE_STAT_KEYS[j])
      end
    elseif key == "all_offensive_stats" then
      add_key("attaque_physique")
      add_key("attaque_magique")
      add_key("soutien")
    elseif key == "all_defensive_stats" then
      add_key("defense_physique")
      add_key("defense_magique")
      add_key("esquive")
    else
      add_key(key)
    end
  end

  return labels
end

local function constrain_button_label(button, leftInset, rightInset)
  if not button then
    return
  end

  local label = button.text or button.label or button:GetFontString()
  if not label then
    return
  end

  label:ClearAllPoints()
  label:SetPoint("LEFT", button, "LEFT", leftInset or 6, 0)
  label:SetPoint("RIGHT", button, "RIGHT", -(rightInset or 6), 0)
  if label.SetJustifyH then
    label:SetJustifyH("LEFT")
  end
  if label.SetWordWrap then
    label:SetWordWrap(false)
  end
end

local function constrain_checkbox_label(checkbox, owner, rightInset)
  if not checkbox then
    return
  end

  local label = checkbox.text or checkbox.label or checkbox:GetFontString()
  if not label then
    return
  end

  local target = checkbox.target or checkbox
  local container = owner or checkbox

  label:ClearAllPoints()
  label:SetPoint("LEFT", target, "RIGHT", 5, 0)
  label:SetPoint("RIGHT", container, "RIGHT", -(rightInset or 6), 0)
  if label.SetJustifyH then
    label:SetJustifyH("LEFT")
  end
  if label.SetWordWrap then
    label:SetWordWrap(false)
  end
end

local function create_stat_dropdown(parent, initialValue, onSelect, optionsProvider)
  local StdUi = get_stdui()
  if not StdUi then
    return nil, function() end, function() return nil end
  end

  local function get_options()
    if type(optionsProvider) == "function" then
      local provided = optionsProvider()
      if type(provided) == "table" and #provided > 0 then
        return provided
      end
    elseif type(optionsProvider) == "table" and #optionsProvider > 0 then
      return optionsProvider
    end
    return STAT_OPTIONS
  end

  local selectedKey = resolve_target_key(initialValue) or (STAT_OPTIONS[1] and STAT_OPTIONS[1].key or nil)
  local trigger = StdUi:Button(parent, 180, 20, "")
  apply_button_theme(trigger)
  constrain_button_label(trigger, 6, 6)

  local dropdown = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  dropdown:SetFrameStrata("DIALOG")
  dropdown:SetFrameLevel((parent:GetFrameLevel() or 1) + 20)
  dropdown:EnableMouse(true)
  dropdown:SetClampedToScreen(true)
  apply_panel_theme(dropdown, false)
  dropdown:Hide()

  local scroll = StdUi:ScrollFrame(dropdown, 168, 104)
  StdUi:GlueAcross(scroll, dropdown, 6, -6, -6, 6)
  apply_panel_theme(scroll, true)
  if INTERNALS.apply_scrollbar_theme then
    INTERNALS.apply_scrollbar_theme(scroll)
  end

  local content = scroll.scrollChild
  apply_panel_theme(content, true)

  local function get_selected_option()
    local options = get_options()
    local option = find_stat_option(selectedKey, options)
    if option then
      return option
    end
    return options[1]
  end

  local function refresh_trigger_text()
    local option = get_selected_option()
    trigger:SetText(option and option.label or "")
  end

  local function hide_dropdown()
    dropdown:Hide()
  end

  local function rebuild_dropdown()
    local children = { content:GetChildren() }
    for i = 1, #children do
      children[i]:Hide()
      children[i]:SetParent(nil)
    end

    local previous = nil
    local options = get_options()
    local selectedOption = get_selected_option()
    local selectedOptionKey = selectedOption and selectedOption.key or nil

    for i = 1, #options do
      local option = options[i]
      local row = StdUi:Button(content, 148, 20, option.label)
      apply_button_theme(row, option.key == selectedOptionKey)
      constrain_button_label(row, 6, 6)
      StdUi:GlueLeft(row, content, 2, 0, 0, 0)
      StdUi:GlueRight(row, content, -18, 0, 0, 0)
      if previous then
        StdUi:GlueBelow(row, previous, 0, -2)
      else
        StdUi:GlueTop(row, content, 0, -2)
      end
      previous = row

      row:SetScript("OnClick", function()
        selectedKey = option.key
        refresh_trigger_text()
        hide_dropdown()
        if onSelect then
          onSelect(option, i)
        end
      end)
    end
  end

  trigger:SetScript("OnClick", function()
    if dropdown:IsShown() then
      hide_dropdown()
      return
    end

    rebuild_dropdown()
    dropdown:ClearAllPoints()
    dropdown:SetPoint("TOPLEFT", trigger, "BOTTOMLEFT", 0, -2)
    dropdown:SetSize(trigger:GetWidth(), 116)
    dropdown:Show()
  end)

  refresh_trigger_text()

  return trigger, hide_dropdown, function()
    return get_selected_option()
  end
end

local function create_multi_target_dropdown(parent, optionsProvider, selectedMap)
  local StdUi = get_stdui()
  if not StdUi then
    return nil, function() end, function() return {} end
  end

  local function get_options()
    if type(optionsProvider) == "function" then
      local provided = optionsProvider()
      if type(provided) == "table" then
        return provided
      end
    elseif type(optionsProvider) == "table" then
      return optionsProvider
    end
    return {}
  end

  local trigger = StdUi:Button(parent, 220, 20, "")
  apply_button_theme(trigger)
  constrain_button_label(trigger, 6, 6)

  local dropdown = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  dropdown:SetFrameStrata("DIALOG")
  dropdown:SetFrameLevel((parent:GetFrameLevel() or 1) + 22)
  dropdown:EnableMouse(true)
  dropdown:SetClampedToScreen(true)
  apply_panel_theme(dropdown, false)
  dropdown:Hide()

  local scroll = StdUi:ScrollFrame(dropdown, 208, 132)
  StdUi:GlueAcross(scroll, dropdown, 6, -6, -6, 6)
  apply_panel_theme(scroll, true)
  if INTERNALS.apply_scrollbar_theme then
    INTERNALS.apply_scrollbar_theme(scroll)
  end

  local content = scroll.scrollChild
  apply_panel_theme(content, true)
  if content.SetClipsChildren then
    content:SetClipsChildren(true)
  end

  local function get_selected_keys()
    local out = {}
    local seen = {}
    local options = get_options()
    for i = 1, #options do
      local option = options[i]
      if option and option.key and selectedMap[option.key] and not seen[option.key] then
        seen[option.key] = true
        out[#out + 1] = option.key
      end
    end
    return out
  end

  local function refresh_trigger_text()
    local count = #get_selected_keys()
    if count <= 0 then
      trigger:SetText(L_get("modal_choose"))
    elseif count == 1 then
      local options = get_options()
      for i = 1, #options do
        local option = options[i]
        if option and option.key and selectedMap[option.key] then
          trigger:SetText(option.label or tostring(option.key))
          return
        end
      end
      trigger:SetText(L_get("modal_choose"))
    else
      trigger:SetText(string.format(L_get("buff_multi_select_count"), count))
    end
  end

  local function hide_dropdown()
    dropdown:Hide()
  end

  local function rebuild_dropdown()
    local children = { content:GetChildren() }
    for i = 1, #children do
      children[i]:Hide()
      children[i]:SetParent(nil)
    end

    local previous = nil
    local options = get_options()
    for i = 1, #options do
      local option = options[i]
      local row = CreateFrame("Frame", nil, content, "BackdropTemplate")
      row:SetHeight(22)
      row:SetPoint("LEFT", content, "LEFT", 2, 0)
      row:SetPoint("RIGHT", content, "RIGHT", -18, 0)
      if row.SetClipsChildren then
        row:SetClipsChildren(true)
      end
      if previous then
        row:SetPoint("TOP", previous, "BOTTOM", 0, -2)
      else
        row:SetPoint("TOP", content, "TOP", 0, -2)
      end
      previous = row
      apply_panel_theme(row, true)

      local check = StdUi:Checkbox(row, option.label or tostring(option.key or ""), 180, 20)
      check:ClearAllPoints()
      check:SetPoint("LEFT", row, "LEFT", 6, 0)
      check:SetPoint("RIGHT", row, "RIGHT", -6, 0)
      apply_checkbox_theme(check)
      constrain_checkbox_label(check, row, 6)
      check:SetChecked(selectedMap[option.key] and true or false)
      check.OnValueChanged = function(_, checked)
        if checked then
          selectedMap[option.key] = true
        else
          selectedMap[option.key] = nil
        end
        refresh_trigger_text()
      end
    end

    content:SetHeight(math.max(28, (#options * 24) + 4))
  end

  trigger:SetScript("OnClick", function()
    if dropdown:IsShown() then
      hide_dropdown()
      return
    end

    rebuild_dropdown()
    dropdown:ClearAllPoints()
    dropdown:SetPoint("TOPLEFT", trigger, "BOTTOMLEFT", 0, -2)
    dropdown:SetSize(math.max(trigger:GetWidth(), 230), 144)
    dropdown:Show()
  end)

  refresh_trigger_text()

  return trigger, hide_dropdown, get_selected_keys
end

local DEFAULT_BUFF_SECTION_NAME = "Buffs"

local function is_buff_section(entry)
  return type(entry) == "table" and entry.type == "section"
end

local function sanitize_buff_values(values)
  if type(values) ~= "table" then
    return nil
  end
  local out = {}
  local hasAny = false
  for k, v in pairs(values) do
    if type(k) == "string" and k ~= "" then
      local n = tonumber(v)
      if n then
        out[k] = n
        hasAny = true
      end
    end
  end
  return hasAny and out or nil
end

local function sanitize_buff_payload(entry)
  local stats = sanitize_stats_list(entry and entry.stats)
  local stat = sanitize_line(entry and entry.stat or "")
  if stat == "" and #stats > 0 then
    stat = stats[1]
  end

  return {
    title = sanitize_line(entry and entry.title or ""),
    stat = stat,
    stats = stats,
    value = tonumber(entry and entry.value) or 0,
    values = sanitize_buff_values(entry and entry.values),
    active = entry and entry.active and true or false,
  }
end

local function sanitize_buff_section(section)
  if not is_buff_section(section) then
    return nil
  end

  local out = {
    type = "section",
    name = sanitize_line(section.name or ""),
    is_fixed = section.is_fixed and true or false,
    expanded = section.expanded ~= false,
    items = {},
  }

  for i = 1, #(section.items or {}) do
    local item = section.items[i]
    if type(item) == "table" and item.type ~= "section" then
      out.items[#out.items + 1] = sanitize_buff_payload(item)
    end
  end

  return out
end

local function normalize_buff_sections(buffs)
  if type(buffs) ~= "table" then
    return {
      {
        type = "section",
        name = DEFAULT_BUFF_SECTION_NAME,
        is_fixed = true,
        expanded = true,
        items = {},
      }
    }
  end

  local hasSections = false
  for i = 1, #buffs do
    if is_buff_section(buffs[i]) then
      hasSections = true
      break
    end
  end

  if hasSections then
    local defaultSection = nil
    local defaultIndex = nil
    local duplicateIndexes = {}

    for i = 1, #buffs do
      local entry = buffs[i]
      if is_buff_section(entry) then
        entry.type = "section"
        entry.name = sanitize_line(entry.name or "")
        entry.expanded = entry.expanded ~= false
        entry.is_fixed = entry.is_fixed and true or false
        if type(entry.items) ~= "table" then
          entry.items = {}
        end

        local sanitizedItems = {}
        for j = 1, #entry.items do
          local item = entry.items[j]
          if type(item) == "table" and item.type ~= "section" then
            sanitizedItems[#sanitizedItems + 1] = sanitize_buff_payload(item)
          end
        end
        entry.items = sanitizedItems

        local nameNorm = normalize_name(entry.name)
        if entry.is_fixed or nameNorm == normalize_name(DEFAULT_BUFF_SECTION_NAME) then
          if not defaultSection then
            defaultSection = entry
            defaultIndex = i
          else
            for j = 1, #entry.items do
              defaultSection.items[#defaultSection.items + 1] = entry.items[j]
            end
            duplicateIndexes[#duplicateIndexes + 1] = i
          end
        end
      end
    end

    for i = #duplicateIndexes, 1, -1 do
      table.remove(buffs, duplicateIndexes[i])
    end

    if not defaultSection then
      defaultSection = {
        type = "section",
        name = DEFAULT_BUFF_SECTION_NAME,
        is_fixed = true,
        expanded = true,
        items = {},
      }
      table.insert(buffs, 1, defaultSection)
    else
      if sanitize_line(defaultSection.name) == "" then
        defaultSection.name = DEFAULT_BUFF_SECTION_NAME
      end
      defaultSection.is_fixed = true
      if defaultIndex and defaultIndex ~= 1 then
        table.remove(buffs, defaultIndex)
        table.insert(buffs, 1, defaultSection)
      end
    end

    local i = #buffs
    while i >= 1 do
      local entry = buffs[i]
      if not is_buff_section(entry) and type(entry) == "table" then
        defaultSection.items[#defaultSection.items + 1] = sanitize_buff_payload(entry)
        table.remove(buffs, i)
      end
      i = i - 1
    end

    return buffs
  end

  local normalized = {}
  local defaultSection = nil

  local function ensure_default_section()
    if not defaultSection then
      defaultSection = {
        type = "section",
        name = DEFAULT_BUFF_SECTION_NAME,
        is_fixed = true,
        expanded = true,
        items = {},
      }
      table.insert(normalized, 1, defaultSection)
    end
    return defaultSection
  end

  for i = 1, #buffs do
    local entry = buffs[i]
    if is_buff_section(entry) then
      local section = sanitize_buff_section(entry)
      if section then
        local nameNorm = normalize_name(section.name)
        if section.is_fixed or nameNorm == normalize_name(DEFAULT_BUFF_SECTION_NAME) then
          local fixed = ensure_default_section()
          fixed.name = DEFAULT_BUFF_SECTION_NAME
          fixed.expanded = section.expanded
          for j = 1, #section.items do
            fixed.items[#fixed.items + 1] = section.items[j]
          end
        else
          normalized[#normalized + 1] = section
        end
      end
    elseif type(entry) == "table" then
      local fixed = ensure_default_section()
      fixed.items[#fixed.items + 1] = sanitize_buff_payload(entry)
    end
  end

  local fixed = ensure_default_section()
  fixed.name = DEFAULT_BUFF_SECTION_NAME
  fixed.is_fixed = true

  if normalized[1] ~= fixed then
    for i = 1, #normalized do
      if normalized[i] == fixed then
        table.remove(normalized, i)
        break
      end
    end
    table.insert(normalized, 1, fixed)
  end

  return normalized
end

local function for_each_buff_item(buffs, fn)
  if type(buffs) ~= "table" or type(fn) ~= "function" then
    return
  end
  for i = 1, #buffs do
    local section = buffs[i]
    if is_buff_section(section) then
      for j = 1, #(section.items or {}) do
        local item = section.items[j]
        if type(item) == "table" and item.type ~= "section" then
          fn(item, section, j, i)
        end
      end
    elseif type(section) == "table" then
      fn(section, nil, i, nil)
    end
  end
end

local function ensure_profile_buffs(index)
  local STATE = get_state()
  if not STATE then
    return {}
  end

  if type(STATE.profile_buffs) ~= "table" then
    STATE.profile_buffs = {}
  end

  if type(STATE.profile_buffs[index]) ~= "table" then
    STATE.profile_buffs[index] = {}
  end

  STATE.profile_buffs[index] = normalize_buff_sections(STATE.profile_buffs[index])
  STATE.buffs = STATE.profile_buffs[index]
  return STATE.profile_buffs[index]
end

local function reset_current_profile_buffs()
  local STATE = get_state()
  if not STATE then
    return
  end

  if type(STATE.profile_buffs) ~= "table" then
    STATE.profile_buffs = {}
  end

  local index = STATE.profile_index
  if index == nil then
    index = 1
    STATE.profile_index = index
  end

  STATE.profile_buffs[index] = {}
  ensure_profile_buffs(index)
  _G.EASY_SANALUNE_SAVED_STATE = STATE

  if UI.Buffs.RefreshList then
    UI.Buffs.RefreshList()
  end
  if UI.REFRESH then
    UI.REFRESH()
  end
end

local function has_current_profile_buffs_to_reset()
  local STATE = get_state()
  if not STATE then
    return false
  end

  local index = STATE.profile_index
  local buffs = nil
  if type(STATE.profile_buffs) == "table" then
    buffs = STATE.profile_buffs[index]
  end
  if type(buffs) ~= "table" then
    buffs = STATE.buffs
  end
  if type(buffs) ~= "table" then
    return false
  end

  for i = 1, #buffs do
    local entry = buffs[i]
    if is_buff_section(entry) then
      if type(entry.items) == "table" and #entry.items > 0 then
        return true
      end
    elseif type(entry) == "table" then
      return true
    end
  end

  return false
end

local function ensure_reset_popup_dialog()
  if type(StaticPopupDialogs) ~= "table" then
    return false
  end

  if StaticPopupDialogs[RESET_BUFFS_POPUP_KEY] then
    return true
  end

  StaticPopupDialogs[RESET_BUFFS_POPUP_KEY] = {
    text = L_get_fallback("buff_reset_confirm_text", "Supprimer tous les buffs, debuffs et categories ?"),
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = function()
      reset_current_profile_buffs()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }

  return true
end

local function prompt_reset_all_buffs()
  if not has_current_profile_buffs_to_reset() then
    L_print("buff_reset_nothing")
    return
  end

  if not ensure_reset_popup_dialog() then
    return
  end
  StaticPopup_Show(RESET_BUFFS_POPUP_KEY)
end

local function update_buffs_reset_button_visibility()
  if not UI.BUFFS_RESET_BUTTON then
    return
  end

  if has_current_profile_buffs_to_reset() then
    UI.BUFFS_RESET_BUTTON:Show()
  else
    UI.BUFFS_RESET_BUTTON:Hide()
  end
end

function UI.Buffs.SwitchProfile(index)
  local STATE = get_state()
  if not STATE then
    return
  end
  ensure_profile_buffs(index)
  _G.EASY_SANALUNE_SAVED_STATE = STATE
end

local function collect_bonus_details(randName, randRole)
  local STATE = get_state()
  if not STATE or type(STATE.buffs) ~= "table" then
    return 0, nil, 0, {}
  end

  local option = get_stat_option_by_rand_name(randName)
  local normalizedRandName = normalize_name(randName)
  local normalizedRole = normalize_name(randRole)

  local isSupportTarget = normalizedRole == "support"
  local isOffensiveTarget = normalizedRole == "offensive" or isSupportTarget
  local isDefensiveTarget = normalizedRole == "defensive"

  if option then
    if option.key == "soutien" then
      isSupportTarget = true
      isOffensiveTarget = true
    elseif option.key == "attaque_physique" or option.key == "attaque_magique" then
      isOffensiveTarget = true
    elseif option.key == "defense_physique" or option.key == "defense_magique" or option.key == "esquive" then
      isDefensiveTarget = true
    end
  end

  if not option and normalizedRandName == "" and not isOffensiveTarget and not isDefensiveTarget then
    return 0, nil, 0, {}
  end

  local total = 0
  local supportRangeBonus = 0
  local sourceTitles = {}
  local directStatKey = option and option.key or nil

  for_each_buff_item(STATE.buffs, function(entry)
    if not (entry and entry.active) then
      return
    end

    local buffStatKeys = get_entry_stat_keys(entry)
    if #buffStatKeys == 0 then
      return
    end

    local hasPerStatValues = type(entry.values) == "table"
    local fallbackValue = tonumber(entry.value) or 0
    local applies = false
    local appliedValue = fallbackValue

    for i = 1, #buffStatKeys do
      local buffKey = tostring(buffStatKeys[i] or "")
      local normalizedBuffKey = normalize_name(buffKey)

      if buffKey == "all_stats" then
        applies = true
        if hasPerStatValues and directStatKey and entry.values[directStatKey] ~= nil then
          appliedValue = tonumber(entry.values[directStatKey]) or 0
        end
        if isSupportTarget then
          appliedValue = appliedValue * 2
          supportRangeBonus = supportRangeBonus + appliedValue
        end
        break
      end

      if buffKey == "all_offensive_stats" and isOffensiveTarget then
        applies = true
        if hasPerStatValues and directStatKey and entry.values[directStatKey] ~= nil then
          appliedValue = tonumber(entry.values[directStatKey]) or 0
        end
        if isSupportTarget then
          appliedValue = appliedValue * 2
          supportRangeBonus = supportRangeBonus + appliedValue
        end
        break
      end

      if buffKey == "all_defensive_stats" and isDefensiveTarget then
        applies = true
        if hasPerStatValues and directStatKey and entry.values[directStatKey] ~= nil then
          appliedValue = tonumber(entry.values[directStatKey]) or 0
        end
        break
      end

      if directStatKey and buffKey == directStatKey then
        applies = true
        if hasPerStatValues and entry.values[buffKey] ~= nil then
          appliedValue = tonumber(entry.values[buffKey]) or 0
        end
        if isSupportTarget then
          supportRangeBonus = supportRangeBonus + appliedValue
        end
        break
      end

      if normalizedRandName ~= "" and normalizedBuffKey ~= "" and normalizedBuffKey == normalizedRandName then
        applies = true
        if hasPerStatValues and entry.values[buffKey] ~= nil then
          appliedValue = tonumber(entry.values[buffKey]) or 0
        end
        if isSupportTarget then
          supportRangeBonus = supportRangeBonus + appliedValue
        end
        break
      end
    end

    if applies then
      total = total + appliedValue
      local title = sanitize_line(entry.title or "")
      if title ~= "" then
        sourceTitles[#sourceTitles + 1] = title
      end
    end
  end)

  return total, option, supportRangeBonus, sourceTitles
end

local function collect_crit_bonus_details(kind)
  local STATE = get_state()
  if not STATE or type(STATE.buffs) ~= "table" then
    return 0, {}
  end

  local targetKey = tostring(kind or "")
  if targetKey ~= "crit_off_success" and targetKey ~= "crit_def_success" then
    return 0, {}
  end

  local total = 0
  local sourceTitles = {}

  for_each_buff_item(STATE.buffs, function(entry)
    if not (entry and entry.active) then
      return
    end

    local buffStatKeys = get_entry_stat_keys(entry)
    if #buffStatKeys == 0 then
      return
    end

    local hasPerStatValues = type(entry.values) == "table"
    local fallbackValue = tonumber(entry.value) or 0
    local applies = false
    local appliedValue = fallbackValue

    for i = 1, #buffStatKeys do
      local buffKey = buffStatKeys[i]
      if buffKey == "all_crit_success" or buffKey == targetKey then
        applies = true
        if hasPerStatValues and entry.values[targetKey] ~= nil then
          appliedValue = tonumber(entry.values[targetKey]) or 0
        elseif hasPerStatValues and entry.values.all_crit_success ~= nil then
          appliedValue = tonumber(entry.values.all_crit_success) or 0
        end
        break
      end
    end

    if applies then
      total = total + appliedValue
      local title = sanitize_line(entry.title or "")
      if title ~= "" then
        sourceTitles[#sourceTitles + 1] = title
      end
    end
  end)

  return total, sourceTitles
end

function UI.Buffs.GetTotalBonusForRand(randName, randRole)
  return collect_bonus_details(randName, randRole)
end

function UI.Buffs.GetCritThresholdBonus(kind)
  return collect_crit_bonus_details(kind)
end

function UI.Buffs.GetBonusSourceText(randName, randRole)
  local totalBonus, _, _, sourceTitles = collect_bonus_details(randName, randRole)
  if (tonumber(totalBonus) or 0) == 0 or #sourceTitles == 0 then
    return nil
  end
  return table.concat(sourceTitles, ", ")
end

function UI.Buffs.ApplyBonusToRange(randName, minVal, maxVal, randRole)
  local totalBonus, option, supportRangeBonus = UI.Buffs.GetTotalBonusForRand(randName, randRole)
  local outMin = tonumber(minVal)
  local outMax = tonumber(maxVal)

  if not outMin or not outMax then
    return minVal, maxVal, totalBonus, option, supportRangeBonus
  end

  local isSupportTarget = (option and option.key == "soutien") or normalize_name(randRole) == "support"
  if isSupportTarget and (tonumber(totalBonus) or 0) ~= 0 then
    outMax = outMax + totalBonus
    if outMax < outMin then
      outMax = outMin
    end
  end

  return outMin, outMax, totalBonus, option, supportRangeBonus
end

function UI.Buffs.GetDisplayName(randData)
  if not randData then
    return ""
  end

  local name = tostring(randData.name or "")
  local totalBonus = 0
  if UI.Buffs.GetTotalBonusForRand then
    totalBonus = select(1, UI.Buffs.GetTotalBonusForRand(randData.name, randData.rand_role)) or 0
  end

  if totalBonus == 0 then
    return name
  end

  return string.format("%s (%+d)", name, totalBonus)
end

function UI.Buffs.GetDisplayInfo(randData)
  if not randData then
    return ""
  end

  local baseMin, baseMax = parse_command(randData.command)
  if not baseMin or not baseMax then
    return tostring(randData.info or "")
  end

  local minVal, maxVal, totalBonus, option, supportRangeBonus = UI.Buffs.ApplyBonusToRange(randData.name, baseMin, baseMax, randData.rand_role)
  if (tonumber(totalBonus) or 0) == 0 then
    return tostring(randData.info or "")
  end

  if (option and option.key == "soutien") or normalize_name(randData.rand_role) == "support" then
    return format_range(minVal, maxVal)
  end

  return tostring(randData.info or "")
end

local function get_default_section(buffs)
  if type(buffs) ~= "table" then
    return nil
  end
  for i = 1, #buffs do
    if is_buff_section(buffs[i]) and buffs[i].is_fixed then
      return buffs[i]
    end
  end
  local section = {
    type = "section",
    name = DEFAULT_BUFF_SECTION_NAME,
    is_fixed = true,
    expanded = true,
    items = {},
  }
  table.insert(buffs, 1, section)
  return section
end

local function make_buff_modal(entry, parentSection, itemIndex)
  local StdUi = get_stdui()
  local STATE = get_state()
  if not StdUi or not STATE then
    return
  end

  if UI.Buffs.modal and UI.Buffs.modal:IsShown() then
    UI.Buffs.modal:Hide()
  end

  local buffs = ensure_profile_buffs(STATE.profile_index)
  local targetSection = parentSection
  if not is_buff_section(targetSection) then
    targetSection = get_default_section(buffs)
  end

  local isEdit = entry ~= nil and is_buff_section(targetSection)
  local frame = StdUi:Panel(UIParent, 380, 286)
  frame:SetFrameStrata("DIALOG")
  frame:SetFrameLevel(420)
  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  apply_panel_theme(frame, false)
  make_modal_draggable(frame, "buff_modal")
  apply_modal_position(frame, "buff_modal")

  local title = StdUi:FontString(frame, isEdit and L_get("buff_modal_title_edit") or L_get("buff_modal_title_new"))
  title:SetPoint("TOP", frame, "TOP", 0, -10)
  style_font_string(title, true)

  local lblName = StdUi:FontString(frame, L_get("buff_label_title"))
  lblName:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -34)
  style_font_string(lblName)

  local ebTitle = StdUi:SimpleEditBox(frame, 220, 20, isEdit and (entry.title or "") or "")
  ebTitle:SetPoint("LEFT", lblName, "RIGHT", 10, 0)
  apply_editbox_theme(ebTitle)

  local lblValue = StdUi:FontString(frame, L_get("buff_label_value"))
  lblValue:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -60)
  style_font_string(lblValue)

  local ebValue = StdUi:SimpleEditBox(frame, 80, 20, tostring(isEdit and (entry.value or 0) or 0))
  ebValue:SetPoint("LEFT", lblValue, "RIGHT", 10, 0)
  apply_editbox_theme(ebValue)

  local initialTargetKey = resolve_target_key(isEdit and entry and entry.stat or "") or ""
  local lblStat = StdUi:FontString(frame, L_get("buff_label_stat"))
  lblStat:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -86)
  style_font_string(lblStat)

  local statDropdown, hideStatDropdown, getSelectedStatOption = create_stat_dropdown(frame, initialTargetKey, nil, build_single_target_options)
  if statDropdown then
    statDropdown:SetPoint("LEFT", lblStat, "RIGHT", 10, 0)
  end

  local initialStats = get_entry_stat_keys(entry)
  local selectedMultiStats = {}
  for i = 1, #initialStats do
    local key = initialStats[i]
    if not AGGREGATE_STAT_KEYS[key] then
      selectedMultiStats[key] = true
    end
  end

  local initialMultiEnabled = false
  if #initialStats > 1 then
    initialMultiEnabled = true
  elseif #initialStats == 1 and not AGGREGATE_STAT_KEYS[initialStats[1]] and entry and type(entry.stats) == "table" and #entry.stats > 0 then
    initialMultiEnabled = true
  end

  local cbMulti = StdUi:Checkbox(frame, L_get("buff_multi_stats_toggle"))
  cbMulti:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -112)
  apply_checkbox_theme(cbMulti)
  cbMulti:SetChecked(initialMultiEnabled)

  local lblStats = StdUi:FontString(frame, L_get("buff_label_stats"))
  lblStats:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -136)
  style_font_string(lblStats)

  local multiDropdown, hideMultiDropdown, getSelectedMultiStats = create_multi_target_dropdown(frame, build_multi_target_options, selectedMultiStats)
  if multiDropdown then
    multiDropdown:SetPoint("LEFT", lblStats, "RIGHT", 10, 0)
  end

  local function set_multi_mode_enabled(enabled)
    if statDropdown then
      statDropdown:SetShown(not enabled)
    end
    if lblStat then
      lblStat:SetShown(not enabled)
    end
    lblStats:SetShown(enabled)
    if multiDropdown then
      multiDropdown:SetShown(enabled)
    end
    lblValue:SetShown(true)
    ebValue:SetShown(true)
    frame:SetHeight(286)
  end

  cbMulti.OnValueChanged = function(_, checked)
    set_multi_mode_enabled(checked and true or false)
  end
  set_multi_mode_enabled(initialMultiEnabled)

  local btnSave = StdUi:Button(frame, 100, 22, L_get("common_save"))
  btnSave:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
  apply_button_theme(btnSave, true)

  local btnCancel = StdUi:Button(frame, 90, 22, L_get("common_cancel"))
  btnCancel:SetPoint("LEFT", btnSave, "RIGHT", 8, 0)
  apply_button_theme(btnCancel)

  local btnDelete = nil
  if isEdit then
    local deleteButton = StdUi:Button(frame, 90, 22, L_get("common_delete"))
    if deleteButton then
      deleteButton:SetPoint("LEFT", btnCancel, "RIGHT", 8, 0)
      apply_button_theme(deleteButton)
      if deleteButton.SetBackdropColor then
        deleteButton:SetBackdropColor(0.30, 0.08, 0.08, 0.95)
      end
    end
    btnDelete = deleteButton
  end

  btnSave:SetScript("OnClick", function()
    local titleText = sanitize_line(ebTitle:GetText())
    local numericValue = tonumber(ebValue:GetText() or "0") or 0
    hideStatDropdown()
    hideMultiDropdown()
    local option = getSelectedStatOption() or STAT_OPTIONS[1]

    local stats = {}
    local perStatValues = {}
    local hasPerStatValues = false
    if cbMulti:GetChecked() then
      local selectedKeys = getSelectedMultiStats()
      for i = 1, #selectedKeys do
        local candidateKey = selectedKeys[i]
        stats[#stats + 1] = candidateKey
        perStatValues[candidateKey] = numericValue
        hasPerStatValues = true
      end
    end
    if #stats == 0 then
      stats[1] = option and option.key or STAT_OPTIONS[1].key
    end

    local primaryStat = stats[1] or (option and option.key) or STAT_OPTIONS[1].key

    if titleText == "" then
      if #stats > 1 then
        titleText = L_get("buff_multi_stats_default_title")
      else
        titleText = get_option_label_by_key(primaryStat)
      end
    end

    local payload = {
      title = titleText,
      stat = primaryStat,
      stats = stats,
      value = numericValue,
      values = hasPerStatValues and perStatValues or nil,
      active = isEdit and (entry.active and true or false) or true,
    }

    local buffSections = ensure_profile_buffs(STATE.profile_index)
    local section = targetSection
    if not is_buff_section(section) then
      section = get_default_section(buffSections)
    end
    if type(section.items) ~= "table" then
      section.items = {}
    end

    if isEdit and itemIndex and section.items[itemIndex] then
      section.items[itemIndex] = payload
    else
      section.items[#section.items + 1] = payload
    end

    _G.EASY_SANALUNE_SAVED_STATE = STATE
    frame:Hide()
    UI.Buffs.RefreshList()
    if UI.REFRESH then
      UI.REFRESH()
    end
  end)

  btnCancel:SetScript("OnClick", function()
    hideStatDropdown()
    hideMultiDropdown()
    frame:Hide()
  end)

  if btnDelete then
    btnDelete:SetScript("OnClick", function()
      hideStatDropdown()
      hideMultiDropdown()
      local buffSections = ensure_profile_buffs(STATE.profile_index)
      local section = targetSection
      if not is_buff_section(section) then
        section = get_default_section(buffSections)
      end
      if itemIndex and section and section.items and section.items[itemIndex] then
        table.remove(section.items, itemIndex)
      end
      _G.EASY_SANALUNE_SAVED_STATE = STATE
      frame:Hide()
      UI.Buffs.RefreshList()
      if UI.REFRESH then
        UI.REFRESH()
      end
    end)
  end

  UI.Buffs.modal = frame
end

local function make_section_modal(section, sectionIndex)
  local StdUi = get_stdui()
  local STATE = get_state()
  if not StdUi or not STATE then
    return
  end

  if UI.Buffs.sectionModal and UI.Buffs.sectionModal:IsShown() then
    UI.Buffs.sectionModal:Hide()
  end

  local isEdit = is_buff_section(section)
  local frame = StdUi:Panel(UIParent, 320, 110)
  frame:SetFrameStrata("DIALOG")
  frame:SetFrameLevel(425)
  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  apply_panel_theme(frame, false)
  make_modal_draggable(frame, "buff_section_modal")
  apply_modal_position(frame, "buff_section_modal")

  local title = StdUi:FontString(frame, isEdit and L_get("buff_section_modal_title_edit") or L_get("buff_section_modal_title_new"))
  title:SetPoint("TOP", frame, "TOP", 0, -10)
  style_font_string(title, true)

  local lblName = StdUi:FontString(frame, L_get("modal_label_name"))
  lblName:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -40)
  style_font_string(lblName)

  local ebName = StdUi:SimpleEditBox(frame, 220, 20, isEdit and (section.name or "") or "")
  ebName:SetPoint("LEFT", lblName, "RIGHT", 8, 0)
  apply_editbox_theme(ebName)

  local btnSave = StdUi:Button(frame, 110, 22, isEdit and L_get("common_save") or L_get("modal_create"))
  btnSave:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 10)
  apply_button_theme(btnSave, true)

  local btnCancel = StdUi:Button(frame, 90, 22, L_get("common_cancel"))
  btnCancel:SetPoint("LEFT", btnSave, "RIGHT", 8, 0)
  apply_button_theme(btnCancel)

  btnSave:SetScript("OnClick", function()
    local name = sanitize_line(ebName:GetText())
    if name == "" then
      name = L_get("buff_section_default_name")
    end

    local buffSections = ensure_profile_buffs(STATE.profile_index)
    if isEdit and sectionIndex and buffSections[sectionIndex] then
      buffSections[sectionIndex].name = name
    else
      buffSections[#buffSections + 1] = {
        type = "section",
        name = name,
        expanded = true,
        items = {},
      }
    end

    _G.EASY_SANALUNE_SAVED_STATE = STATE
    frame:Hide()
    UI.Buffs.RefreshList()
    if UI.REFRESH then
      UI.REFRESH()
    end
  end)

  btnCancel:SetScript("OnClick", function()
    frame:Hide()
  end)

  UI.Buffs.sectionModal = frame
end

function UI.Buffs.RefreshList()
  local STATE = get_state()
  local StdUi = get_stdui()
  if not STATE or not StdUi then
    return
  end

  if not UI.BUFFS_FRAME or not UI.BUFFS_CONTENT then
    return
  end

  update_buffs_reset_button_visibility()

  local buffs = ensure_profile_buffs(STATE.profile_index)

  local children = { UI.BUFFS_CONTENT:GetChildren() }
  for i = 1, #children do
    children[i]:Hide()
    children[i]:SetParent(nil)
  end

  UI.Buffs.sectionWidgets = {}
  local rows = {}

  local function move_entry(list, entry, delta)
    if type(list) ~= "table" or not entry or not delta or delta == 0 then
      return false
    end
    local idx = nil
    for i = 1, #list do
      if list[i] == entry then
        idx = i
        break
      end
    end
    if not idx then
      return false
    end
    local newIndex = idx + delta
    if newIndex < 1 or newIndex > #list then
      return false
    end
    list[idx], list[newIndex] = list[newIndex], list[idx]
    return true
  end

  local function remove_entry(list, entry)
    if type(list) ~= "table" then
      return false
    end
    for i = 1, #list do
      if list[i] == entry then
        table.remove(list, i)
        return true
      end
    end
    return false
  end

  local function set_section_highlight(sectionWidget, enabled)
    if not sectionWidget then
      return
    end
    sectionWidget:SetAlpha(enabled and 0.75 or 1.0)
  end

  local function find_hover_section_widget(excludedWidget)
    if type(UI.Buffs.sectionWidgets) ~= "table" then
      return nil
    end
    for i = 1, #UI.Buffs.sectionWidgets do
      local sectionWidget = UI.Buffs.sectionWidgets[i]
      if sectionWidget and sectionWidget ~= excludedWidget and sectionWidget:IsMouseOver() and sectionWidget.infos then
        return sectionWidget
      end
    end
    return nil
  end

  local function move_section_relative(sectionElem, targetSectionWidget, placeAfter)
    if not sectionElem or not sectionElem.infos or sectionElem.infos.is_fixed then
      return false
    end
    if not targetSectionWidget or not targetSectionWidget.infos then
      return false
    end

    local moving = sectionElem.infos
    local target = targetSectionWidget.infos
    local sourceIndex, targetIndex = nil, nil

    for i = 1, #buffs do
      if buffs[i] == moving then
        sourceIndex = i
      end
      if buffs[i] == target then
        targetIndex = i
      end
    end
    if not sourceIndex or not targetIndex or sourceIndex == targetIndex then
      return false
    end

    table.remove(buffs, sourceIndex)
    if sourceIndex < targetIndex then
      targetIndex = targetIndex - 1
    end
    local insertIndex = placeAfter and (targetIndex + 1) or targetIndex
    if insertIndex < 2 then
      insertIndex = 2
    end
    if insertIndex > #buffs + 1 then
      insertIndex = #buffs + 1
    end
    table.insert(buffs, insertIndex, moving)
    return true
  end

  local function move_buff_to_section(buffElem, targetSection)
    if not buffElem or not buffElem.infos or not is_buff_section(targetSection) then
      return false
    end
    local buffData = buffElem.infos
    local sourceSection = buffElem.parentSection
    if not is_buff_section(sourceSection) then
      return false
    end
    if sourceSection == targetSection then
      return false
    end
    if not remove_entry(sourceSection.items, buffData) then
      return false
    end
    targetSection.items[#targetSection.items + 1] = buffData
    targetSection.expanded = true
    return true
  end

  local function move_buff_to_default_section(buffElem)
    local defaultSection = get_default_section(buffs)
    local sourceSection = buffElem and buffElem.parentSection or nil
    if not defaultSection or not sourceSection or sourceSection == defaultSection then
      return false
    end
    return move_buff_to_section(buffElem, defaultSection)
  end

  UI.Buffs.start_buff_drag = function(buffElem)
    if not buffElem or not buffElem.infos then
      return
    end
    UI.Buffs.draggedBuff = buffElem
    UI.Buffs.dragHoverSection = nil
    buffElem:SetAlpha(0.6)
    UI.BUFFS_CONTENT:SetScript("OnUpdate", function()
      local hovered = find_hover_section_widget()
      if hovered ~= UI.Buffs.dragHoverSection then
        if UI.Buffs.dragHoverSection then
          set_section_highlight(UI.Buffs.dragHoverSection, false)
        end
        UI.Buffs.dragHoverSection = hovered
        if UI.Buffs.dragHoverSection then
          set_section_highlight(UI.Buffs.dragHoverSection, true)
        end
      end
    end)
  end

  UI.Buffs.stop_buff_drag = function(buffElem)
    if not UI.Buffs.draggedBuff then
      return
    end
    if UI.Buffs.dragHoverSection then
      set_section_highlight(UI.Buffs.dragHoverSection, false)
    end
    UI.BUFFS_CONTENT:SetScript("OnUpdate", nil)
    buffElem:SetAlpha(1.0)

    local moved = false
    if UI.Buffs.dragHoverSection and UI.Buffs.dragHoverSection.infos then
      moved = move_buff_to_section(buffElem, UI.Buffs.dragHoverSection.infos)
    else
      moved = move_buff_to_default_section(buffElem)
    end

    UI.Buffs.draggedBuff = nil
    UI.Buffs.dragHoverSection = nil
    if moved then
      _G.EASY_SANALUNE_SAVED_STATE = STATE
      UI.Buffs.RefreshList()
      if UI.REFRESH then UI.REFRESH() end
    end
  end

  UI.Buffs.start_section_drag = function(sectionElem)
    if not sectionElem or not sectionElem.infos or sectionElem.infos.is_fixed then
      return
    end
    UI.Buffs.draggedSection = sectionElem
    UI.Buffs.dragHoverTargetSection = nil
    sectionElem:SetAlpha(0.6)
    UI.BUFFS_CONTENT:SetScript("OnUpdate", function()
      local hovered = find_hover_section_widget(sectionElem)
      if hovered ~= UI.Buffs.dragHoverTargetSection then
        if UI.Buffs.dragHoverTargetSection then
          set_section_highlight(UI.Buffs.dragHoverTargetSection, false)
        end
        UI.Buffs.dragHoverTargetSection = hovered
        if UI.Buffs.dragHoverTargetSection then
          set_section_highlight(UI.Buffs.dragHoverTargetSection, true)
        end
      end
    end)
  end

  UI.Buffs.stop_section_drag = function(sectionElem)
    if not UI.Buffs.draggedSection then
      return
    end
    if UI.Buffs.dragHoverTargetSection then
      set_section_highlight(UI.Buffs.dragHoverTargetSection, false)
    end
    UI.BUFFS_CONTENT:SetScript("OnUpdate", nil)
    sectionElem:SetAlpha(1.0)

    local moved = false
    if UI.Buffs.dragHoverTargetSection then
      local _, y = GetCursorPosition()
      local scale = UIParent:GetEffectiveScale()
      local cursorY = y / scale
      local _, centerY = UI.Buffs.dragHoverTargetSection:GetCenter()
      local placeAfter = centerY and cursorY < centerY or false
      moved = move_section_relative(sectionElem, UI.Buffs.dragHoverTargetSection, placeAfter)
    end

    UI.Buffs.draggedSection = nil
    UI.Buffs.dragHoverTargetSection = nil
    if moved then
      _G.EASY_SANALUNE_SAVED_STATE = STATE
      UI.Buffs.RefreshList()
      if UI.REFRESH then UI.REFRESH() end
    end
  end

  local function glue_row(row)
    StdUi:GlueLeft(row, UI.BUFFS_CONTENT, 4, 0, 0, 0)
    StdUi:GlueRight(row, UI.BUFFS_CONTENT, -4, 0, 0, 0)
    if #rows == 0 then
      StdUi:GlueTop(row, UI.BUFFS_CONTENT, 0, -4)
    else
      StdUi:GlueBelow(row, rows[#rows], 0, -4)
    end
    rows[#rows + 1] = row
  end

  local function set_widgets_visible(widgets, visible)
    for i = 1, #widgets do
      local widget = widgets[i]
      if widget then
        if visible then
          widget:Show()
        else
          widget:Hide()
        end
      end
    end
  end

  local function is_hovered_any(widgets)
    for i = 1, #widgets do
      local widget = widgets[i]
      if widget and widget:IsMouseOver() then
        return true
      end
    end
    return false
  end

  local function bind_hover_refresh(widgets, refreshFn)
    for i = 1, #widgets do
      local widget = widgets[i]
      if widget then
        widget:SetScript("OnEnter", refreshFn)
        widget:SetScript("OnLeave", refreshFn)
      end
    end
  end

  local function save_and_refresh(includeMainRefresh)
    _G.EASY_SANALUNE_SAVED_STATE = STATE
    UI.Buffs.RefreshList()
    if includeMainRefresh and UI.REFRESH then
      UI.REFRESH()
    end
  end

  local function move_entry_and_refresh(list, entry, delta)
    if move_entry(list, entry, delta) then
      save_and_refresh(false)
    end
  end

  local function remove_entry_and_refresh(list, entry, includeMainRefresh)
    if remove_entry(list, entry) then
      save_and_refresh(includeMainRefresh and true or false)
    end
  end

  local function create_action_button(parent, width, height, text, point, relativeTo, relativePoint, x, y, isPrimary, onClick)
    local button = StdUi:Button(parent, width, height, text)
    button:SetPoint(point, relativeTo, relativePoint, x, y)
    apply_button_theme(button, isPrimary and true or nil)
    if text == "x" or text == "+" or text == "^" or text == "v" or text == "-" then
      apply_centered_symbol_label(button, text)
    end
    if onClick then
      button:SetScript("OnClick", onClick)
    end
    return button
  end

  local totalItems = 0

  for sectionIndex = 1, #buffs do
    local section = buffs[sectionIndex]
    if not is_buff_section(section) then
      section = {
        type = "section",
        name = L_get("buff_section_default_name"),
        is_fixed = false,
        expanded = true,
        items = { sanitize_buff_payload(section) },
      }
      buffs[sectionIndex] = section
    end

    section.name = sanitize_line(section.name)
    if section.name == "" then
      section.name = L_get("buff_section_default_name")
    end
    if type(section.items) ~= "table" then
      section.items = {}
    end

    local sectionRow = StdUi:Panel(UI.BUFFS_CONTENT, 10, BUFF_CATEGORY_ROW_HEIGHT)
    sectionRow.infos = section
    sectionRow.type = "section"
    apply_panel_theme(sectionRow, false)
    glue_row(sectionRow)
    UI.Buffs.sectionWidgets[#UI.Buffs.sectionWidgets + 1] = sectionRow

    if not section.is_fixed then
      sectionRow:RegisterForDrag("LeftButton")
      sectionRow:SetScript("OnDragStart", function() UI.Buffs.start_section_drag(sectionRow) end)
      sectionRow:SetScript("OnDragStop", function() UI.Buffs.stop_section_drag(sectionRow) end)
    end

    local countText = string.format("(%d)", #section.items)
    local title = StdUi:FontString(sectionRow, string.format("%s %s", section.name, countText))
    title:SetPoint("LEFT", sectionRow, "LEFT", 6, 0)
    title:SetPoint("RIGHT", sectionRow, "RIGHT", -8, 0)
    title:SetJustifyH("LEFT")
    if title.SetWordWrap then
      title:SetWordWrap(false)
    end
    style_font_string(title, true)

    local btnAdd = create_action_button(sectionRow, BUFF_CATEGORY_ADD_BUTTON_WIDTH, BUFF_CATEGORY_ICON_BUTTON_SIZE, "+", "RIGHT", sectionRow, "RIGHT", -6, 0, true, function()
      make_buff_modal(nil, section, nil)
    end)

    local btnDown = create_action_button(sectionRow, BUFF_CATEGORY_ICON_BUTTON_SIZE, BUFF_CATEGORY_ICON_BUTTON_SIZE, "v", "RIGHT", btnAdd, "LEFT", -4, 0, false, function()
      if section.is_fixed then return end
      move_entry_and_refresh(buffs, section, 1)
    end)

    local btnUp = create_action_button(sectionRow, BUFF_CATEGORY_ICON_BUTTON_SIZE, BUFF_CATEGORY_ICON_BUTTON_SIZE, "^", "RIGHT", btnDown, "LEFT", -4, 0, false, function()
      if section.is_fixed then return end
      move_entry_and_refresh(buffs, section, -1)
    end)

    local sectionActionButtons = { btnAdd, btnDown, btnUp }

    local editAnchor = btnUp
    if not section.is_fixed then
      local btnDeleteSection = create_action_button(sectionRow, BUFF_CATEGORY_ICON_BUTTON_SIZE, BUFF_CATEGORY_ICON_BUTTON_SIZE, "x", "RIGHT", btnUp, "LEFT", -4, 0, false, function()
        remove_entry_and_refresh(buffs, section, true)
      end)
      sectionActionButtons[#sectionActionButtons + 1] = btnDeleteSection
      editAnchor = btnDeleteSection
    end

    local btnEditSection = create_action_button(sectionRow, BUFF_SECTION_EDIT_BUTTON_WIDTH, BUFF_CATEGORY_ICON_BUTTON_SIZE, L_get("common_edit"), "RIGHT", editAnchor, "LEFT", -4, 0, false, function()
      make_section_modal(section, sectionIndex)
    end)

    sectionActionButtons[#sectionActionButtons + 1] = btnEditSection

    sectionRow:SetScript("OnMouseUp", function(_, button)
      if is_hovered_any(sectionActionButtons) then
        return
      end

      if button == "LeftButton" then
        section.expanded = not section.expanded
        _G.EASY_SANALUNE_SAVED_STATE = STATE
        UI.Buffs.RefreshList()
      elseif button == "RightButton" then
        make_section_modal(section, sectionIndex)
      end
    end)

    local function set_section_actions_visible(visible)
      set_widgets_visible(sectionActionButtons, visible)

      title:ClearAllPoints()
      title:SetPoint("LEFT", sectionRow, "LEFT", 6, 0)
      title:SetPoint("RIGHT", sectionRow, "RIGHT", -8, 0)
    end

    local function refresh_section_actions_visibility()
      local hovered = sectionRow:IsMouseOver() or is_hovered_any(sectionActionButtons)
      set_section_actions_visible(hovered)
    end

    set_section_actions_visible(false)
    sectionRow:SetScript("OnEnter", refresh_section_actions_visibility)
    sectionRow:SetScript("OnLeave", refresh_section_actions_visibility)
    sectionRow:SetScript("OnHide", function()
      set_section_actions_visible(false)
    end)
    bind_hover_refresh(sectionActionButtons, refresh_section_actions_visibility)

    if section.expanded then
      for itemIndex = 1, #section.items do
        local entry = sanitize_buff_payload(section.items[itemIndex])
        section.items[itemIndex] = entry
        totalItems = totalItems + 1

        local row = StdUi:Panel(UI.BUFFS_CONTENT, 10, BUFF_ROW_HEIGHT)
        row.infos = entry
        row.parentSection = section
        apply_panel_theme(row, true)
        glue_row(row)

        row:RegisterForDrag("LeftButton")
        row:SetScript("OnDragStart", function() UI.Buffs.start_buff_drag(row) end)
        row:SetScript("OnDragStop", function() UI.Buffs.stop_buff_drag(row) end)

        local check = StdUi:Checkbox(row, "")
        check:SetPoint("LEFT", row, "LEFT", 8, 0)
        apply_checkbox_theme(check)
        check:SetChecked(entry.active and true or false)
        check.OnValueChanged = function(_, checked)
          entry.active = checked and true or false
          _G.EASY_SANALUNE_SAVED_STATE = STATE
          if UI.REFRESH then UI.REFRESH() end
        end

        local statLabel = format_entry_stats_label(entry)
        local exactStatLabels = get_exact_entry_stat_labels(entry)
        local hasPerStatValues = type(entry.values) == "table"
        local valueText = get_entry_value_text(entry)

        local titleFs = StdUi:FontString(row, entry.title)
        titleFs:SetPoint("TOPLEFT", row, "TOPLEFT", 30, -6)
        titleFs:SetPoint("RIGHT", row, "RIGHT", -180, 0)
        titleFs:SetJustifyH("LEFT")
        if titleFs.SetWordWrap then titleFs:SetWordWrap(false) end
        style_font_string(titleFs, entry.active)

        local metaFs = StdUi:FontString(row, statLabel)
        metaFs:SetPoint("TOPLEFT", titleFs, "BOTTOMLEFT", 0, -2)
        metaFs:SetPoint("RIGHT", row, "RIGHT", -180, 0)
        metaFs:SetJustifyH("LEFT")
        if metaFs.SetWordWrap then metaFs:SetWordWrap(false) end
        style_font_string(metaFs)
        apply_font_size(metaFs, BUFF_STATS_FONT_SIZE)

        local valueFs = StdUi:FontString(row, valueText)
        valueFs:SetWidth(42)
        valueFs:SetJustifyH("RIGHT")
        style_font_string(valueFs, true)

        local btnDown = create_action_button(row, BUFF_ROW_ICON_BUTTON_SIZE, BUFF_ROW_ICON_BUTTON_SIZE, "v", "RIGHT", row, "RIGHT", -6, 0, false, function()
          move_entry_and_refresh(section.items, entry, 1)
        end)

        local btnUp = create_action_button(row, BUFF_ROW_ICON_BUTTON_SIZE, BUFF_ROW_ICON_BUTTON_SIZE, "^", "RIGHT", btnDown, "LEFT", -4, 0, false, function()
          move_entry_and_refresh(section.items, entry, -1)
        end)

        local btnDelete = create_action_button(row, BUFF_ROW_ICON_BUTTON_SIZE, BUFF_ROW_ICON_BUTTON_SIZE, "x", "RIGHT", btnUp, "LEFT", -4, 0, false, function()
          remove_entry_and_refresh(section.items, entry, true)
        end)

        local btnEdit = create_action_button(row, BUFF_ROW_EDIT_BUTTON_WIDTH, 18, L_get("common_edit"), "RIGHT", btnDelete, "LEFT", -4, 0, false, function()
          make_buff_modal(entry, section, itemIndex)
        end)

        row:SetScript("OnMouseUp", function(_, button)
          if button == "RightButton" then
            make_buff_modal(entry, section, itemIndex)
          end
        end)

        local actionButtons = { btnEdit, btnDelete, btnUp, btnDown }

        local function show_row_tooltip()
          if not GameTooltip then
            return
          end
          GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
          GameTooltip:ClearLines()
          GameTooltip:AddLine(sanitize_line(entry.title) ~= "" and sanitize_line(entry.title) or L_get("buff_modal_title_new"), 1, 1, 1)

          local affectedStatsText = #exactStatLabels > 0 and table.concat(exactStatLabels, ", ") or statLabel
          GameTooltip:AddLine(L_get("buff_tooltip_affected_stats") .. " " .. affectedStatsText, 0.85, 0.85, 0.85, true)

          if hasPerStatValues then
            local keys = get_entry_stat_keys(entry)
            for ii = 1, #keys do
              local k = keys[ii]
              local v = tonumber(entry.values[k])
              if v then
                GameTooltip:AddLine("  " .. get_option_label_by_key(k) .. ": " .. string.format("%+d", v), 0.85, 0.85, 0.85)
              end
            end
          else
            GameTooltip:AddLine(L_get("buff_label_value") .. " " .. valueText, 0.85, 0.85, 0.85)
          end

          local statusText = entry.active and L_get("buff_tooltip_status_active") or L_get("buff_tooltip_status_inactive")
          GameTooltip:AddLine(L_get("buff_tooltip_status") .. " " .. statusText, 0.75, 0.75, 0.75)
          GameTooltip:Show()
        end

        local function hide_row_tooltip()
          if GameTooltip and GameTooltip:IsOwned(row) then
            GameTooltip:Hide()
          end
        end

        local function set_value_anchor(showActions)
          valueFs:ClearAllPoints()
          if showActions then
            valueFs:SetPoint("RIGHT", row, "RIGHT", BUFF_ROW_VALUE_RIGHT_WITH_ACTIONS, 0)
          else
            valueFs:SetPoint("RIGHT", row, "RIGHT", -10, 0)
          end
        end

        local function set_text_anchor(showActions)
          local rightOffset = showActions and BUFF_ROW_TEXT_RIGHT_WITH_ACTIONS or -58

          titleFs:ClearAllPoints()
          titleFs:SetPoint("TOPLEFT", row, "TOPLEFT", 30, -6)
          titleFs:SetPoint("RIGHT", row, "RIGHT", rightOffset, 0)

          metaFs:ClearAllPoints()
          metaFs:SetPoint("TOPLEFT", titleFs, "BOTTOMLEFT", 0, -2)
          metaFs:SetPoint("RIGHT", row, "RIGHT", rightOffset, 0)
        end

        local function set_actions_visible(visible)
          set_widgets_visible(actionButtons, visible)
          set_value_anchor(visible)
          set_text_anchor(visible)
        end

        local function refresh_actions_visibility()
          local hovered = row:IsMouseOver() or is_hovered_any(actionButtons)
          set_actions_visible(hovered)
          if hovered then
            show_row_tooltip()
          else
            hide_row_tooltip()
          end
        end

        set_actions_visible(false)
        row:SetScript("OnEnter", refresh_actions_visibility)
        row:SetScript("OnLeave", refresh_actions_visibility)
        bind_hover_refresh(actionButtons, refresh_actions_visibility)
        row:SetScript("OnHide", function()
          set_actions_visible(false)
          hide_row_tooltip()
        end)
      end
    end
  end

  if totalItems == 0 then
    local empty = StdUi:Panel(UI.BUFFS_CONTENT, 10, 28)
    apply_panel_theme(empty, true)
    glue_row(empty)
    local text = StdUi:FontString(empty, L_get("buff_empty"))
    text:SetPoint("CENTER", empty, "CENTER", 0, 0)
    style_font_string(text)
  end
end

function UI.Buffs.SyncToMainFrame()
  if not UI.BUFFS_FRAME or not UI.MAIN_FRAME then
    return
  end

  UI.BUFFS_FRAME:ClearAllPoints()
  UI.BUFFS_FRAME:SetPoint("TOPRIGHT", UI.MAIN_FRAME, "TOPLEFT", 3, 0)
end

function UI.Buffs.EnsureWindow()
  local StdUi = get_stdui()
  local STATE = get_state()
  if not StdUi or not STATE or not UI.MAIN_FRAME then
    return nil
  end

  if UI.BUFFS_FRAME then
    return UI.BUFFS_FRAME
  end

  STATE.buff_dim_w = math.max(tonumber(STATE.buff_dim_w) or 280, BUFF_WINDOW_MIN_W)
  STATE.buff_dim_h = math.max(tonumber(STATE.buff_dim_h) or 320, BUFF_WINDOW_MIN_H)

  local frame = StdUi:Panel(UIParent, STATE.buff_dim_w, STATE.buff_dim_h)
  frame:SetFrameStrata(UI.MAIN_FRAME:GetFrameStrata())
  frame:SetFrameLevel((UI.MAIN_FRAME:GetFrameLevel() or 1) + 2)
  apply_panel_theme(frame, false)
  frame:Hide()
  frame:SetResizable(true)
  frame:SetClampedToScreen(true)
  frame:SetMinResize(BUFF_WINDOW_MIN_W, BUFF_WINDOW_MIN_H)
  frame:SetMaxResize(480, 620)

  local title = StdUi:FontString(frame, L_get("buff_window_title"))
  title:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
  style_font_string(title, true)

  local close = StdUi:Button(frame, BUFF_CLOSE_BUTTON_SIZE, BUFF_CLOSE_BUTTON_SIZE, "x")
  close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
  apply_button_theme(close)

  local resetButton = StdUi:Button(frame, BUFF_RESET_BUTTON_WIDTH, BUFF_CLOSE_BUTTON_SIZE, L_get_fallback("common_reset", "Reset"))
  resetButton:SetPoint("RIGHT", close, "LEFT", -4, 0)
  apply_button_theme(resetButton)
  resetButton:SetScript("OnClick", function()
    prompt_reset_all_buffs()
  end)

  apply_centered_symbol_label(close, "x")
  close:SetScript("OnClick", function()
    STATE.buffs_visible = false
    frame:Hide()
    _G.EASY_SANALUNE_SAVED_STATE = STATE
  end)

  local scroll = StdUi:ScrollFrame(frame, STATE.buff_dim_w - 14, STATE.buff_dim_h - 72)
  StdUi:GlueAcross(scroll, frame, 6, -30, -6, 36)
  apply_panel_theme(scroll, true)
  if INTERNALS.apply_scrollbar_theme then
    INTERNALS.apply_scrollbar_theme(scroll)
  end
  if scroll.scrollFrame then
    scroll.scrollFrame.scrollBarHideable = false
    local function buff_scroll_guard()
      if not scroll.scrollFrame or not scroll.scrollBar then return end
      local yRange = scroll.scrollFrame:GetVerticalScrollRange() or 0
      local hasRange = yRange > 0.005
      scroll.scrollFrame:EnableMouseWheel(hasRange)
      if not hasRange then
        scroll.scrollBar:SetValue(0)
        scroll.scrollFrame:SetVerticalScroll(0)
      else
        local cur = scroll.scrollBar:GetValue()
        if cur > yRange then
          scroll.scrollBar:SetValue(yRange)
          scroll.scrollFrame:SetVerticalScroll(yRange)
        end
      end
    end
    scroll.scrollFrame:HookScript("OnScrollRangeChanged", buff_scroll_guard)
    scroll.scrollFrame:HookScript("OnVerticalScroll", function(_, offset)
      local yRange = scroll.scrollFrame:GetVerticalScrollRange() or 0
      if offset > yRange then
        scroll.scrollFrame:SetVerticalScroll(yRange)
        scroll.scrollBar:SetValue(yRange)
      end
    end)
    buff_scroll_guard()
  end

  local content = scroll.scrollChild
  apply_panel_theme(content, true)

  local addButton = StdUi:Button(frame, 130, 22, L_get("buff_new_button"))
  addButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 8)
  apply_button_theme(addButton, true)
  addButton:SetScript("OnClick", function()
    make_buff_modal(nil, nil)
  end)

  local addSectionButton = StdUi:Button(frame, 140, 22, L_get("buff_new_section_button"))
  addSectionButton:SetPoint("LEFT", addButton, "RIGHT", 8, 0)
  apply_button_theme(addSectionButton)
  addSectionButton:SetScript("OnClick", function()
    make_section_modal(nil, nil)
  end)

  local resizeHandle = CreateFrame("Button", nil, frame)
  resizeHandle:SetSize(16, 16)
  resizeHandle:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
  resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
  local nt = resizeHandle:GetNormalTexture()
  local ht = resizeHandle:GetHighlightTexture()
  local pt = resizeHandle:GetPushedTexture()
  local function orient_to_bottom_left(tex)
    if not tex then
      return
    end
    if tex.SetRotation then
      tex:SetRotation(math.pi)
    end
    if tex.SetTexCoord then
      tex:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)
    end
  end
  orient_to_bottom_left(nt)
  orient_to_bottom_left(ht)
  orient_to_bottom_left(pt)
  resizeHandle:SetScript("OnMouseDown", function(_, button)
    if button == "LeftButton" then
      frame:StartSizing("BOTTOMLEFT")
    end
  end)
  resizeHandle:SetScript("OnMouseUp", function()
    frame:StopMovingOrSizing()
    STATE.buff_dim_w = frame:GetWidth()
    STATE.buff_dim_h = frame:GetHeight()
    scroll:SetSize(frame:GetWidth() - 14, frame:GetHeight() - 72)
    StdUi:GlueAcross(scroll, frame, 6, -30, -6, 36)
    _G.EASY_SANALUNE_SAVED_STATE = STATE
  end)

  frame:SetScript("OnSizeChanged", function(self, newW, newH)
    scroll:SetSize(newW - 14, newH - 72)
    StdUi:GlueAcross(scroll, frame, 6, -30, -6, 36)
    STATE.buff_dim_w = newW
    STATE.buff_dim_h = newH
  end)

  UI.BUFFS_FRAME = frame
  UI.BUFFS_SCROLL = scroll
  UI.BUFFS_CONTENT = content
  UI.BUFFS_ADD_BUTTON = addButton
  UI.BUFFS_ADD_SECTION_BUTTON = addSectionButton
  UI.BUFFS_RESET_BUTTON = resetButton
  update_buffs_reset_button_visibility()

  UI.Buffs.SyncToMainFrame()

  return UI.BUFFS_FRAME
end

function UI.Buffs.Toggle()
  local STATE = get_state()
  if not STATE then
    return
  end

  UI.Buffs.EnsureWindow()
  if not UI.BUFFS_FRAME then
    return
  end

  update_buffs_reset_button_visibility()

  if UI.BUFFS_FRAME:IsShown() then
    UI.BUFFS_FRAME:Hide()
    STATE.buffs_visible = false
  else
    UI.Buffs.RefreshList()
    UI.BUFFS_FRAME:Show()
    STATE.buffs_visible = true
  end
  _G.EASY_SANALUNE_SAVED_STATE = STATE
end

function UI.Buffs.OnMainShow()
  local STATE = get_state()
  if not STATE then
    return
  end

  UI.Buffs.EnsureWindow()
  if not UI.BUFFS_FRAME then
    return
  end

  if STATE.buffs_visible == nil then
    STATE.buffs_visible = true
  end

  UI.Buffs.SyncToMainFrame()
  update_buffs_reset_button_visibility()

  if STATE.buffs_visible then
    UI.Buffs.RefreshList()
    UI.BUFFS_FRAME:Show()
  else
    UI.BUFFS_FRAME:Hide()
  end
end

function UI.Buffs.OnMainHide()
  if UI.BUFFS_FRAME then
    UI.BUFFS_FRAME:Hide()
  end
end
