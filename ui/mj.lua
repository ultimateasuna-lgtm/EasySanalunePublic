------------------------------------------------------------
-- ui/mj.lua — Fenêtre MJ, CRUD mobs, notifications, résolution
------------------------------------------------------------

local UI = _G.EasySanaluneUI
if not UI then return end

local INTERNALS = UI._internals or {}
---@type EasySanaluneCore|nil
local Core = rawget(_G, "EasySanaluneCore")
local Text = (Core and Core.Text) or {}
local MJLogic = Core and Core.MJ or nil
local mjFrame = nil

local function L_get(key, ...)
  if INTERNALS.l_get then return INTERNALS.l_get(key, ...) end
  return select("#",...) > 0 and string.format(tostring(key),...) or tostring(key)
end
local function L_print(key, ...) if INTERNALS.l_print then INTERNALS.l_print(key, ...) end end

---@return EasySanaluneState|nil
local function get_state()                     return INTERNALS.getState          and INTERNALS.getState()               end
---@return any
local function get_stdui()                     return INTERNALS.getStdUi          and INTERNALS.getStdUi()               end
local function apply_panel_theme(w, s, n)       if INTERNALS.apply_panel_theme    then INTERNALS.apply_panel_theme(w, s, n)    end end
local function apply_button_theme(w, p)        if INTERNALS.apply_button_theme   then INTERNALS.apply_button_theme(w, p)   end end
local function apply_checkbox_theme(w)         if INTERNALS.apply_checkbox_theme then INTERNALS.apply_checkbox_theme(w)    end end
local function apply_editbox_theme(w)          if INTERNALS.apply_editbox_theme  then INTERNALS.apply_editbox_theme(w)     end end
local function apply_scrollbar_theme(w)        if INTERNALS.apply_scrollbar_theme then INTERNALS.apply_scrollbar_theme(w)  end end
local function style_font_string(w, a)         if INTERNALS.style_font_string    then INTERNALS.style_font_string(w, a)    end end
local function make_modal_draggable(modal, k)  if INTERNALS.make_modal_draggable then INTERNALS.make_modal_draggable(modal, k) end end
local function apply_modal_position(modal, k)  if INTERNALS.apply_modal_position then INTERNALS.apply_modal_position(modal, k) end end
local function parse_command(v)
  if type(INTERNALS.parse_command) == "function" then
    return INTERNALS.parse_command(v)
  end
  return nil, nil, nil
end

local function get_addon_send_channel()
  if IsInRaid() then
    return "RAID"
  elseif IsInGroup() then
    return "PARTY"
  end
  return nil
end

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function next_mob_id(state)
  if MJLogic and MJLogic.next_mob_id then
    return MJLogic.next_mob_id(state)
  end
  local maxId = 0
  if type(state and state.mj_mobs) == "table" then
    for id in pairs(state.mj_mobs) do
      local n = tonumber(id)
      if n and n > maxId then
        maxId = n
      end
    end
  end
  return maxId + 1
end

local function trim(s)
  if Text.trim then
    return Text.trim(s)
  end
  return (tostring(s or "")):match("^%s*(.-)%s*$")
end

local function normalize_armor_type(value)
  if Core and type(Core.normalize_armor_type) == "function" then
    return Core.normalize_armor_type(value)
  end
  return trim(value)
end

local function fold_accents(s)
  if Text.fold_accents then
    return Text.fold_accents(s)
  end
  local out = string.lower(tostring(s or ""))
  local map = {
    ["à"] = "a", ["á"] = "a", ["â"] = "a", ["ã"] = "a", ["ä"] = "a", ["å"] = "a",
    ["ç"] = "c",
    ["è"] = "e", ["é"] = "e", ["ê"] = "e", ["ë"] = "e",
    ["ì"] = "i", ["í"] = "i", ["î"] = "i", ["ï"] = "i",
    ["ñ"] = "n",
    ["ò"] = "o", ["ó"] = "o", ["ô"] = "o", ["õ"] = "o", ["ö"] = "o", ["ø"] = "o",
    ["ù"] = "u", ["ú"] = "u", ["û"] = "u", ["ü"] = "u",
    ["ý"] = "y", ["ÿ"] = "y",
    ["œ"] = "oe", ["æ"] = "ae",
  }
  for k, v in pairs(map) do
    out = string.gsub(out, k, v)
  end
  return out
end

local function player_name_key(name)
  if Text.player_name_key then
    return Text.player_name_key(name)
  end
  local raw = trim(name)
  if raw == "" then
    return ""
  end
  local short = string.match(raw, "^([^%-]+)") or raw
  short = string.gsub(short, "%s+", "")
  return fold_accents(short)
end

local function player_names_equal(a, b)
  if Text.player_names_equal then
    return Text.player_names_equal(a, b)
  end
  local ka = player_name_key(a)
  local kb = player_name_key(b)
  return ka ~= "" and kb ~= "" and ka == kb
end

local function collect_group_player_names()
  local names = {}
  local seen = {}

  local function add_name(n)
    local name = trim(n)
    if name == "" then
      return
    end
    local key = string.lower(name)
    if seen[key] then
      return
    end
    seen[key] = true
    names[#names + 1] = name
  end

  if IsInRaid() then
    for i = 1, (GetNumGroupMembers() or 0) do
      local unit = "raid" .. tostring(i)
      if UnitExists(unit) and UnitIsConnected(unit) then
        add_name(UnitName(unit))
      end
    end
  elseif IsInGroup() then
    add_name(UnitName("player"))
    for i = 1, (GetNumSubgroupMembers() or 0) do
      local unit = "party" .. tostring(i)
      if UnitExists(unit) and UnitIsConnected(unit) then
        add_name(UnitName(unit))
      end
    end
  else
    add_name(UnitName("player"))
  end

  return names
end

local function resolve_player_name(inputName, state)
  local typed = trim(inputName)
  if typed == "" then
    return ""
  end
  local typedKey = player_name_key(typed)
  if typedKey == "" then
    return typed
  end

  local candidates = collect_group_player_names()
  if state and type(state.mj_player_targets) == "table" then
    for i = 1, #state.mj_player_targets do
      candidates[#candidates + 1] = state.mj_player_targets[i]
    end
  end

  for i = 1, #candidates do
    local candidate = trim(candidates[i])
    if candidate ~= "" and player_name_key(candidate) == typedKey then
      return candidate
    end
  end

  return typed
end

local function clear_widget_rows(rows)
  if type(rows) ~= "table" then
    return
  end
  for i = 1, #rows do
    local row = rows[i]
    if row then
      row:Hide()
      row:SetParent(nil)
    end
  end
end

local function format_session_time(secondsValue)
  local total = math.max(0, math.floor(tonumber(secondsValue) or 0))
  local hours = math.floor(total / 3600)
  local minutes = math.floor((total % 3600) / 60)
  local seconds = total % 60
  return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

local function build_history_entry_text(entry)
  if type(entry) ~= "table" then
    return ""
  end

  local prefix = string.format("[%s]", format_session_time(entry.timestamp))
  if entry.kind == "rand_request" then
    return string.format(
      "%s Attaque joueur: %s via %s (%d-%d)%s%s",
      prefix,
      tostring(entry.actor or "?"),
      tostring(entry.randName or "?"),
      tonumber(entry.min) or 0,
      tonumber(entry.max) or 0,
      tostring(entry.mobName or "") ~= "" and (" sur " .. tostring(entry.mobName)) or "",
      entry.isBehindAttack and (" | " .. L_get("mj_attack_back")) or ""
    )
  end

  if entry.kind == "mj_attack_request" then
    return string.format(
      "%s Attaque MJ: %s -> %s (%s %d-%d)%s",
      prefix,
      tostring(entry.mobName or entry.actor or "Mob"),
      tostring(entry.target or "?"),
      tostring(entry.attackType or "ATK_PHY"),
      tonumber(entry.min) or 0,
      tonumber(entry.max) or 0,
      entry.isBehindAttack and (" | " .. L_get("mj_attack_back")) or ""
    )
  end

  if entry.kind == "mj_resolution" then
    return string.format(
      "%s Résolution MJ: %s",
      prefix,
      tostring(entry.resultText or "")
    )
  end

  if entry.kind == "mj_attack_result" then
    return string.format(
      "%s Résultat attaque MJ: %s",
      prefix,
      tostring(entry.resultText or "")
    )
  end

  return prefix .. " " .. tostring(entry.resultText or entry.kind or "Action")
end

local function sanitize_mj_player_targets(state)
  if type(state) ~= "table" then
    return nil
  end
  if type(state.mj_player_targets) ~= "table" then
    state.mj_player_targets = {}
  end

  local cleanTargets = {}
  local seenTargets = {}
  for i = 1, #state.mj_player_targets do
    local name = trim(state.mj_player_targets[i])
    if name ~= "" then
      local key = player_name_key(name)
      if not seenTargets[key] then
        seenTargets[key] = true
        cleanTargets[#cleanTargets + 1] = name
      end
    end
  end

  state.mj_player_targets = cleanTargets
  return cleanTargets
end

local function sanitize_mj_selected_target(state, cleanTargets)
  if type(state) ~= "table" then
    return nil
  end
  local targets = cleanTargets or state.mj_player_targets or {}
  ---@type string|nil
  local selected = trim(state.mj_selected_target)

  if selected ~= "" then
    local found = false
    for i = 1, #targets do
      if player_names_equal(targets[i], selected) then
        found = true
        selected = targets[i]
        break
      end
    end
    if not found then
      selected = ""
    end
  end

  if selected == "" then
    selected = targets[1] or nil
  end

  state.mj_selected_target = selected
  return selected
end

local DEFAULT_CRIT_THRESHOLD = 70
local DEFAULT_MJ_DODGE_BACK_PERCENT = 50
local DEFAULT_MJ_HIT_POINTS = 5
local DEFAULT_MJ_ARMOR_TYPE = "nue"
local DEFAULT_MJ_DURABILITY_MAX = 5
local MJ_ARMOR_TYPE_OPTIONS = {
  { value = "nue", labelKey = "ui_armor_type_nue" },
  { value = "legere", labelKey = "ui_armor_type_light" },
  { value = "intermediaire", labelKey = "ui_armor_type_medium" },
  { value = "lourde", labelKey = "ui_armor_type_heavy" },
  { value = "special", labelKey = "ui_armor_type_special" },
}
local normalize_survival_data = Core and Core.normalize_survival_data or function(data) return data end
local get_survival_snapshot = Core and Core.get_survival_snapshot or function(data) return data or {} end
local format_durability_text = Core and Core.format_durability_text or function(data)
  local snapshot = data or {}
  return string.format("%s / %s", tostring(snapshot.durability_current or 5), tostring(snapshot.durability_max or 5))
end
local parse_durability_input = Core and Core.parse_durability_input
or function(value, fallbackCurrent, fallbackMax, fallbackInfinite)
  local raw = trim(value)
  if raw == "" then
    return fallbackCurrent, fallbackMax, fallbackInfinite and true or false, true
  end
  if raw == "∞" or string.lower(raw) == "inf" or string.lower(raw) == "infini" or string.lower(raw) == "infinite" then
    return nil, nil, true, true
  end
  local currentText, maxText = string.match(raw, "^(%-?%d+)%s*/%s*(%-?%d+)$")
  local currentValue = tonumber(currentText)
  local maxValue = tonumber(maxText)
  if currentValue and maxValue and maxValue >= 1 then
    if currentValue < 0 then
      currentValue = 0
    elseif currentValue > maxValue then
      currentValue = maxValue
    end
    return math.floor(currentValue), math.floor(maxValue), false, true
  end
  return nil, nil, false, false
end

local function deserialize_profile(text)
  if MJLogic and MJLogic.deserialize_profile then
    return MJLogic.deserialize_profile(text)
  end
  return nil
end

local function import_as_mob(parsed)
  local STATE = get_state()
  if not parsed or not STATE then
    return nil
  end
  if not MJLogic or not MJLogic.import_parsed_profile_as_mob then
    return nil
  end
  local newId = MJLogic.import_parsed_profile_as_mob(
    STATE,
    parsed,
    L_get("mj_imported_mob_name"),
    L_get("mj_imported_mob_notes")
  )
  if not newId then
    return nil
  end
  _G.EASY_SANALUNE_SAVED_STATE = STATE
  return newId
end

------------------------------------------------------------
-- doMJRoll: rolls defense using mob.rands, starts resolution
------------------------------------------------------------
local function get_current_mj_form_values()
  if mjFrame then
    local editBoxes = {
      mjFrame.ebName,
      mjFrame.ebNotes,
      mjFrame.ebHitPoints,
      mjFrame.ebDurability,
      mjFrame.ebRda,
      mjFrame.ebRdaCrit,
      mjFrame.ebPhyDef,
      mjFrame.ebMagDef,
      mjFrame.ebDodge,
      mjFrame.ebAtkPhy,
      mjFrame.ebAtkMag,
      mjFrame.ebSupport,
      mjFrame.ebCritOff,
      mjFrame.ebCritDef,
    }
    for i = 1, #editBoxes do
      local box = editBoxes[i]
      if box and box.ClearFocus and box:HasFocus() then
        box:ClearFocus()
      end
    end
  end
  if mjFrame and mjFrame.read_current_form_values then
    return mjFrame.read_current_form_values()
  end
  return nil
end

local function get_mj_rand_edit_box(randType)
  if not mjFrame then
    return nil
  end
  if randType == "PHY_DEF" then return mjFrame.ebPhyDef end
  if randType == "MAG_DEF" then return mjFrame.ebMagDef end
  if randType == "DODGE" then return mjFrame.ebDodge end
  if randType == "ATK_MAG" then return mjFrame.ebAtkMag end
  return mjFrame.ebAtkPhy
end

local function get_current_mj_form_rand_bounds(randType)
  local currentFormValues = get_current_mj_form_values()
  local box = get_mj_rand_edit_box(randType)
  local rawText = trim(box and box.GetText and box:GetText() or "")
  if rawText ~= "" then
    local eMin, eMax = parse_command(rawText)
    if eMin and eMax then
      return currentFormValues, rawText, eMin, eMax
    end
  end

  if currentFormValues and currentFormValues.rands then
    local commandText = currentFormValues.rands[randType]
    if commandText then
      local eMin, eMax = parse_command(commandText)
      if eMin and eMax then
        return currentFormValues, commandText, eMin, eMax
      end
    end
  end

  return currentFormValues, nil, nil, nil
end

local function doMJRoll(randType, reqId, mobId, overrideMin, overrideMax)
  local STATE = get_state()
  local rMin, rMax = 1, 100
  local currentFormValues, _, formMin, formMax = get_current_mj_form_rand_bounds(randType)
  -- mobId passed explicitly (from notification mob selector); fallback to active mob
  local effectiveMobId = mobId
  if effectiveMobId == nil and STATE then
    effectiveMobId = STATE.mj_active_mob_id
  end
  if overrideMin and overrideMax then
    rMin, rMax = overrideMin, overrideMax
  elseif formMin and formMax then
    rMin, rMax = formMin, formMax
  elseif STATE and effectiveMobId and type(STATE.mj_mobs) == "table" then
    local mob = STATE.mj_mobs[effectiveMobId]
    if mob then
      local cmd = mob.rands and mob.rands[randType] or nil
      if cmd then
        local eMin, eMax = parse_command(cmd)
        if eMin and eMax then
          rMin, rMax = eMin, eMax
        end
      end
    end
  elseif currentFormValues then
    local cmd = currentFormValues.rands and currentFormValues.rands[randType] or nil
    if cmd then
      local eMin, eMax = parse_command(cmd)
      if eMin and eMax then
        rMin, rMax = eMin, eMax
      end
    end
  end
  -- Store selected mob on the request so StartResolution uses the same mob
  local req = UI.pendingMJRequests and UI.pendingMJRequests[reqId]
  if req and effectiveMobId then
    req.selectedMobId = effectiveMobId
  end
  UI.StartResolution(reqId, randType, rMin, rMax)
  RandomRoll(rMin, rMax)
end

local function doMJAttack(targetName, attackType, isBehindAttack, overrideMin, overrideMax)
  local STATE = get_state()
  if not STATE then return end

  local target = trim(targetName)
  if target == "" then
    L_print("mj_target_required")
    return
  end

  local channel = get_addon_send_channel()
  if not channel then
    L_print("mj_group_required")
    return
  end

  local rMin, rMax = 1, 100
  local mobName = "Mob"
  local mobCritOff = nil
  local mobCritDef = nil
  local key = (attackType == "ATK_MAG") and "ATK_MAG" or "ATK_PHY"
  local currentFormValues, formCommandText, formMin, formMax = get_current_mj_form_rand_bounds(key)
  local activeMob = nil
  if STATE.mj_active_mob_id and type(STATE.mj_mobs) == "table" then
    activeMob = STATE.mj_mobs[STATE.mj_active_mob_id]
  end
  local hasFormMob = currentFormValues and currentFormValues.name ~= ""
  if not activeMob and not hasFormMob then
    L_print("mj_attack_mob_required")
    return
  end
  if STATE.mj_active_mob_id and type(STATE.mj_mobs) == "table" then
    local mob = activeMob
    if mob then
      mobName = mob.name or mobName
      mobCritOff = tonumber(mob.crit_off_success)
      mobCritDef = tonumber(mob.crit_def_success)
      local commandText = mob.rands and mob.rands[key] or nil
      if currentFormValues then
        mobName = currentFormValues.name ~= "" and currentFormValues.name or mobName
        mobCritOff = currentFormValues.critOff or mobCritOff
        mobCritDef = currentFormValues.critDef or mobCritDef
        commandText = formCommandText or commandText
      end
      if overrideMin and overrideMax then
        rMin, rMax = overrideMin, overrideMax
      elseif formMin and formMax then
        rMin, rMax = formMin, formMax
      elseif commandText then
        local eMin, eMax = parse_command(commandText)
        if eMin and eMax then
          rMin, rMax = eMin, eMax
        end
      end
    end
  elseif currentFormValues then
    mobName = currentFormValues.name ~= "" and currentFormValues.name or mobName
    mobCritOff = currentFormValues.critOff or mobCritOff
    mobCritDef = currentFormValues.critDef or mobCritDef
    if overrideMin and overrideMax then
      rMin, rMax = overrideMin, overrideMax
    elseif formMin and formMax then
      rMin, rMax = formMin, formMax
    else
      local commandText = currentFormValues.rands and currentFormValues.rands[key] or nil
      if commandText then
        local eMin, eMax = parse_command(commandText)
        if eMin and eMax then
          rMin, rMax = eMin, eMax
        end
      end
    end
  end

  local requestId = nil
  if UI.SendMJAttackRequest then
    requestId = UI.SendMJAttackRequest(target, attackType, rMin, rMax, mobName, mobCritOff, mobCritDef, isBehindAttack)
  end
  if not requestId then
    L_print("mj_attack_send_failed")
    return
  end
  RandomRoll(rMin, rMax)
  L_print("mj_attack_sent", mobName, target, rMin, rMax)
end

local function has_mj_mobs_to_reset(state)
  if type(state) ~= "table" then
    return false
  end

  if type(state.mj_mobs) == "table" and next(state.mj_mobs) ~= nil then
    return true
  end

  if state.mj_active_mob_id ~= nil then
    return true
  end

  return false
end

local function has_mj_targets_to_reset(state)
  if type(state) ~= "table" then
    return false
  end

  if type(state.mj_player_targets) == "table" and #state.mj_player_targets > 0 then
    return true
  end

  if trim(state.mj_selected_target) ~= "" then
    return true
  end

  return false
end

------------------------------------------------------------
-- Frame variables
------------------------------------------------------------
local mobRows = {}
local refresh_mj_reset_buttons_visibility = nil
local RefreshNotifications = nil

------------------------------------------------------------
-- Mob list refresh (right-click = edit, left-click = toggle active)
------------------------------------------------------------
local function RefreshMobList()
  if not mjFrame then return end
  local STATE = get_state()
  if not STATE then return end

  if refresh_mj_reset_buttons_visibility then
    refresh_mj_reset_buttons_visibility(STATE)
  end

  clear_widget_rows(mobRows)
  mobRows = {}

  local content = mjFrame.mobScrollContent
  if not content then return end

  local mobs = STATE.mj_mobs or {}
  local sortedIds = {}
  for id in pairs(mobs) do
    sortedIds[#sortedIds + 1] = tonumber(id) or id
  end
  table.sort(sortedIds)

  local yOffset = 0
  for _, mobId in ipairs(sortedIds) do
    local mob = mobs[mobId]
    if mob then
      local row = CreateFrame("Button", nil, content, "BackdropTemplate")
      row:SetSize(340, 28)
      row:SetPoint("TOPLEFT", content, "TOPLEFT", 2, yOffset)
      row:SetPoint("RIGHT",   content, "RIGHT",   -2, 0)
      row:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 },
      })
      local isActive = (STATE.mj_active_mob_id == mobId)
      if isActive then
        row:SetBackdropColor(0.12, 0.20, 0.34, 0.95)
        row:SetBackdropBorderColor(0.86, 0.80, 0.62, 1)
      else
        row:SetBackdropColor(0.06, 0.10, 0.17, 0.95)
        row:SetBackdropBorderColor(0.20, 0.34, 0.55, 1)
      end

      local nameFs = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      nameFs:SetPoint("LEFT", row, "LEFT", 8, 0)
      nameFs:SetText(mob.name or "?")
      nameFs:SetTextColor(0.95, 0.95, 0.95)

      local activeFs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      activeFs:SetPoint("RIGHT", row, "RIGHT", -8, 0)
      local badges = {}
      if isActive then
        badges[#badges + 1] = L_get("mj_active_badge")
      end
      activeFs:SetText(table.concat(badges, " • "))
      if #badges > 0 then
        activeFs:SetTextColor(1.0, 0.90, 0.65)
      else
        activeFs:SetText("")
      end

      local capturedId = mobId
      row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
      row:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
          if mjFrame.EditMob then mjFrame.EditMob(capturedId) end
        else
          local S = get_state()
          if not S then return end
          -- Left click now always selects this mob and loads its rands in the form.
          S.mj_active_mob_id = capturedId
          _G.EASY_SANALUNE_SAVED_STATE = S
          if mjFrame.EditMob then mjFrame.EditMob(capturedId) end
          RefreshMobList()
        end
      end)
      row:SetScript("OnEnter", function(self)
        if STATE.mj_active_mob_id ~= capturedId then
          self:SetBackdropColor(0.09, 0.15, 0.24, 0.98)
        end
        if mob.notes and mob.notes ~= "" then
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
          GameTooltip:SetText(mob.name or "?", 1, 0.85, 0.3)
          GameTooltip:AddLine(mob.notes, 1, 1, 1, true)
          GameTooltip:Show()
        end
      end)
      row:SetScript("OnLeave", function(self)
        if STATE.mj_active_mob_id ~= capturedId then
          self:SetBackdropColor(0.06, 0.10, 0.17, 0.95)
        end
        GameTooltip:Hide()
      end)

      row.mobId = capturedId
      mobRows[#mobRows + 1] = row
      yOffset = yOffset - 30
    end
  end

  content:SetHeight(math.max(40, -yOffset + 4))

  if mjFrame.activeMobLabel then
    local activeMob = STATE.mj_active_mob_id and (STATE.mj_mobs or {})[STATE.mj_active_mob_id]
    if activeMob then
      mjFrame.activeMobLabel:SetText(L_get("mj_active_mob_with_name", activeMob.name or "?"))
    else
      mjFrame.activeMobLabel:SetText(L_get("mj_active_mob_none"))
    end
  end
end

------------------------------------------------------------
-- MJ Frame creation
------------------------------------------------------------
local function CreateMJFrame()
  if mjFrame then return mjFrame end
  local StdUi = get_stdui()
  if not StdUi then return nil end

  mjFrame = CreateFrame("Frame", "EasySanaluneMJFrame", UIParent, "BackdropTemplate")
  mjFrame:SetSize(390, 760)
  mjFrame:SetFrameStrata("DIALOG")
  mjFrame:SetFrameLevel(100)
  mjFrame:EnableMouse(true)
  mjFrame:SetClampedToScreen(true)
  apply_panel_theme(mjFrame)
  make_modal_draggable(mjFrame, "mj_frame")
  apply_modal_position(mjFrame, "mj_frame")
  mjFrame:Hide()

  -- Title
  local title = mjFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", mjFrame, "TOP", 0, -12)
  title:SetText(L_get("mj_window_title"))
  title:SetTextColor(1.0, 0.84, 0.3)

  -- Match SanaluneTray behavior: lightweight textual close button with hover feedback.
  local closeBtn = CreateFrame("Button", nil, mjFrame)
  closeBtn:SetSize(18, 18)
  closeBtn:SetPoint("TOPRIGHT", mjFrame, "TOPRIGHT", -6, -6)
  closeBtn:EnableMouse(true)
  closeBtn:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
  if mjFrame.dragHandle and mjFrame.dragHandle.GetFrameLevel then
    closeBtn:SetFrameLevel(mjFrame.dragHandle:GetFrameLevel() + 10)
    -- Keep top-right clear so drag header does not steal clicks from close button.
    mjFrame.dragHandle:ClearAllPoints()
    mjFrame.dragHandle:SetPoint("TOPLEFT", mjFrame, "TOPLEFT", 0, 0)
    mjFrame.dragHandle:SetPoint("TOPRIGHT", mjFrame, "TOPRIGHT", -28, 0)
    mjFrame.dragHandle:SetHeight(24)
  end
  closeBtn:SetNormalFontObject("GameFontNormalSmall")
  closeBtn:SetHighlightFontObject("GameFontHighlightSmall")
  closeBtn:SetText("x")
  local function set_close_btn_color(r, g, b, a)
    local fs = closeBtn:GetFontString()
    if fs and fs.SetTextColor then
      fs:SetTextColor(r, g, b, a or 1)
    end
  end
  set_close_btn_color(1.0, 0.84, 0.30, 1.0)
  closeBtn:SetScript("OnEnter", function(self)
    set_close_btn_color(1.0, 0.94, 0.55, 1.0)
  end)
  closeBtn:SetScript("OnLeave", function(self)
    set_close_btn_color(1.0, 0.84, 0.30, 1.0)
  end)
  closeBtn:SetScript("OnClick", function() mjFrame:Hide() end)

  -- Active mob indicator
  local activeMobLabel = mjFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  activeMobLabel:SetPoint("TOPLEFT", mjFrame, "TOPLEFT", 14, -36)
  activeMobLabel:SetText(L_get("mj_active_mob_none"))
  style_font_string(activeMobLabel, true)
  mjFrame.activeMobLabel = activeMobLabel

  local contentLeft = 14
  local contentWidth = 350
  local contentGap = 6
  local labelWidth = 58
  local textFieldWidth = contentWidth - labelWidth - contentGap
  local randFieldWidth = 96
  local inputOffset = 64
  local rightColumnOffset = 166
  local rightInputOffset = 64
  local rightRandFieldWidth = 92

  -- Mob list scroll
  local mobScroll = StdUi:ScrollFrame(mjFrame, contentWidth, 128)
  mobScroll:SetPoint("TOPLEFT", mjFrame, "TOPLEFT", contentLeft, -56)
  apply_scrollbar_theme(mobScroll)
  mjFrame.mobScroll        = mobScroll
  mjFrame.mobScrollContent = mobScroll.scrollChild

  -- Separator
  local lblSep = mjFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  lblSep:SetPoint("TOPLEFT", mobScroll, "BOTTOMLEFT", 0, -6)
  lblSep:SetText(L_get("mj_separator_edit"))
  style_font_string(lblSep)

  -- Form: Nom
  local lblName = mjFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  lblName:SetPoint("TOPLEFT", lblSep, "BOTTOMLEFT", 0, -4)
  lblName:SetText(L_get("mj_label_name"))
  style_font_string(lblName)

  local ebName = StdUi:SimpleEditBox(mjFrame, textFieldWidth, 20, "")
  ebName:SetPoint("LEFT", lblName, "LEFT", inputOffset, 0)
  apply_editbox_theme(ebName)
  mjFrame.ebName = ebName

  local lblHitPoints = mjFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  lblHitPoints:SetPoint("TOPLEFT", lblName, "BOTTOMLEFT", 0, -6)
  lblHitPoints:SetText(L_get("mj_label_hit_points"))
  style_font_string(lblHitPoints)

  local ebHitPoints = StdUi:SimpleEditBox(mjFrame, randFieldWidth, 20, tostring(DEFAULT_MJ_HIT_POINTS))
  ebHitPoints:SetPoint("LEFT", lblHitPoints, "LEFT", inputOffset, 0)
  apply_editbox_theme(ebHitPoints)
  mjFrame.ebHitPoints = ebHitPoints

  local lblArmorType = mjFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  lblArmorType:SetPoint("LEFT", lblHitPoints, "LEFT", rightColumnOffset, 0)
  lblArmorType:SetText(L_get("mj_label_armor_type"))
  style_font_string(lblArmorType)

  local btnArmorType = StdUi:Button(mjFrame, rightRandFieldWidth, 20, "")
  btnArmorType:SetPoint("LEFT", lblArmorType, "LEFT", rightInputOffset, 0)
  apply_button_theme(btnArmorType)
  btnArmorType:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  mjFrame.btnArmorType = btnArmorType

  local lblDurability = mjFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  lblDurability:SetPoint("TOPLEFT", lblHitPoints, "BOTTOMLEFT", 0, -4)
  lblDurability:SetText(L_get("mj_label_durability"))
  style_font_string(lblDurability)

  local ebDurability = StdUi:SimpleEditBox(mjFrame, randFieldWidth, 20, tostring(DEFAULT_MJ_DURABILITY_MAX) .. " / " .. tostring(DEFAULT_MJ_DURABILITY_MAX))
  ebDurability:SetPoint("LEFT", lblDurability, "LEFT", inputOffset, 0)
  apply_editbox_theme(ebDurability)
  mjFrame.ebDurability = ebDurability

  local lblRda = mjFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  lblRda:SetPoint("LEFT", lblDurability, "LEFT", rightColumnOffset, 0)
  lblRda:SetText(L_get("mj_label_rda"))
  style_font_string(lblRda)

  local ebRda = StdUi:SimpleEditBox(mjFrame, rightRandFieldWidth, 20, "0")
  ebRda:SetPoint("LEFT", lblRda, "LEFT", rightInputOffset, 0)
  apply_editbox_theme(ebRda)
  mjFrame.ebRda = ebRda

  local lblRdaCrit = mjFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  lblRdaCrit:SetPoint("TOPLEFT", lblDurability, "BOTTOMLEFT", 0, -4)
  lblRdaCrit:SetText(L_get("mj_label_rda_crit"))
  style_font_string(lblRdaCrit)

  local ebRdaCrit = StdUi:SimpleEditBox(mjFrame, randFieldWidth, 20, "0")
  ebRdaCrit:SetPoint("LEFT", lblRdaCrit, "LEFT", inputOffset, 0)
  apply_editbox_theme(ebRdaCrit)
  mjFrame.ebRdaCrit = ebRdaCrit

  -- Form: Notes
  local lblNotes = mjFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  lblNotes:SetPoint("TOPLEFT", lblRdaCrit, "BOTTOMLEFT", 0, -6)
  lblNotes:SetText(L_get("mj_label_notes"))
  style_font_string(lblNotes)

  local ebNotes = StdUi:SimpleEditBox(mjFrame, textFieldWidth, 36, "")
  ebNotes:SetPoint("TOPLEFT", lblNotes, "TOPLEFT", inputOffset, 0)
  ebNotes:SetMultiLine(true)
  apply_editbox_theme(ebNotes)
  mjFrame.ebNotes = ebNotes

  -- Rands section header
  local lblRandsHeader = mjFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  lblRandsHeader:SetPoint("TOPLEFT", lblNotes, "BOTTOMLEFT", 0, -10)
  lblRandsHeader:SetText(L_get("mj_label_mob_rands"))
  style_font_string(lblRandsHeader, true)

  -- ATK_PHY
  local lblAtkPhy = mjFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  lblAtkPhy:SetPoint("TOPLEFT", lblRandsHeader, "BOTTOMLEFT", 0, -4)
  lblAtkPhy:SetText(L_get("mj_label_atk_phy"))
  style_font_string(lblAtkPhy)

  local ebAtkPhy = StdUi:SimpleEditBox(mjFrame, randFieldWidth, 20, "1-100")
  ebAtkPhy:SetPoint("LEFT", lblAtkPhy, "LEFT", inputOffset, 0)
  apply_editbox_theme(ebAtkPhy)
  mjFrame.ebAtkPhy = ebAtkPhy

  local lblCritOff = mjFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  lblCritOff:SetPoint("LEFT", lblAtkPhy, "LEFT", rightColumnOffset, 0)
  lblCritOff:SetText(L_get("mj_label_crit_off"))
  style_font_string(lblCritOff)

  local ebCritOff = StdUi:SimpleEditBox(mjFrame, rightRandFieldWidth, 20, tostring(DEFAULT_CRIT_THRESHOLD))
  ebCritOff:SetPoint("LEFT", lblCritOff, "LEFT", rightInputOffset, 0)
  apply_editbox_theme(ebCritOff)
  mjFrame.ebCritOff = ebCritOff

  -- ATK_MAG
  local lblAtkMag = mjFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  lblAtkMag:SetPoint("TOPLEFT", lblAtkPhy, "BOTTOMLEFT", 0, -4)
  lblAtkMag:SetText(L_get("mj_label_atk_mag"))
  style_font_string(lblAtkMag)

  local ebAtkMag = StdUi:SimpleEditBox(mjFrame, randFieldWidth, 20, "1-100")
  ebAtkMag:SetPoint("LEFT", lblAtkMag, "LEFT", inputOffset, 0)
  apply_editbox_theme(ebAtkMag)
  mjFrame.ebAtkMag = ebAtkMag

  local lblCritDef = mjFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  lblCritDef:SetPoint("LEFT", lblAtkMag, "LEFT", rightColumnOffset, 0)
  lblCritDef:SetText(L_get("mj_label_crit_def"))
  style_font_string(lblCritDef)

  local ebCritDef = StdUi:SimpleEditBox(mjFrame, rightRandFieldWidth, 20, tostring(DEFAULT_CRIT_THRESHOLD))
  ebCritDef:SetPoint("LEFT", lblCritDef, "LEFT", rightInputOffset, 0)
  apply_editbox_theme(ebCritDef)
  mjFrame.ebCritDef = ebCritDef

  local lblSupport = mjFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  lblSupport:SetPoint("TOPLEFT", lblAtkMag, "BOTTOMLEFT", 0, -4)
  lblSupport:SetText(L_get("mj_label_support"))
  style_font_string(lblSupport)

  local ebSupport = StdUi:SimpleEditBox(mjFrame, randFieldWidth, 20, "1-100")
  ebSupport:SetPoint("LEFT", lblSupport, "LEFT", inputOffset, 0)
  apply_editbox_theme(ebSupport)
  mjFrame.ebSupport = ebSupport

  local lblECritOff = mjFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  lblECritOff:SetPoint("LEFT", lblSupport, "LEFT", rightColumnOffset, 0)
  lblECritOff:SetText(L_get("mj_label_ecrit_off"))
  style_font_string(lblECritOff)

  local ebECritOff = StdUi:SimpleEditBox(mjFrame, rightRandFieldWidth, 20, "0")
  ebECritOff:SetPoint("LEFT", lblECritOff, "LEFT", rightInputOffset, 0)
  apply_editbox_theme(ebECritOff)
  mjFrame.ebECritOff = ebECritOff

  -- PHY_DEF
  local lblPhyDef = mjFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  lblPhyDef:SetPoint("TOPLEFT", lblSupport, "BOTTOMLEFT", 0, -4)
  lblPhyDef:SetText(L_get("mj_label_def_phy"))
  style_font_string(lblPhyDef)

  local ebPhyDef = StdUi:SimpleEditBox(mjFrame, randFieldWidth, 20, "1-100")
  ebPhyDef:SetPoint("LEFT", lblPhyDef, "LEFT", inputOffset, 0)
  apply_editbox_theme(ebPhyDef)
  mjFrame.ebPhyDef = ebPhyDef

  local lblECritDef = mjFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  lblECritDef:SetPoint("LEFT", lblPhyDef, "LEFT", rightColumnOffset, 0)
  lblECritDef:SetText(L_get("mj_label_ecrit_def"))
  style_font_string(lblECritDef)

  local ebECritDef = StdUi:SimpleEditBox(mjFrame, rightRandFieldWidth, 20, "0")
  ebECritDef:SetPoint("LEFT", lblECritDef, "LEFT", rightInputOffset, 0)
  apply_editbox_theme(ebECritDef)
  mjFrame.ebECritDef = ebECritDef

  -- MAG_DEF
  local lblMagDef = mjFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  lblMagDef:SetPoint("TOPLEFT", lblPhyDef, "BOTTOMLEFT", 0, -4)
  lblMagDef:SetText(L_get("mj_label_def_mag"))
  style_font_string(lblMagDef)

  local ebMagDef = StdUi:SimpleEditBox(mjFrame, randFieldWidth, 20, "1-100")
  ebMagDef:SetPoint("LEFT", lblMagDef, "LEFT", inputOffset, 0)
  apply_editbox_theme(ebMagDef)
  mjFrame.ebMagDef = ebMagDef

  -- DODGE
  local lblDodge = mjFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  lblDodge:SetPoint("TOPLEFT", lblMagDef, "BOTTOMLEFT", 0, -4)
  lblDodge:SetText(L_get("mj_label_dodge"))
  style_font_string(lblDodge)

  local ebDodge = StdUi:SimpleEditBox(mjFrame, randFieldWidth, 20, "1-100")
  ebDodge:SetPoint("LEFT", lblDodge, "LEFT", inputOffset, 0)
  apply_editbox_theme(ebDodge)
  mjFrame.ebDodge = ebDodge

  local lblDodgeBack = mjFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  lblDodgeBack:SetPoint("LEFT", lblDodge, "LEFT", rightColumnOffset, 0)
  lblDodgeBack:SetText(L_get("mj_label_dodge_back"))
  style_font_string(lblDodgeBack)

  local ebDodgeBack = StdUi:SimpleEditBox(mjFrame, rightRandFieldWidth, 20, tostring(DEFAULT_MJ_DODGE_BACK_PERCENT))
  ebDodgeBack:SetPoint("LEFT", lblDodgeBack, "LEFT", rightInputOffset, 0)
  apply_editbox_theme(ebDodgeBack)
  mjFrame.ebDodgeBack = ebDodgeBack

  local function set_editbox_interactive(editBox, enabled)
    if not editBox then
      return
    end
    if editBox.EnableMouse then
      editBox:EnableMouse(enabled and true or false)
    end
    if enabled then
      if editBox.Enable then
        pcall(function() editBox:Enable() end)
      end
    else
      if editBox.Disable then
        pcall(function() editBox:Disable() end)
      end
      if editBox.ClearFocus and editBox:HasFocus() then
        editBox:ClearFocus()
      end
    end
  end

  local function get_armor_label(armorType)
    local normalizedType = normalize_armor_type(armorType)
    for i = 1, #MJ_ARMOR_TYPE_OPTIONS do
      local option = MJ_ARMOR_TYPE_OPTIONS[i]
      if option.value == normalizedType then
        return option.labelKey and L_get(option.labelKey) or tostring(option.value)
      end
    end
    return tostring(normalizedType)
  end

  local function refresh_survival_fields(source)
    local snapshot = get_survival_snapshot(source)
    mjFrame.currentArmorType = normalize_armor_type(snapshot.armor_type)
    ebHitPoints:SetText(tostring(tonumber(snapshot.hit_points) or DEFAULT_MJ_HIT_POINTS))
    btnArmorType:SetText(get_armor_label(snapshot.armor_type))
    ebDurability:SetText(format_durability_text(snapshot))
    ebRda:SetText(tostring(tonumber(snapshot.rda) or 0))
    ebRdaCrit:SetText(tostring(tonumber(snapshot.rda_crit) or 0))

    local isSpecialArmor = normalize_armor_type(snapshot.armor_type) == "special"
    set_editbox_interactive(ebDurability, isSpecialArmor)
    set_editbox_interactive(ebRda, isSpecialArmor)
    set_editbox_interactive(ebRdaCrit, isSpecialArmor)
  end

  btnArmorType:SetScript("OnClick", function(_, button)
    local currentValue = mjFrame.currentArmorType or DEFAULT_MJ_ARMOR_TYPE
    local currentIndex = 1
    for optionIndex = 1, #MJ_ARMOR_TYPE_OPTIONS do
      if MJ_ARMOR_TYPE_OPTIONS[optionIndex].value == currentValue then
        currentIndex = optionIndex
        break
      end
    end

    local direction = (button == "RightButton") and -1 or 1
    local nextIndex = currentIndex + direction
    if nextIndex > #MJ_ARMOR_TYPE_OPTIONS then
      nextIndex = 1
    elseif nextIndex < 1 then
      nextIndex = #MJ_ARMOR_TYPE_OPTIONS
    end

    local nextArmorType = MJ_ARMOR_TYPE_OPTIONS[nextIndex].value
    local isSpecialArmor = normalize_armor_type(nextArmorType) == "special"
    local durabilityCurrent = nil
    local durabilityMax = nil
    local durabilityInfinite = false
    local rdaValue = 0
    local rdaCritValue = 0

    if isSpecialArmor then
      durabilityCurrent, durabilityMax, durabilityInfinite = parse_durability_input(
        trim(ebDurability:GetText() or ""),
        DEFAULT_MJ_DURABILITY_MAX,
        DEFAULT_MJ_DURABILITY_MAX,
        false
      )
      rdaValue = tonumber(trim(ebRda:GetText() or "")) or 0
      rdaCritValue = tonumber(trim(ebRdaCrit:GetText() or "")) or 0
    end

    refresh_survival_fields({
      hit_points = tonumber(trim(ebHitPoints:GetText())) or DEFAULT_MJ_HIT_POINTS,
      armor_type = nextArmorType,
      durability_current = durabilityCurrent,
      durability_max = durabilityMax,
      durability_infinite = durabilityInfinite and true or false,
      rda = rdaValue,
      rda_crit = rdaCritValue,
    })
  end)

  -- RefreshRandFields: populate rand editboxes for a given mob
  mjFrame.RefreshRandFields = function(mobId)
    local STATE = get_state()
    local mob = STATE and STATE.mj_mobs and mobId and STATE.mj_mobs[mobId]
    if mob and mob.rands then
      ebPhyDef:SetText(mob.rands.PHY_DEF or "1-100")
      ebMagDef:SetText(mob.rands.MAG_DEF or "1-100")
      ebDodge:SetText(mob.rands.DODGE    or "1-100")
      ebDodgeBack:SetText(tostring(tonumber(mob.dodge_back_percent) or DEFAULT_MJ_DODGE_BACK_PERCENT))
      ebAtkPhy:SetText(mob.rands.ATK_PHY or "1-100")
      ebAtkMag:SetText(mob.rands.ATK_MAG or "1-100")
      ebSupport:SetText(mob.support_text or "1-100")
      ebCritOff:SetText(mob.crit_off_success and tostring(mob.crit_off_success) or "")
      ebCritDef:SetText(mob.crit_def_success and tostring(mob.crit_def_success) or "")
      ebECritOff:SetText(tostring(tonumber(mob.crit_off_failure_visual) or 0))
      ebECritDef:SetText(tostring(tonumber(mob.crit_def_failure_visual) or 0))
      refresh_survival_fields(mob)
    else
      ebPhyDef:SetText("1-100")
      ebMagDef:SetText("1-100")
      ebDodge:SetText("1-100")
      ebDodgeBack:SetText(tostring(DEFAULT_MJ_DODGE_BACK_PERCENT))
      ebAtkPhy:SetText("1-100")
      ebAtkMag:SetText("1-100")
      ebSupport:SetText("1-100")
      ebCritOff:SetText(tostring(DEFAULT_CRIT_THRESHOLD))
      ebCritDef:SetText(tostring(DEFAULT_CRIT_THRESHOLD))
      ebECritOff:SetText("0")
      ebECritDef:SetText("0")
      refresh_survival_fields({
        hit_points = DEFAULT_MJ_HIT_POINTS,
        armor_type = DEFAULT_MJ_ARMOR_TYPE,
        durability_current = DEFAULT_MJ_DURABILITY_MAX,
        durability_max = DEFAULT_MJ_DURABILITY_MAX,
        durability_infinite = false,
        rda = 0,
        rda_crit = 0,
      })
    end
  end

  -- EditMob: load a mob's data into the form
  mjFrame.EditMob = function(mobId)
    local STATE = get_state()
    if not STATE or not STATE.mj_mobs or not STATE.mj_mobs[mobId] then return end
    mjFrame.editingMobId = mobId
    local mob = STATE.mj_mobs[mobId]
    ebName:SetText(mob.name or "")
    ebNotes:SetText(mob.notes or "")
    mjFrame.RefreshRandFields(mobId)
  end

  mjFrame.editingMobId = nil

  local function read_rand_fields()
    local function safe(v) return trim(v) ~= "" and trim(v) or "1-100" end
    return {
      PHY_DEF = safe(ebPhyDef:GetText()),
      MAG_DEF = safe(ebMagDef:GetText()),
      DODGE   = safe(ebDodge:GetText()),
      ATK_PHY = safe(ebAtkPhy:GetText()),
      ATK_MAG = safe(ebAtkMag:GetText()),
    }
  end

  local function get_click_bounds(randType)
    local box = nil
    if randType == "PHY_DEF" then box = ebPhyDef end
    if randType == "MAG_DEF" then box = ebMagDef end
    if randType == "DODGE" then box = ebDodge end
    if randType == "ATK_PHY" then box = ebAtkPhy end
    if randType == "ATK_MAG" then box = ebAtkMag end
    local raw = trim(box and box:GetText() or "")
    local eMin, eMax = parse_command(raw)
    if eMin and eMax then
      return eMin, eMax
    end
    return nil, nil
  end

  local function read_crit_value(box)
    local raw = trim(box:GetText())
    if raw == "" then return nil end
    local value = tonumber(raw)
    if not value or value <= 0 then return nil end
    return math.floor(value)
  end

  local function read_failure_crit_value(box)
    local raw = trim(box and box:GetText() or "")
    if raw == "" then return 0 end
    local value = tonumber(raw)
    if not value then return 0 end
    value = math.floor(value)
    if value < 0 then
      return 0
    end
    return value
  end

  local function read_support_text()
    local value = trim(ebSupport and ebSupport:GetText() or "")
    return value ~= "" and value or "1-100"
  end

  local function read_dodge_back_percent()
    local value = tonumber(trim(ebDodgeBack and ebDodgeBack:GetText() or ""))
    if value == nil then
      return DEFAULT_MJ_DODGE_BACK_PERCENT
    end
    value = math.floor(value)
    if value < 0 then
      return 0
    end
    if value > 100 then
      return 100
    end
    return value
  end

  local function read_hit_points()
    local value = tonumber(trim(ebHitPoints and ebHitPoints:GetText() or ""))
    if value == nil then
      return DEFAULT_MJ_HIT_POINTS
    end
    value = math.floor(value)
    if value < -2 then
      value = -2
    end
    return value
  end

  local function read_survival_values()
    local durabilityCurrent, durabilityMax, durabilityInfinite, okDurability = parse_durability_input(
      trim(ebDurability and ebDurability:GetText() or ""),
      DEFAULT_MJ_DURABILITY_MAX,
      DEFAULT_MJ_DURABILITY_MAX,
      false
    )
    if not okDurability then
      durabilityCurrent = DEFAULT_MJ_DURABILITY_MAX
      durabilityMax = DEFAULT_MJ_DURABILITY_MAX
      durabilityInfinite = false
    end

    local survivalData = {
      hit_points = read_hit_points(),
      armor_type = mjFrame.currentArmorType or DEFAULT_MJ_ARMOR_TYPE,
      durability_current = durabilityCurrent,
      durability_max = durabilityMax or DEFAULT_MJ_DURABILITY_MAX,
      durability_infinite = durabilityInfinite and true or false,
      rda = read_failure_crit_value(ebRda),
      rda_crit = read_failure_crit_value(ebRdaCrit),
    }
    normalize_survival_data(survivalData)
    return survivalData
  end

  local function read_support_flag()
    return read_support_text() ~= "1-100"
  end

  mjFrame.read_current_form_values = function()
    local survival = read_survival_values()
    return {
      name = trim(ebName:GetText()),
      notes = trim(ebNotes:GetText()),
      rands = read_rand_fields(),
      critOff = read_crit_value(ebCritOff),
      critDef = read_crit_value(ebCritDef),
      ecritOff = read_failure_crit_value(ebECritOff),
      ecritDef = read_failure_crit_value(ebECritDef),
      dodgeBackPercent = read_dodge_back_percent(),
      supportText = read_support_text(),
      isSupport = read_support_flag(),
      hitPoints = survival.hit_points,
      armorType = survival.armor_type,
      durabilityCurrent = survival.durability_current,
      durabilityMax = survival.durability_max,
      durabilityInfinite = survival.durability_infinite,
      rda = survival.rda,
      rdaCrit = survival.rda_crit,
    }
  end

  ebHitPoints:SetScript("OnEditFocusLost", function()
    refresh_survival_fields(read_survival_values())
  end)
  ebDurability:SetScript("OnEditFocusLost", function()
    refresh_survival_fields(read_survival_values())
  end)
  ebRda:SetScript("OnEditFocusLost", function()
    refresh_survival_fields(read_survival_values())
  end)
  ebRdaCrit:SetScript("OnEditFocusLost", function()
    refresh_survival_fields(read_survival_values())
  end)

  -- Action buttons
  local actionButtonWidth = math.floor((contentWidth - 12) / 3)
  local btnNew = StdUi:Button(mjFrame, actionButtonWidth, 22, L_get("common_new"))
  btnNew:SetPoint("TOPLEFT", lblDodge, "BOTTOMLEFT", 0, -8)
  apply_button_theme(btnNew, true)

  local btnSave = StdUi:Button(mjFrame, actionButtonWidth, 22, L_get("common_save"))
  btnSave:SetPoint("LEFT", btnNew, "RIGHT", 6, 0)
  apply_button_theme(btnSave, true)

  local btnDelete = StdUi:Button(mjFrame, actionButtonWidth, 22, L_get("common_delete"))
  btnDelete:SetPoint("LEFT", btnSave, "RIGHT", 6, 0)
  apply_button_theme(btnDelete)

  -- Import button
  local btnImport = StdUi:Button(mjFrame, contentWidth, 22, L_get("mj_import_profile_button"))
  btnImport:SetPoint("TOPLEFT", btnNew, "BOTTOMLEFT", 0, -4)
  apply_button_theme(btnImport)

  -- MJ attack controls
  local lblAttack = mjFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  lblAttack:SetPoint("TOPLEFT", btnImport, "BOTTOMLEFT", 0, -8)
  lblAttack:SetText(L_get("mj_attack_section"))
  style_font_string(lblAttack, true)

  local attackBackCheck = StdUi:Checkbox(mjFrame, L_get("mj_attack_back"))
  attackBackCheck:SetPoint("TOPLEFT", lblAttack, "BOTTOMLEFT", 0, -4)
  apply_checkbox_theme(attackBackCheck)

  local attackTargetWidth = 150
  local attackButtonWidth = 82
  local function ensure_attack_targets_state()
    local STATE = get_state()
    if not STATE then
      return nil
    end
    local cleanTargets = sanitize_mj_player_targets(STATE)
    sanitize_mj_selected_target(STATE, cleanTargets)
    return STATE
  end

  local targetDropBtn = CreateFrame("Button", nil, mjFrame, "BackdropTemplate")
  targetDropBtn:SetSize(attackTargetWidth, 20)
  targetDropBtn:SetPoint("TOPLEFT", attackBackCheck, "BOTTOMLEFT", 0, -4)
  targetDropBtn:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 10,
    insets   = { left = 2, right = 2, top = 2, bottom = 2 },
  })
  targetDropBtn:SetBackdropColor(0.08, 0.13, 0.23, 0.92)
  targetDropBtn:SetBackdropBorderColor(1.0, 0.84, 0.30, 0.9)

  local targetDropNameFs = targetDropBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  targetDropNameFs:SetPoint("LEFT", targetDropBtn, "LEFT", 6, 0)
  targetDropNameFs:SetPoint("RIGHT", targetDropBtn, "RIGHT", -16, 0)
  targetDropNameFs:SetJustifyH("LEFT")
  targetDropNameFs:SetTextColor(0.95, 0.95, 0.95)

  local targetDropArrowFs = targetDropBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  targetDropArrowFs:SetPoint("RIGHT", targetDropBtn, "RIGHT", -6, 0)
  targetDropArrowFs:SetText("v")
  targetDropArrowFs:SetTextColor(0.95, 0.95, 0.95)

  local attackTargetDropdown = nil
  local function close_attack_target_dropdown()
    if attackTargetDropdown then
      attackTargetDropdown:Hide()
    end
  end

  local update_mj_reset_buttons_visibility

  local function refresh_attack_target_dropdown_label()
    local STATE = ensure_attack_targets_state()
    local selected = STATE and trim(STATE.mj_selected_target) or ""
    if selected == "" then
      targetDropNameFs:SetText(L_get("mj_attack_target_none"))
    else
      targetDropNameFs:SetText(selected)
    end

    update_mj_reset_buttons_visibility(STATE)
  end

  local function open_attack_target_dropdown()
    local STATE = ensure_attack_targets_state()
    if not STATE then
      return
    end

    if not attackTargetDropdown then
      attackTargetDropdown = CreateFrame("Frame", "EasySanaluneMJTargetDrop", UIParent, "BackdropTemplate")
      attackTargetDropdown:SetFrameStrata("TOOLTIP")
      attackTargetDropdown:SetFrameLevel(500)
      attackTargetDropdown:EnableMouse(true)
      attackTargetDropdown:SetClampedToScreen(true)
      attackTargetDropdown:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
      })
      attackTargetDropdown:SetBackdropColor(0.08, 0.13, 0.23, 0.92)
      attackTargetDropdown:SetBackdropBorderColor(1.0, 0.84, 0.30, 0.9)
    end

    clear_widget_rows(attackTargetDropdown.rows)
    attackTargetDropdown.rows = {}

    local targets = STATE.mj_player_targets or {}
    local rowH = 20
    local yOff = -2

    for i = 1, #targets do
      local playerName = targets[i]
      local row = CreateFrame("Button", nil, attackTargetDropdown, "BackdropTemplate")
      row:SetSize(attackTargetWidth - 4, rowH)
      row:SetPoint("TOPLEFT", attackTargetDropdown, "TOPLEFT", 2, yOff)
      row:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
      })

      local isSelected = trim(STATE.mj_selected_target) ~= "" and player_names_equal(trim(STATE.mj_selected_target), playerName)
      if isSelected then
        row:SetBackdropColor(0.12, 0.20, 0.34, 0.95)
        row:SetBackdropBorderColor(1.0, 0.88, 0.42, 0.95)
      else
        row:SetBackdropColor(0.08, 0.13, 0.23, 0.92)
        row:SetBackdropBorderColor(1.0, 0.84, 0.30, 0.9)
      end

      row:SetScript("OnEnter", function(self)
        if not (trim(STATE.mj_selected_target) ~= "" and player_names_equal(trim(STATE.mj_selected_target), playerName)) then
          self:SetBackdropColor(0.12, 0.20, 0.34, 0.95)
          self:SetBackdropBorderColor(1.0, 0.88, 0.42, 0.95)
        end
      end)
      row:SetScript("OnLeave", function(self)
        if not (trim(STATE.mj_selected_target) ~= "" and player_names_equal(trim(STATE.mj_selected_target), playerName)) then
          self:SetBackdropColor(0.08, 0.13, 0.23, 0.92)
          self:SetBackdropBorderColor(1.0, 0.84, 0.30, 0.9)
        end
      end)

      local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      fs:SetPoint("LEFT", row, "LEFT", 6, 0)
      fs:SetText(playerName)
      fs:SetTextColor(0.95, 0.95, 0.95)

      row:SetScript("OnClick", function()
        local S = ensure_attack_targets_state()
        if not S then
          return
        end
        S.mj_selected_target = playerName
        _G.EASY_SANALUNE_SAVED_STATE = S
        refresh_attack_target_dropdown_label()
        close_attack_target_dropdown()
      end)

      attackTargetDropdown.rows[#attackTargetDropdown.rows + 1] = row
      yOff = yOff - rowH - 2
    end

    local totalH = math.max(24, #targets * (rowH + 2) + 4)
    attackTargetDropdown:SetSize(attackTargetWidth, totalH)
    attackTargetDropdown:ClearAllPoints()
    attackTargetDropdown:SetPoint("TOPLEFT", targetDropBtn, "BOTTOMLEFT", 0, -2)
    attackTargetDropdown:Show()
  end

  targetDropBtn:SetScript("OnClick", function()
    if attackTargetDropdown and attackTargetDropdown:IsShown() then
      close_attack_target_dropdown()
    else
      open_attack_target_dropdown()
    end
  end)

  local ebTargetManage = StdUi:SimpleEditBox(mjFrame, attackTargetWidth, 20, "")
  ebTargetManage:SetPoint("TOPLEFT", targetDropBtn, "BOTTOMLEFT", 0, -4)
  apply_editbox_theme(ebTargetManage)
  ebTargetManage:SetText("")
  mjFrame.ebAttackTargetManage = ebTargetManage

  local btnTargetAdd = StdUi:Button(mjFrame, attackButtonWidth, 20, L_get("mj_attack_target_add"))
  btnTargetAdd:SetPoint("LEFT", ebTargetManage, "RIGHT", 6, 0)
  apply_button_theme(btnTargetAdd)

  local btnTargetRemove = StdUi:Button(mjFrame, attackButtonWidth, 20, L_get("mj_attack_target_remove"))
  btnTargetRemove:SetPoint("LEFT", btnTargetAdd, "RIGHT", 6, 0)
  apply_button_theme(btnTargetRemove)

  local splitActionButtonWidth = math.floor((contentWidth - 6) / 2)
  local btnTargetGroupFill = StdUi:Button(mjFrame, splitActionButtonWidth, 20, L_get("mj_attack_target_group_fill"))
  btnTargetGroupFill:SetPoint("TOPLEFT", ebTargetManage, "BOTTOMLEFT", 0, -4)
  apply_button_theme(btnTargetGroupFill)

  local btnRefreshMobs = StdUi:Button(mjFrame, splitActionButtonWidth, 20, L_get("mj_refresh_mobs_button"))
  btnRefreshMobs:SetPoint("LEFT", btnTargetGroupFill, "RIGHT", 6, 0)
  apply_button_theme(btnRefreshMobs, true)

  local mjResetButtonWidth = math.floor((contentWidth - 8) / 2)
  local btnResetMobs = StdUi:Button(mjFrame, mjResetButtonWidth, 20, L_get("mj_reset_mobs_button"))
  btnResetMobs:SetPoint("TOPLEFT", btnTargetGroupFill, "BOTTOMLEFT", 0, -4)
  apply_button_theme(btnResetMobs)

  local btnResetTargets = StdUi:Button(mjFrame, mjResetButtonWidth, 20, L_get("mj_reset_targets_button"))
  btnResetTargets:SetPoint("LEFT", btnResetMobs, "RIGHT", 8, 0)
  apply_button_theme(btnResetTargets)

  local notifTitle = nil
  update_mj_reset_buttons_visibility = function(state)
    local S = state or get_state()
    if type(S) ~= "table" then
      btnResetMobs:Hide()
      btnResetTargets:Hide()
      return
    end

    local showMobs = has_mj_mobs_to_reset(S)
    local showTargets = has_mj_targets_to_reset(S)

    if showMobs then
      btnResetMobs:Show()
    else
      btnResetMobs:Hide()
    end

    if showTargets then
      btnResetTargets:Show()
    else
      btnResetTargets:Hide()
    end

    if notifTitle then
      notifTitle:ClearAllPoints()
      if showMobs or showTargets then
        notifTitle:SetPoint("TOPLEFT", btnResetMobs, "BOTTOMLEFT", 0, -10)
      else
        notifTitle:SetPoint("TOPLEFT", btnTargetGroupFill, "BOTTOMLEFT", 0, -10)
      end
    end
  end
  refresh_mj_reset_buttons_visibility = update_mj_reset_buttons_visibility

  local btnAtkPhys = StdUi:Button(mjFrame, attackButtonWidth, 20, L_get("mj_attack_btn_phy"))
  btnAtkPhys:SetPoint("LEFT", targetDropBtn, "RIGHT", 6, 0)
  apply_button_theme(btnAtkPhys, true)

  local btnAtkMag = StdUi:Button(mjFrame, attackButtonWidth, 20, L_get("mj_attack_btn_mag"))
  btnAtkMag:SetPoint("LEFT", btnAtkPhys, "RIGHT", 6, 0)
  apply_button_theme(btnAtkMag)

  local function get_selected_attack_target_name()
    local STATE = ensure_attack_targets_state()
    if not STATE then
      return ""
    end
    return trim(STATE.mj_selected_target)
  end

  local function show_reset_confirm(dialogKey, text, onAccept)
    if type(StaticPopupDialogs) ~= "table" then
      if onAccept then
        onAccept()
      end
      return
    end

    StaticPopupDialogs[dialogKey] = {
      text = text,
      button1 = L_get("ui_reset_profile_popup_confirm"),
      button2 = L_get("common_cancel"),
      OnAccept = function()
        if onAccept then
          onAccept()
        end
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
    StaticPopup_Show(dialogKey)
  end

  btnTargetAdd:SetScript("OnClick", function()
    local STATE = ensure_attack_targets_state()
    if not STATE then
      return
    end
    local newName = trim(ebTargetManage:GetText())
    if newName == "" then
      return
    end
    newName = resolve_player_name(newName, STATE)

    local exists = false
    for i = 1, #STATE.mj_player_targets do
      if player_names_equal(STATE.mj_player_targets[i], newName) then
        exists = true
        newName = STATE.mj_player_targets[i]
        break
      end
    end

    if not exists then
      STATE.mj_player_targets[#STATE.mj_player_targets + 1] = newName
      L_print("mj_target_added", newName)
    end
    STATE.mj_selected_target = newName
    _G.EASY_SANALUNE_SAVED_STATE = STATE
    ebTargetManage:SetText("")
    refresh_attack_target_dropdown_label()
    close_attack_target_dropdown()
    update_mj_reset_buttons_visibility(STATE)
  end)

  btnTargetRemove:SetScript("OnClick", function()
    local STATE = ensure_attack_targets_state()
    if not STATE then
      return
    end
    local selected = trim(STATE.mj_selected_target)
    if selected == "" then
      L_print("mj_target_remove_missing")
      return
    end

    for i = #STATE.mj_player_targets, 1, -1 do
      if player_names_equal(STATE.mj_player_targets[i], selected) then
        table.remove(STATE.mj_player_targets, i)
      end
    end

    L_print("mj_target_removed", selected)
    STATE.mj_selected_target = STATE.mj_player_targets[1] or nil
    _G.EASY_SANALUNE_SAVED_STATE = STATE
    refresh_attack_target_dropdown_label()
    close_attack_target_dropdown()
    update_mj_reset_buttons_visibility(STATE)
  end)

  btnTargetGroupFill:SetScript("OnClick", function()
    local STATE = ensure_attack_targets_state()
    if not STATE then
      return
    end

    STATE.mj_player_targets = collect_group_player_names()
    STATE.mj_selected_target = STATE.mj_player_targets[1] or nil
    _G.EASY_SANALUNE_SAVED_STATE = STATE
    refresh_attack_target_dropdown_label()
    close_attack_target_dropdown()
    update_mj_reset_buttons_visibility(STATE)
  end)

  btnRefreshMobs:SetScript("OnClick", function()
    if UI.SendMJMobSync and UI.SendMJMobSync() then
      L_print("mj_mobs_sync_sent")
    else
      L_print("mj_mobs_sync_failed")
    end
  end)

  btnResetMobs:SetScript("OnClick", function()
    local STATE = get_state()
    if not STATE then
      return
    end

    if not has_mj_mobs_to_reset(STATE) then
      L_print("mj_reset_mobs_nothing")
      return
    end

    show_reset_confirm("EASYSANALUNE_MJ_RESET_MOBS", L_get("mj_reset_mobs_confirm_text"), function()
      STATE.mj_mobs = {}
      STATE.mj_active_mob_id = nil
      mjFrame.editingMobId = nil
      ebName:SetText("")
      ebNotes:SetText("")
      mjFrame.RefreshRandFields(nil)
      _G.EASY_SANALUNE_SAVED_STATE = STATE
      RefreshMobList()
      update_mj_reset_buttons_visibility(STATE)
    end)
  end)

  btnResetTargets:SetScript("OnClick", function()
    local STATE = ensure_attack_targets_state()
    if not STATE then
      return
    end

    if not has_mj_targets_to_reset(STATE) then
      L_print("mj_reset_targets_nothing")
      return
    end

    show_reset_confirm("EASYSANALUNE_MJ_RESET_TARGETS", L_get("mj_reset_targets_confirm_text"), function()
      STATE.mj_player_targets = {}
      STATE.mj_selected_target = nil
      _G.EASY_SANALUNE_SAVED_STATE = STATE
      ebTargetManage:SetText("")
      refresh_attack_target_dropdown_label()
      close_attack_target_dropdown()
      update_mj_reset_buttons_visibility(STATE)
    end)
  end)

  ebTargetManage:SetScript("OnEnterPressed", function(self)
    btnTargetAdd:Click()
    self:ClearFocus()
  end)

  refresh_attack_target_dropdown_label()

  btnAtkPhys:SetScript("OnClick", function()
    local eMin, eMax = get_click_bounds("ATK_PHY")
    doMJAttack(get_selected_attack_target_name(), "ATK_PHY", attackBackCheck and attackBackCheck:GetChecked(), eMin, eMax)
  end)
  btnAtkMag:SetScript("OnClick", function()
    local eMin, eMax = get_click_bounds("ATK_MAG")
    doMJAttack(get_selected_attack_target_name(), "ATK_MAG", attackBackCheck and attackBackCheck:GetChecked(), eMin, eMax)
  end)

  -- btnNew: create mob immediately with default name
  btnNew:SetScript("OnClick", function()
    local STATE = get_state()
    if not STATE then return end
    if type(STATE.mj_mobs) ~= "table" then STATE.mj_mobs = {} end
    local currentRands = read_rand_fields()
    local currentCritOff = read_crit_value(ebCritOff)
    local currentCritDef = read_crit_value(ebCritDef)
    local currentECritOff = read_failure_crit_value(ebECritOff)
    local currentECritDef = read_failure_crit_value(ebECritDef)
    local currentDodgeBackPercent = read_dodge_back_percent()
    local currentSurvival = read_survival_values()
    local newId = next_mob_id(STATE)
    STATE.mj_mobs[newId] = {
      name  = L_get("mj_new_mob_name"),
      notes = "",
      rands = currentRands,
      crit_off_success = currentCritOff or DEFAULT_CRIT_THRESHOLD,
      crit_def_success = currentCritDef or DEFAULT_CRIT_THRESHOLD,
      crit_off_failure_visual = currentECritOff,
      crit_def_failure_visual = currentECritDef,
      dodge_back_percent = currentDodgeBackPercent,
      hit_points = currentSurvival.hit_points,
      armor_type = currentSurvival.armor_type,
      durability_current = currentSurvival.durability_current,
      durability_max = currentSurvival.durability_max,
      durability_infinite = currentSurvival.durability_infinite,
      rda = currentSurvival.rda,
      rda_crit = currentSurvival.rda_crit,
      is_support = read_support_flag(),
      support_text = read_support_text(),
    }
    STATE.mj_active_mob_id = newId
    _G.EASY_SANALUNE_SAVED_STATE = STATE
    mjFrame.editingMobId = newId
    ebName:SetText(L_get("mj_new_mob_name"))
    ebNotes:SetText("")
    mjFrame.RefreshRandFields(newId)
    RefreshMobList()
  end)

  btnSave:SetScript("OnClick", function()
    local STATE = get_state()
    if not STATE then return end
    local name = trim(ebName:GetText())
    if name == "" then
      L_print("mj_mob_name_required")
      return
    end
    local notes = trim(ebNotes:GetText())
    local rands = read_rand_fields()
    local critOff = read_crit_value(ebCritOff)
    local critDef = read_crit_value(ebCritDef)
    local ecritOff = read_failure_crit_value(ebECritOff)
    local ecritDef = read_failure_crit_value(ebECritDef)
    local dodgeBackPercent = read_dodge_back_percent()
    local survival = read_survival_values()
    if type(STATE.mj_mobs) ~= "table" then STATE.mj_mobs = {} end
    if mjFrame.editingMobId and STATE.mj_mobs[mjFrame.editingMobId] then
      local mob = STATE.mj_mobs[mjFrame.editingMobId]
      mob.name  = name
      mob.notes = notes
      mob.rands = rands
      mob.crit_off_success = critOff
      mob.crit_def_success = critDef
      mob.crit_off_failure_visual = ecritOff
      mob.crit_def_failure_visual = ecritDef
      mob.dodge_back_percent = dodgeBackPercent
      mob.hit_points = survival.hit_points
      mob.armor_type = survival.armor_type
      mob.durability_current = survival.durability_current
      mob.durability_max = survival.durability_max
      mob.durability_infinite = survival.durability_infinite
      mob.rda = survival.rda
      mob.rda_crit = survival.rda_crit
      mob.is_support = read_support_flag()
      mob.support_text = read_support_text()
    else
      local newId = next_mob_id(STATE)
      STATE.mj_mobs[newId] = {
        name = name,
        notes = notes,
        rands = rands,
        crit_off_success = critOff,
        crit_def_success = critDef,
        crit_off_failure_visual = ecritOff,
        crit_def_failure_visual = ecritDef,
        dodge_back_percent = dodgeBackPercent,
        hit_points = survival.hit_points,
        armor_type = survival.armor_type,
        durability_current = survival.durability_current,
        durability_max = survival.durability_max,
        durability_infinite = survival.durability_infinite,
        rda = survival.rda,
        rda_crit = survival.rda_crit,
        is_support = read_support_flag(),
        support_text = read_support_text(),
      }
      mjFrame.editingMobId = newId
    end
    _G.EASY_SANALUNE_SAVED_STATE = STATE
    RefreshMobList()
  end)

  btnDelete:SetScript("OnClick", function()
    local STATE = get_state()
    if not STATE then return end
    if not mjFrame.editingMobId or not (STATE.mj_mobs or {})[mjFrame.editingMobId] then
      L_print("mj_no_mob_selected")
      return
    end
    STATE.mj_mobs[mjFrame.editingMobId] = nil
    if STATE.mj_active_mob_id == mjFrame.editingMobId then
      STATE.mj_active_mob_id = nil
    end
    mjFrame.editingMobId = nil
    ebName:SetText("")
    ebNotes:SetText("")
    mjFrame.RefreshRandFields(nil)
    _G.EASY_SANALUNE_SAVED_STATE = STATE
    RefreshMobList()
  end)

  btnImport:SetScript("OnClick", function()
    if mjFrame.OpenImportModal then mjFrame.OpenImportModal() end
  end)

  -- Notifications section
  notifTitle = mjFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  notifTitle:SetPoint("TOPLEFT", btnResetMobs, "BOTTOMLEFT", 0, -10)
  notifTitle:SetText(L_get("mj_pending_requests"))
  style_font_string(notifTitle, true)

  local btnHistory = StdUi:Button(mjFrame, 92, 20, L_get("mj_history_button"))
  btnHistory:SetPoint("RIGHT", mjFrame, "RIGHT", -14, 0)
  btnHistory:SetPoint("CENTER", notifTitle, "CENTER", 0, 0)
  apply_button_theme(btnHistory)

  update_mj_reset_buttons_visibility()

  local notifScroll = StdUi:ScrollFrame(mjFrame, 360, 100)
  notifScroll:ClearAllPoints()
  notifScroll:SetPoint("TOPLEFT", notifTitle, "BOTTOMLEFT", 0, -3)
  notifScroll:SetPoint("BOTTOMLEFT", mjFrame, "BOTTOMLEFT", 14, 10)
  notifScroll:SetPoint("BOTTOMRIGHT", mjFrame, "BOTTOMRIGHT", -14, 10)
  apply_scrollbar_theme(notifScroll)
  mjFrame.notifScroll  = notifScroll
  mjFrame.notifContent = notifScroll.scrollChild
  mjFrame.notifRows    = {}

  local function ensure_mj_frame_fits()
    if not mjFrame or not mjFrame:IsShown() then return end
    local frameBottom = mjFrame:GetBottom()
    local notifTop = notifScroll:GetTop()
    if not frameBottom or not notifTop then return end
    local available = notifTop - frameBottom - 10
    local minNotifHeight = 96
    if available < minNotifHeight then
      local _, h = mjFrame:GetSize()
      mjFrame:SetHeight(h + (minNotifHeight - available))
    end
  end
  mjFrame.ensure_layout = ensure_mj_frame_fits
  mjFrame:HookScript("OnShow", function()
    C_Timer.After(0, function()
      if mjFrame and mjFrame.ensure_layout then
        mjFrame.ensure_layout()
      end
    end)
  end)

  local historyModal = nil
  local function open_history_modal()
    local history = UI.GetActionHistory and UI.GetActionHistory() or {}

    if not historyModal then
      historyModal = CreateFrame("Frame", "EasySanaluneMJHistoryModal", UIParent, "BackdropTemplate")
      historyModal:SetSize(430, 320)
      historyModal:SetFrameStrata("DIALOG")
      historyModal:SetFrameLevel(220)
      historyModal:EnableMouse(true)
      historyModal:SetClampedToScreen(true)
      apply_panel_theme(historyModal)
      make_modal_draggable(historyModal, "mj_history_modal")
      historyModal:Hide()

      local title = historyModal:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
      title:SetPoint("TOP", historyModal, "TOP", 0, -12)
      title:SetText(L_get("mj_history_title"))
      style_font_string(title, true)

      local scroll = StdUi:ScrollFrame(historyModal, 396, 228)
      scroll:SetPoint("TOPLEFT", historyModal, "TOPLEFT", 14, -38)
      apply_scrollbar_theme(scroll)
      historyModal.scroll = scroll

      local btnClose = StdUi:Button(historyModal, 100, 22, L_get("common_close"))
      btnClose:SetPoint("BOTTOMRIGHT", historyModal, "BOTTOMRIGHT", -14, 14)
      apply_button_theme(btnClose)
      btnClose:SetScript("OnClick", function()
        historyModal:Hide()
      end)
    end

    local content = historyModal.scroll and historyModal.scroll.scrollChild
    if not content then
      return
    end

    local children = { content:GetChildren() }
    for i = 1, #children do
      children[i]:Hide()
      children[i]:SetParent(nil)
    end

    local yOffset = 0
    if #history == 0 then
      local emptyFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      emptyFs:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -8)
      emptyFs:SetText(L_get("mj_history_empty"))
      style_font_string(emptyFs)
      yOffset = -32
    else
      for i = 1, #history do
        local entry = history[i]
        local row = CreateFrame("Frame", nil, content, "BackdropTemplate")
        row:SetSize(372, 48)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        row:SetBackdrop({
          bgFile = "Interface\\Buttons\\WHITE8X8",
          edgeFile = "Interface\\Buttons\\WHITE8X8",
          edgeSize = 1,
          insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        row:SetBackdropColor(0.08, 0.12, 0.22, 0.95)
        row:SetBackdropBorderColor(0.86, 0.80, 0.62, 0.75)

        local textFs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        textFs:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -6)
        textFs:SetPoint("RIGHT", row, "RIGHT", -88, 0)
        textFs:SetJustifyH("LEFT")
        textFs:SetJustifyV("TOP")
        textFs:SetText(build_history_entry_text(entry))
        style_font_string(textFs)

        if entry.replay then
          local replayBtn = StdUi:Button(row, 72, 18, L_get("mj_history_replay"))
          replayBtn:SetPoint("RIGHT", row, "RIGHT", -8, 0)
          apply_button_theme(replayBtn, true)
          replayBtn:SetScript("OnClick", function()
            if UI.ReplayActionHistoryEntry and UI.ReplayActionHistoryEntry(entry) then
              L_print("mj_history_replay_success")
              historyModal:Hide()
              if RefreshNotifications then
                RefreshNotifications()
              end
            else
              L_print("mj_history_replay_failed")
            end
          end)
        end

        yOffset = yOffset - 54
      end
    end

    content:SetHeight(math.max(40, -yOffset + 8))
    apply_modal_position(historyModal, "mj_history_modal")
    historyModal:Show()
  end

  btnHistory:SetScript("OnClick", function()
    open_history_modal()
  end)

  ------------------------------------------------------------
  -- Import Modal
  ------------------------------------------------------------
  local importModal = CreateFrame("Frame", "EasySanaluneImportModal", UIParent, "BackdropTemplate")
  importModal:SetSize(430, 260)
  importModal:SetFrameStrata("DIALOG")
  importModal:SetFrameLevel(200)
  importModal:EnableMouse(true)
  importModal:SetClampedToScreen(true)
  apply_panel_theme(importModal)
  make_modal_draggable(importModal, "import_modal")
  importModal:Hide()

  local impTitle = importModal:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  impTitle:SetPoint("TOP", importModal, "TOP", 0, -12)
  impTitle:SetText(L_get("mj_import_modal_title"))
  style_font_string(impTitle, true)

  local impHint = importModal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  impHint:SetPoint("TOPLEFT", importModal, "TOPLEFT", 14, -36)
  impHint:SetText(L_get("mj_import_modal_hint"))
  style_font_string(impHint)

  local impScroll = StdUi:ScrollFrame(importModal, 400, 148)
  impScroll:SetPoint("TOPLEFT", importModal, "TOPLEFT", 14, -54)
  apply_scrollbar_theme(impScroll)

  local impEb = StdUi:SimpleEditBox(impScroll.scrollChild, 390, 500, "")
  impEb:SetPoint("TOPLEFT", impScroll.scrollChild, "TOPLEFT", 0, 0)
  impEb:SetMultiLine(true)
  if impEb.SetWordWrap then impEb:SetWordWrap(true) end
  apply_editbox_theme(impEb)

  local btnImpCancel = StdUi:Button(importModal, 80, 22, L_get("common_cancel"))
  btnImpCancel:SetPoint("BOTTOMRIGHT", importModal, "BOTTOMRIGHT", -14, 14)
  apply_button_theme(btnImpCancel)
  btnImpCancel:SetScript("OnClick", function() importModal:Hide() end)

  local btnImpConfirm = StdUi:Button(importModal, 100, 22, L_get("common_import"))
  btnImpConfirm:SetPoint("RIGHT", btnImpCancel, "LEFT", -8, 0)
  apply_button_theme(btnImpConfirm, true)
  btnImpConfirm:SetScript("OnClick", function()
    local text   = impEb:GetText()
    local parsed = deserialize_profile(text)
    if not parsed then
      L_print("mj_import_invalid")
      return
    end
    local newId = import_as_mob(parsed)
    if newId then
      local S = get_state()
      local mobName = S and S.mj_mobs and S.mj_mobs[newId] and S.mj_mobs[newId].name or "?"
      L_print("mj_import_success", mobName)
      mjFrame.editingMobId = newId
      if S and S.mj_mobs and S.mj_mobs[newId] then
        ebName:SetText(S.mj_mobs[newId].name or "")
        ebNotes:SetText(S.mj_mobs[newId].notes or "")
        mjFrame.RefreshRandFields(newId)
      end
      RefreshMobList()
      importModal:Hide()
    else
      L_print("mj_import_error")
    end
  end)

  mjFrame.OpenImportModal = function()
    impEb:SetText("")
    apply_modal_position(importModal, "import_modal")
    importModal:Show()
  end

  return mjFrame
end

------------------------------------------------------------
-- Mob dropdown for notification rows
------------------------------------------------------------
local mjNotifMobDropdown  = nil
local mjNotifDropdownReqId = nil

local function CloseMobDropdown()
  if mjNotifMobDropdown then mjNotifMobDropdown:Hide() end
  mjNotifDropdownReqId = nil
end

local function OpenMobDropdown(anchorBtn, requestId)
  if not mjNotifMobDropdown then
    mjNotifMobDropdown = CreateFrame("Frame", "EasySanaluneNotifMobDrop", UIParent, "BackdropTemplate")
    mjNotifMobDropdown:SetFrameStrata("TOOLTIP")
    mjNotifMobDropdown:SetFrameLevel(500)
    mjNotifMobDropdown:EnableMouse(true)
    mjNotifMobDropdown:SetClampedToScreen(true)
    mjNotifMobDropdown:SetBackdrop({
      bgFile   = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Buttons\\WHITE8X8",
      edgeSize = 1,
      insets   = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    mjNotifMobDropdown:SetBackdropColor(0.05, 0.08, 0.15, 0.98)
    mjNotifMobDropdown:SetBackdropBorderColor(0.86, 0.80, 0.62, 0.95)
  end

  clear_widget_rows(mjNotifMobDropdown.dropRows)
  mjNotifMobDropdown.dropRows = {}

  local STATE   = get_state()
  local mobs    = (STATE and STATE.mj_mobs) or {}
  local sortedIds = {}
  for id in pairs(mobs) do
    sortedIds[#sortedIds + 1] = tonumber(id) or id
  end
  table.sort(sortedIds)

  local req   = UI.pendingMJRequests[requestId]
  local rowH  = 22
  local dropW = 182
  local yOff  = -2

  for _, mobId in ipairs(sortedIds) do
    local mob = mobs[mobId]
    if mob then
      local r = CreateFrame("Button", nil, mjNotifMobDropdown, "BackdropTemplate")
      r:SetSize(dropW - 4, rowH)
      r:SetPoint("TOPLEFT", mjNotifMobDropdown, "TOPLEFT", 2, yOff)
      r:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 },
      })
      local isSel = req and (req.selectedMobId == mobId)
      if isSel then
        r:SetBackdropColor(0.12, 0.20, 0.34, 0.95)
        r:SetBackdropBorderColor(0.86, 0.80, 0.62, 1.0)
      else
        r:SetBackdropColor(0.08, 0.14, 0.24, 0.95)
        r:SetBackdropBorderColor(0.20, 0.34, 0.55, 1)
      end
      local capturedMobId = mobId
      r:SetScript("OnEnter", function(self)
        local rr = UI.pendingMJRequests[requestId]
        if not (rr and rr.selectedMobId == capturedMobId) then
          self:SetBackdropColor(0.12, 0.20, 0.34, 0.95)
        end
      end)
      r:SetScript("OnLeave", function(self)
        local rr = UI.pendingMJRequests[requestId]
        if not (rr and rr.selectedMobId == capturedMobId) then
          self:SetBackdropColor(0.08, 0.14, 0.24, 0.95)
        end
      end)
      local fs = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      fs:SetPoint("LEFT", r, "LEFT", 6, 0)
      fs:SetText(mob.name or "?")
      fs:SetTextColor(0.95, 0.95, 0.95)
      local capturedReqId = requestId
      r:SetScript("OnClick", function()
        local req2 = UI.pendingMJRequests[capturedReqId]
        if req2 then req2.selectedMobId = capturedMobId end
        CloseMobDropdown()
        if RefreshNotifications then
          RefreshNotifications()
        end
      end)
      mjNotifMobDropdown.dropRows[#mjNotifMobDropdown.dropRows + 1] = r
      yOff = yOff - rowH - 2
    end
  end

  local totalH = math.max(26, #sortedIds * (rowH + 2) + 4)
  mjNotifMobDropdown:SetSize(dropW, totalH)
  mjNotifMobDropdown:ClearAllPoints()
  mjNotifMobDropdown:SetPoint("TOPLEFT", anchorBtn, "BOTTOMLEFT", 0, -2)
  mjNotifMobDropdown:Show()
  mjNotifDropdownReqId = requestId
end

------------------------------------------------------------
-- Notification refresh
------------------------------------------------------------
RefreshNotifications = function()
  if not mjFrame then return end

  local openReqId = mjNotifDropdownReqId

  clear_widget_rows(mjFrame.notifRows)
  mjFrame.notifRows = {}

  local content = mjFrame.notifContent
  if not content then return end

  local STATE   = get_state()
  local now     = GetTime()
  local yOffset = 0
  local notifMobButtons = {}

  -- Small button helper
  local function makeBtn(parent, label, w)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(w, 18)
    btn:SetBackdrop({
      bgFile   = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Buttons\\WHITE8X8",
      edgeSize = 1,
      insets   = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    btn:SetBackdropColor(0.13, 0.21, 0.37, 0.95)
    btn:SetBackdropBorderColor(0.86, 0.80, 0.62, 0.9)
    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("CENTER")
    fs:SetText(label)
    return btn
  end

  for requestId, req in pairs(UI.pendingMJRequests) do
    if (now - (req.time or 0)) < 120 then
      -- Initialise selectedMobId to active mob if not yet set
      if req.selectedMobId == nil and STATE and STATE.mj_active_mob_id then
        req.selectedMobId = STATE.mj_active_mob_id
      end

      -- Row: infoText(14) + gap(2) + mobSelBtn(18) + gap(2) + defBtns(18) + pad(10) = 64
      local rowH    = 64
      local rowStep = rowH + 4

      local row = CreateFrame("Frame", nil, content, "BackdropTemplate")
      row:SetSize(350, rowH)
      row:SetPoint("TOPLEFT", content, "TOPLEFT", 2, yOffset)
      row:SetPoint("RIGHT",   content, "RIGHT",   -2, 0)
      row:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 },
      })
      row:SetBackdropColor(0.08, 0.12, 0.22, 0.95)
      row:SetBackdropBorderColor(0.86, 0.80, 0.62, 0.8)

      -- Sender + rand info
      local infoText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      infoText:SetPoint("TOPLEFT", row, "TOPLEFT", 6, -4)
      infoText:SetText(string.format("%s : %s (%d-%d)",
        req.sender or "?", req.randName or "?", req.min or 0, req.max or 0))
      infoText:SetTextColor(0.95, 0.95, 0.95)

      -- Mob selector button (dropdown trigger)
      local mobs = (STATE and STATE.mj_mobs) or {}
      local selectedMob  = req.selectedMobId and mobs[req.selectedMobId]
      local selectedName = selectedMob and selectedMob.name or "aucun"
      local mobSelBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
      mobSelBtn:SetSize(180, 18)
      mobSelBtn:SetPoint("TOPLEFT", infoText, "BOTTOMLEFT", 0, -2)
      mobSelBtn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 },
      })
      mobSelBtn:SetBackdropColor(0.10, 0.16, 0.28, 0.95)
      mobSelBtn:SetBackdropBorderColor(0.86, 0.80, 0.62, 0.85)
      local mobSelNameFs = mobSelBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      mobSelNameFs:SetPoint("LEFT", mobSelBtn, "LEFT", 6, 0)
      mobSelNameFs:SetPoint("RIGHT", mobSelBtn, "RIGHT", -16, 0)
      mobSelNameFs:SetJustifyH("LEFT")
      mobSelNameFs:SetText(selectedName)
      mobSelNameFs:SetTextColor(1.0, 0.90, 0.70)

      local mobSelArrowFs = mobSelBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      mobSelArrowFs:SetPoint("RIGHT", mobSelBtn, "RIGHT", -6, 0)
      mobSelArrowFs:SetText("v")
      mobSelArrowFs:SetTextColor(1.0, 0.90, 0.70)
      local capturedId = requestId
      mobSelBtn:SetScript("OnClick", function()
        if mjNotifDropdownReqId == capturedId
            and mjNotifMobDropdown and mjNotifMobDropdown:IsShown() then
          CloseMobDropdown()
        else
          OpenMobDropdown(mobSelBtn, capturedId)
        end
      end)
      notifMobButtons[capturedId] = mobSelBtn

      -- Defense buttons
      local btnDP = makeBtn(row, "Def phys", 62)
      btnDP:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 6, 5)
      local btnDM = makeBtn(row, "Def mag", 62)
      btnDM:SetPoint("LEFT", btnDP, "RIGHT", 4, 0)
      local btnES = makeBtn(row, "Esquive", 58)
      btnES:SetPoint("LEFT", btnDM, "RIGHT", 4, 0)

      btnDP:SetScript("OnClick", function()
        local r = UI.pendingMJRequests[capturedId]
        local _, _, eMin, eMax = get_current_mj_form_rand_bounds("PHY_DEF")
        doMJRoll("PHY_DEF", capturedId, r and r.selectedMobId, eMin, eMax)
      end)
      btnDM:SetScript("OnClick", function()
        local r = UI.pendingMJRequests[capturedId]
        local _, _, eMin, eMax = get_current_mj_form_rand_bounds("MAG_DEF")
        doMJRoll("MAG_DEF", capturedId, r and r.selectedMobId, eMin, eMax)
      end)
      btnES:SetScript("OnClick", function()
        local r = UI.pendingMJRequests[capturedId]
        local _, _, eMin, eMax = get_current_mj_form_rand_bounds("DODGE")
        doMJRoll("DODGE", capturedId, r and r.selectedMobId, eMin, eMax)
      end)

      mjFrame.notifRows[#mjFrame.notifRows + 1] = row
      yOffset = yOffset - rowStep
    end
  end

  -- Keep dropdown open across periodic refreshes if its request still exists.
  if openReqId and openReqId ~= "" then
    local reqStillPresent = UI.pendingMJRequests and UI.pendingMJRequests[openReqId]
    local newAnchor = notifMobButtons[openReqId]
    if reqStillPresent and newAnchor then
      OpenMobDropdown(newAnchor, openReqId)
    else
      CloseMobDropdown()
    end
  end

  content:SetHeight(math.max(20, -yOffset + 4))
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------
function UI.ShowMJNotification(requestId)
  if not mjFrame then CreateMJFrame() end
  if mjFrame and not mjFrame:IsShown() then
    mjFrame:Show()
    RefreshMobList()
  end
  RefreshNotifications()
  if mjFrame and mjFrame.ensure_layout then
    mjFrame.ensure_layout()
  end
end

function UI.ToggleMJFrame()
  if not mjFrame then CreateMJFrame() end
  if not mjFrame then return end
  if mjFrame:IsShown() then
    mjFrame:Hide()
  else
    mjFrame:Show()
    RefreshMobList()
    RefreshNotifications()
    if mjFrame.ensure_layout then
      mjFrame.ensure_layout()
    end
  end
end

function UI.OpenMJFrame()
  if not mjFrame then CreateMJFrame() end
  if not mjFrame then return end
  if not mjFrame:IsShown() then
    mjFrame:Show()
  end
  RefreshMobList()
  RefreshNotifications()
  if mjFrame.ensure_layout then
    mjFrame.ensure_layout()
  end
end

-- Periodic notification refresh while frame is open
C_Timer.NewTicker(2, function()
  if mjFrame and mjFrame:IsShown() then
    RefreshNotifications()
    if mjFrame.ensure_layout then
      mjFrame.ensure_layout()
    end
  end
end)