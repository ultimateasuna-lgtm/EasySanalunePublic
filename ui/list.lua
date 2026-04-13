local UI = _G.EasySanaluneUI
if not UI then
  return
end

local INTERNALS = UI._internals or {}

---@return EasySanaluneState|nil
local function get_state()                        return INTERNALS.getState         and INTERNALS.getState()                    end
---@return any
local function get_stdui()                        return INTERNALS.getStdUi         and INTERNALS.getStdUi()                    end
local function parse_command(v)
  if type(INTERNALS.parse_command) == "function" then
    local minVal, maxVal, extra = INTERNALS.parse_command(v)
    if minVal and maxVal then
      return minVal, maxVal, extra
    end
  end

  local raw = tostring(v or "")
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

  local minVal, maxVal = string.match(raw, "^%s*(%d+)%s*%-%s*(%d+)%s*$")
  if not minVal or not maxVal then
    minVal, maxVal = string.match(string.lower(raw), "^%s*/?rand%s+(%d+)%s+(%d+)%s*$")
  end
  if not minVal or not maxVal then
    minVal, maxVal = string.match(raw, "^%D*(%d+)%D+(%d+)%D*$")
  end

  minVal = tonumber(minVal)
  maxVal = tonumber(maxVal)
  if minVal and maxVal then
    if minVal > maxVal then
      minVal, maxVal = maxVal, minVal
    end
    return minVal, maxVal, 0
  end
  return nil, nil, nil
end
local function copy_outcomes(v)                   return INTERNALS.copy_outcomes    and INTERNALS.copy_outcomes(v)    or {}      end
local function copy_outcome_ranges(v)             return INTERNALS.copy_outcome_ranges and INTERNALS.copy_outcome_ranges(v) or {} end
local function toggle_widgets(w, vis)    if INTERNALS.toggle_widgets    then INTERNALS.toggle_widgets(w, vis)       end end
local function apply_panel_theme(w, s, n) if INTERNALS.apply_panel_theme then INTERNALS.apply_panel_theme(w, s, n) end end
local function apply_button_theme(w, p)  if INTERNALS.apply_button_theme then INTERNALS.apply_button_theme(w, p)   end end
local function style_font_string(w, a)   if INTERNALS.style_font_string  then INTERNALS.style_font_string(w, a)   end end

local MAIN_LIST_ROW_HEIGHT = 24
local MAIN_LIST_SECTION_HEIGHT = 24
local MAIN_LIST_ICON_BUTTON_SIZE = 16
local MAIN_LIST_SECTION_ADD_BUTTON_WIDTH = 16
local MAIN_LIST_ROW_EDIT_BUTTON_WIDTH = 58
local MAIN_LIST_SECTION_EDIT_BUTTON_WIDTH = 56
local MAIN_LIST_VALUE_RIGHT_WITH_ACTIONS = -125
local MAIN_LIST_SYMBOL_FONT_SIZE = 10
local MAIN_LIST_SYMBOL_OFFSET_X = 0
local MAIN_LIST_SYMBOL_OFFSET_Y = 0
local MAIN_LIST_X_OFFSET_X = 0
local MAIN_LIST_X_OFFSET_Y = 1
local MAIN_LIST_CARET_OFFSET_X = 0
local MAIN_LIST_CARET_OFFSET_Y = 0

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
  local offsetX = MAIN_LIST_SYMBOL_OFFSET_X
  local offsetY = MAIN_LIST_SYMBOL_OFFSET_Y
  if symbol == "x" then
    offsetX = offsetX + MAIN_LIST_X_OFFSET_X
    offsetY = offsetY + MAIN_LIST_X_OFFSET_Y
  elseif symbol == "^" or symbol == "v" then
    offsetX = offsetX + MAIN_LIST_CARET_OFFSET_X
    offsetY = offsetY + MAIN_LIST_CARET_OFFSET_Y
  end

  label:ClearAllPoints()
  label:SetPoint("CENTER", button, "CENTER", offsetX, offsetY)
  label:SetText(symbol or "")
  if label.SetRotation then
    pcall(label.SetRotation, label, 0)
  end

  style_font_string(label, true)
  apply_font_size(label, MAIN_LIST_SYMBOL_FONT_SIZE)
  if label.SetJustifyH then
    label:SetJustifyH("CENTER")
  end
  if label.SetJustifyV then
    label:SetJustifyV("MIDDLE")
  end
end

local function escape_rand_announce_text(text)
  local value = tostring(text or "")
  value = string.gsub(value, "[\r\n]", " ")
  value = string.gsub(value, "|", "/")
  return value
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

local function create_action_button(parent, width, height, text, point, relativeTo, relativePoint, x, y, isPrimary, onClick)
  local StdUi = get_stdui()
  if not StdUi then
    return nil
  end

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

local function infer_rand_role_from_entry(entry)
  local explicit = string.lower(tostring(entry and entry.rand_role or ""))
  if explicit == "offensive" or explicit == "support" or explicit == "defensive" then
    return explicit
  end

  local raw = string.lower(tostring(entry and entry.name or ""))
  raw = string.gsub(raw, "[éèêë]", "e")
  raw = string.gsub(raw, "[àâä]", "a")
  raw = string.gsub(raw, "[îï]", "i")
  raw = string.gsub(raw, "[ôö]", "o")
  raw = string.gsub(raw, "[ùûü]", "u")
  raw = string.gsub(raw, "[^%w%s]", "")
  raw = string.gsub(raw, "%s+", " ")
  raw = string.gsub(raw, "^%s+", "")
  raw = string.gsub(raw, "%s+$", "")

  if raw == "soutien" or raw == "support" then
    return "support"
  end
  if raw == "defense physique" or raw == "defense magique" or raw == "esquive" or raw == "dodge" then
    return "defensive"
  end
  return "offensive"
end

local function get_rand_role_badge_text(entry)
  local role = infer_rand_role_from_entry(entry)
  if role == "support" then
    return "|cff8ad7ff[SOUT]|r"
  end
  if role == "defensive" then
    return "|cff7de28f[DEF]|r"
  end
  return "|cffffc86b[OFF]|r"
end

UI.make_scroll_elem = function(parent, charlink)
  local StdUi = get_stdui()
  local STATE = get_state()
  if not StdUi or not STATE then
    return nil
  end

  local obj = StdUi:Button(parent, 100, MAIN_LIST_ROW_HEIGHT)
  obj.infos = charlink
  apply_panel_theme(obj, true)
  if obj.SetBackdropColor then
    obj:SetBackdropColor(0.08, 0.13, 0.23, 0.9)
  end
  if obj.SetBackdropBorderColor then
    obj:SetBackdropBorderColor(0.96, 0.88, 0.48, 0.7)
  end

  local function set_rand_row_hover(hovered)
    if not obj or not obj.SetBackdropColor then
      return
    end
    if hovered then
      obj:SetBackdropColor(0.12, 0.20, 0.34, 0.95)
    else
      obj:SetBackdropColor(0.08, 0.13, 0.23, 0.9)
    end
  end

  local secure = CreateFrame("Button", nil, obj, "SecureActionButtonTemplate")
  -- Garde la couche secure a l'interieur de la bordure pour ne pas "manger" le cadre visuel.
  secure:SetPoint("TOPLEFT", obj, "TOPLEFT", 1, -1)
  secure:SetPoint("BOTTOMRIGHT", obj, "BOTTOMRIGHT", -1, 1)
  secure:SetFrameStrata(obj:GetFrameStrata())
  secure:SetFrameLevel(obj:GetFrameLevel() + 1)
  secure:RegisterForDrag("LeftButton")
  secure:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  secure:SetAttribute("type1", "macro")

  if secure.SetBackdrop then secure:SetBackdrop(nil) end
  if secure.SetBackdropColor then secure:SetBackdropColor(0, 0, 0, 0) end
  if secure.SetBackdropBorderColor then secure:SetBackdropBorderColor(0, 0, 0, 0) end
  local sNormal = secure.GetNormalTexture and secure:GetNormalTexture()
  local sPushed = secure.GetPushedTexture and secure:GetPushedTexture()
  local sHighlight = secure.GetHighlightTexture and secure:GetHighlightTexture()
  local sDisabled = secure.GetDisabledTexture and secure:GetDisabledTexture()
  if sNormal and sNormal.SetAlpha then sNormal:SetAlpha(0) end
  if sPushed and sPushed.SetAlpha then sPushed:SetAlpha(0) end
  if sHighlight and sHighlight.SetAlpha then sHighlight:SetAlpha(0) end
  if sDisabled and sDisabled.SetAlpha then sDisabled:SetAlpha(0) end

  local function get_effective_roll_values()
    local minVal, maxVal = parse_command(obj.infos.command)
    if not minVal or not maxVal then
      minVal, maxVal = parse_command(obj.infos.info)
    end
    if not minVal or not maxVal then
      return nil, nil, tostring(obj.infos.info or "")
    end

    if UI.Buffs and UI.Buffs.ApplyBonusToRange then
      minVal, maxVal = UI.Buffs.ApplyBonusToRange(obj.infos.name, minVal, maxVal, obj.infos.rand_role)
    end

    local displayInfo = tostring(obj.infos.info or "")
    if UI.Buffs and UI.Buffs.GetDisplayInfo then
      displayInfo = UI.Buffs.GetDisplayInfo(obj.infos)
    end

    return minVal, maxVal, displayInfo
  end

  local function get_display_name()
    local displayName = tostring(obj.infos.name or "")
    if UI.Buffs and UI.Buffs.GetDisplayName then
      displayName = UI.Buffs.GetDisplayName(obj.infos)
    end
    return displayName
  end

  local function update_macrotext()
    secure:SetAttribute("macrotext1", nil)
  end

  local function run_local_rand(min, max)
    if STATE and STATE.raid_announce then
      local channel = nil
      if IsInRaid() then
        channel = "RAID"
      elseif IsInGroup() then
        channel = "PARTY"
      end
      if channel then
        local announceText = string.format("Rand %s", escape_rand_announce_text(get_display_name()))
        ---@diagnostic disable-next-line:deprecated
        SendChatMessage(announceText, channel)
      end
    end
    RandomRoll(min, max)
  end

  update_macrotext()

  secure:SetScript("OnMouseDown", function(_, button)
    if button == "RightButton" then
      UI.open_edit_rand_form(obj.infos)
    end
  end)

  secure:SetScript("PreClick", function(_, button)
    if button ~= "LeftButton" then
      return
    end

    update_macrotext()

    local min, max, displayInfo = get_effective_roll_values()
    if not min or not max then
      return
    end

    local shouldPrompt = UI.ShouldPromptForOffensiveRand and UI.ShouldPromptForOffensiveRand(obj.infos.name, obj.infos and obj.infos.rand_role)

    UI.pendingRand = {
      time = GetTime(),
      min = min,
      max = max,
      outcomes = copy_outcomes(obj.infos.outcomes),
      outcomeRanges = copy_outcome_ranges(obj.infos.outcome_ranges),
    }

    if shouldPrompt then
      return
    end

    -- Notify MJ(s) if any exist
    if UI.SendRandRequest then
      UI.SendRandRequest(min, max, get_display_name(), displayInfo, obj.infos and obj.infos.rand_role)
    end
    run_local_rand(min, max)
  end)

  secure:SetScript("OnClick", function(_, button)
    if button ~= "LeftButton" then
      return
    end

    local shouldPrompt = UI.ShouldPromptForOffensiveRand and UI.ShouldPromptForOffensiveRand(obj.infos.name, obj.infos and obj.infos.rand_role)
    if not shouldPrompt then
      return
    end

    local min, max, displayInfo = get_effective_roll_values()
    if not min or not max then
      return
    end

    if UI.pendingRand == nil then
      UI.pendingRand = {
        time = GetTime(),
        min = min,
        max = max,
        outcomes = copy_outcomes(obj.infos.outcomes),
        outcomeRanges = copy_outcome_ranges(obj.infos.outcome_ranges),
      }
    end

    if UI.SendRandRequest then
      UI.SendRandRequest(min, max, get_display_name(), displayInfo, obj.infos and obj.infos.rand_role)
    end
  end)

  secure:SetScript("OnDragStart", function()
    UI.start_rand_drag(obj)
  end)

  secure:SetScript("OnDragStop", function()
    UI.stop_rand_drag(obj)
  end)

  local but_down = create_action_button(obj, MAIN_LIST_ICON_BUTTON_SIZE, MAIN_LIST_ICON_BUTTON_SIZE, "v", "RIGHT", obj, "RIGHT", -6, 0, false, function()
    UI.elem_move_down(obj)
  end)
  local but_up = create_action_button(obj, MAIN_LIST_ICON_BUTTON_SIZE, MAIN_LIST_ICON_BUTTON_SIZE, "^", "RIGHT", but_down, "LEFT", -4, 0, false, function()
    UI.elem_move_up(obj)
  end)
  local but_delete = create_action_button(obj, MAIN_LIST_ICON_BUTTON_SIZE, MAIN_LIST_ICON_BUTTON_SIZE, "x", "RIGHT", but_up, "LEFT", -4, 0, false, function()
    UI.elem_delete(obj)
  end)
  local but_edit = create_action_button(obj, MAIN_LIST_ROW_EDIT_BUTTON_WIDTH, 18, "Edit", "RIGHT", but_delete, "LEFT", -4, 0, false, function()
    UI.open_edit_rand_form(obj.infos)
  end)

  if but_down then but_down:SetFrameLevel(obj:GetFrameLevel() + 12) end
  if but_up then but_up:SetFrameLevel(obj:GetFrameLevel() + 12) end
  if but_delete then but_delete:SetFrameLevel(obj:GetFrameLevel() + 12) end
  if but_edit then but_edit:SetFrameLevel(obj:GetFrameLevel() + 12) end

  local actionButtons = { but_edit, but_delete, but_up, but_down }

  local check_inside = function()
    if UI.isResizing then
      set_widgets_visible(actionButtons, false)
      return
    end

    -- Disable hover if any menu is open globally
    if INTERNALS and INTERNALS.is_any_menu_open and INTERNALS.is_any_menu_open() then
      set_rand_row_hover(false)
      set_widgets_visible(actionButtons, false)
      return
    end

    if secure:IsMouseOver() or is_hovered_any(actionButtons) then
      set_rand_row_hover(true)
      set_widgets_visible({ but_up, but_down }, true)
      if not (obj.infos and obj.infos.is_default) then
        set_widgets_visible({ but_delete, but_edit }, true)
      else
        set_widgets_visible({ but_delete, but_edit }, false)
      end
    else
      set_rand_row_hover(false)
      set_widgets_visible(actionButtons, false)
    end
  end

  secure:SetScript("OnEnter", check_inside)
  secure:SetScript("OnLeave", check_inside)
  bind_hover_refresh(actionButtons, check_inside)

  local hoverCheckElapsed = 0
  obj:SetScript("OnUpdate", function(_, elapsed)
    hoverCheckElapsed = hoverCheckElapsed + (elapsed or 0)
    if hoverCheckElapsed >= 0.08 then
      hoverCheckElapsed = 0
      check_inside()
    end
  end)

  obj:SetScript("OnHide", function()
    set_rand_row_hover(false)
    set_widgets_visible(actionButtons, false)
  end)

  local fs_name = StdUi:FontString(obj, get_display_name())
  fs_name:SetPoint("LEFT", obj, "LEFT", 8, 0)
  local displayInfo = obj.infos.info
  if UI.Buffs and UI.Buffs.GetDisplayInfo then
    displayInfo = UI.Buffs.GetDisplayInfo(obj.infos)
  end

  local fs_role = StdUi:FontString(obj, get_rand_role_badge_text(obj.infos))
  style_font_string(fs_role, true)

  local fs_rand = StdUi:FontString(obj, displayInfo)
    style_font_string(fs_name)
    style_font_string(fs_rand, true)
  fs_rand:SetPoint("RIGHT", obj, "RIGHT", -10, 0)
  fs_role:SetPoint("RIGHT", fs_rand, "LEFT", -6, 0)

  if obj.infos and obj.infos.icon and obj.infos.icon ~= "" then
    local randIcon = obj:CreateTexture(nil, "ARTWORK")
    randIcon:SetSize(14, 14)
    randIcon:SetTexture(obj.infos.icon)
    randIcon:SetPoint("RIGHT", fs_role, "LEFT", -6, 0)
    fs_name:SetPoint("RIGHT", randIcon, "LEFT", -8, 0)
  else
    fs_name:SetPoint("RIGHT", fs_role, "LEFT", -8, 0)
  end

  fs_name:SetJustifyH("LEFT")
  if fs_name.SetWordWrap then
    fs_name:SetWordWrap(false)
  end
  if fs_rand.SetWordWrap then
    fs_rand:SetWordWrap(false)
  end

  local function set_info_anchor(showActions)
    fs_rand:ClearAllPoints()
    if showActions then
      -- Ancrer à gauche du premier bouton visible avec petit espacement
      local isDefault = obj.infos and obj.infos.is_default
      local anchorBtn = isDefault and but_up or but_edit
      fs_rand:SetPoint("RIGHT", anchorBtn, "LEFT", -6, 0)
    else
      fs_rand:SetPoint("RIGHT", obj, "RIGHT", -10, 0)
    end
    fs_role:ClearAllPoints()
    fs_role:SetPoint("RIGHT", fs_rand, "LEFT", -6, 0)
  end

  local baseCheckInside = check_inside
  check_inside = function()
    baseCheckInside()
    local showActions = secure:IsMouseOver() or is_hovered_any(actionButtons)
    if obj.infos and obj.infos.is_default then
      showActions = secure:IsMouseOver() or is_hovered_any({ but_up, but_down })
    end
    set_info_anchor(showActions)
  end

  secure:SetScript("OnEnter", check_inside)
  secure:SetScript("OnLeave", check_inside)
  bind_hover_refresh(actionButtons, check_inside)
  set_info_anchor(false)
  set_widgets_visible(actionButtons, false)

  return obj
end

UI.make_elem_add = function(parent)
  local StdUi = get_stdui()
  local STATE = get_state()
  if not StdUi or not STATE then
    return nil
  end

  local obj = StdUi:Button(parent, 100, 20)
  obj:SetSize(190, 20)
  apply_button_theme(obj, true)
  obj:SetScript("OnClick", function()
    UI.open_new_rand_form(function(newRand)
      STATE.CHARS[#STATE.CHARS + 1] = newRand
      UI.REFRESH()
    end)
  end)

  local fs_name = StdUi:FontString(obj, "Nouveau rand")
  fs_name:SetPoint("CENTER", obj, "CENTER", 0, 0)
  style_font_string(fs_name, true)
  return obj
end

UI.make_section_add = function(parent)
  local StdUi = get_stdui()
  local STATE = get_state()
  if not StdUi or not STATE then
    return nil
  end

  local obj = StdUi:Button(parent, 100, 20)
  obj:SetSize(190, 20)
  apply_button_theme(obj, true)
  obj:SetScript("OnClick", function()
    UI.open_new_section_form(function(newSection)
      STATE.CHARS[#STATE.CHARS + 1] = newSection
      UI.REFRESH()
    end)
  end)

  local fs_name = StdUi:FontString(obj, "Nouvelle categorie")
  fs_name:SetPoint("CENTER", obj, "CENTER", 0, 0)
  style_font_string(fs_name, true)
  return obj
end

UI.make_section_elem = function(parent, sectionData)
  local StdUi = get_stdui()
  if not StdUi then
    return nil
  end

  local obj = StdUi:Button(parent, 100, MAIN_LIST_SECTION_HEIGHT)
  obj.infos = sectionData
  obj.type = "section"
  local isFixedSection = sectionData and sectionData.is_fixed

  apply_panel_theme(obj, true, true)
  if obj.SetBackdropColor then
    obj:SetBackdropColor(0.10, 0.17, 0.30, 0.94)
  end
  if obj.SetBackdropBorderColor then
    obj:SetBackdropBorderColor(0.96, 0.88, 0.48, 0.85)
  end

  local function set_section_row_hover(hovered)
    if not obj or not obj.SetBackdropColor then
      return
    end
    if hovered then
      obj:SetBackdropColor(0.14, 0.23, 0.39, 0.96)
    else
      obj:SetBackdropColor(0.10, 0.17, 0.30, 0.94)
    end
  end

  obj:RegisterForDrag("LeftButton")
  obj:SetScript("OnDragStart", function()
    if isFixedSection then
      return
    end
    UI.start_section_drag(obj)
  end)

  obj:SetScript("OnDragStop", function()
    if isFixedSection then
      return
    end
    UI.stop_section_drag(obj)
  end)

  local but_add = create_action_button(obj, MAIN_LIST_SECTION_ADD_BUTTON_WIDTH, MAIN_LIST_ICON_BUTTON_SIZE, "+", "RIGHT", obj, "RIGHT", -6, 0, true, function()
    if isFixedSection then
      return
    end
    UI.open_new_rand_form(function(newRand)
      if not sectionData.items then
        sectionData.items = {}
      end
      sectionData.items[#sectionData.items + 1] = newRand
      sectionData.expanded = true
      UI.REFRESH()
    end)
  end)
  local but_down = create_action_button(obj, MAIN_LIST_ICON_BUTTON_SIZE, MAIN_LIST_ICON_BUTTON_SIZE, "v", "RIGHT", but_add, "LEFT", -4, 0, false, function()
    if isFixedSection then
      return
    end
    UI.elem_move_down(obj)
  end)
  local but_up = create_action_button(obj, MAIN_LIST_ICON_BUTTON_SIZE, MAIN_LIST_ICON_BUTTON_SIZE, "^", "RIGHT", but_down, "LEFT", -4, 0, false, function()
    if isFixedSection then
      return
    end
    UI.elem_move_up(obj)
  end)

  local editAnchor = but_up
  local but_delete = nil
  if not isFixedSection then
    but_delete = create_action_button(obj, MAIN_LIST_ICON_BUTTON_SIZE, MAIN_LIST_ICON_BUTTON_SIZE, "x", "RIGHT", but_up, "LEFT", -4, 0, false, function()
      UI.elem_delete(obj)
    end)
    editAnchor = but_delete
  end

  local but_edit = create_action_button(obj, MAIN_LIST_SECTION_EDIT_BUTTON_WIDTH, MAIN_LIST_ICON_BUTTON_SIZE, "Edit", "RIGHT", editAnchor, "LEFT", -4, 0, false, function()
    if not isFixedSection then
      UI.open_edit_section_form(sectionData)
    end
  end)

  local sectionActionButtons = { but_add, but_down, but_up, but_edit }
  if but_delete then
    sectionActionButtons[#sectionActionButtons + 1] = but_delete
  end

  obj:SetScript("OnMouseUp", function(_, button)
    if is_hovered_any(sectionActionButtons) then
      return
    end

    if button == "LeftButton" then
      sectionData.expanded = not sectionData.expanded
      UI.REFRESH()
    elseif button == "RightButton" and not isFixedSection then
      UI.open_edit_section_form(sectionData)
    end
  end)

  local check_inside = function()
    if UI.isResizing then
      set_widgets_visible(sectionActionButtons, false)
      return
    end

    if INTERNALS and INTERNALS.is_any_menu_open and INTERNALS.is_any_menu_open() then
      set_section_row_hover(false)
      set_widgets_visible(sectionActionButtons, false)
      return
    end

    if obj:IsMouseOver() or is_hovered_any(sectionActionButtons) then
      set_section_row_hover(true)
      set_widgets_visible(sectionActionButtons, true)
    else
      set_section_row_hover(false)
      set_widgets_visible(sectionActionButtons, false)
    end
  end

  obj:SetScript("OnEnter", check_inside)
  obj:SetScript("OnLeave", check_inside)
  bind_hover_refresh(sectionActionButtons, check_inside)

  local hoverCheckElapsed = 0
  obj:SetScript("OnUpdate", function(_, elapsed)
    hoverCheckElapsed = hoverCheckElapsed + (elapsed or 0)
    if hoverCheckElapsed >= 0.08 then
      hoverCheckElapsed = 0
      check_inside()
    end
  end)

  obj:SetScript("OnHide", function()
    set_section_row_hover(false)
    set_widgets_visible(sectionActionButtons, false)
  end)

  local itemCount = #(sectionData.items or {})
  local fs_name = StdUi:FontString(obj, string.format("%s (%d)", sectionData.name or "Categorie", itemCount))
  style_font_string(fs_name, true)

  local function set_title_anchor(showActions)
    fs_name:ClearAllPoints()
    fs_name:SetPoint("LEFT", obj, "LEFT", 6, 0)
    fs_name:SetPoint("RIGHT", obj, "RIGHT", -8, 0)
  end

  set_title_anchor(false)
  fs_name:SetJustifyH("LEFT")
  if fs_name.SetWordWrap then
    fs_name:SetWordWrap(false)
  end

  local baseCheckInside = check_inside
  check_inside = function()
    baseCheckInside()
    local showActions = obj:IsMouseOver() or is_hovered_any(sectionActionButtons)
    set_title_anchor(showActions)
  end

  obj:SetScript("OnEnter", check_inside)
  obj:SetScript("OnLeave", check_inside)
  bind_hover_refresh(sectionActionButtons, check_inside)
  set_widgets_visible(sectionActionButtons, false)

  return obj
end

UI.make_elem_form = function(obj)
  local StdUi = get_stdui()
  if not StdUi then
    return nil
  end

  local form_frame = StdUi:Panel(obj, 300, 90)
  form_frame.parent = obj
  form_frame:SetPoint("TOPLEFT", obj, "TOPLEFT", 2, -32)
  form_frame:SetPoint("RIGHT", obj, "RIGHT", -2, -2)

  local fs_name = StdUi:FontString(form_frame, "Titre : ")
  fs_name:SetPoint("TOPLEFT", form_frame, "TOPLEFT", 20, -5)
  style_font_string(fs_name)
  local fs_info = StdUi:FontString(form_frame, "Info : ")
  fs_info:SetPoint("TOPLEFT", form_frame, "TOPLEFT", 20, -25)
  style_font_string(fs_info)
  local fs_command = StdUi:FontString(form_frame, "Commande : ")
  fs_command:SetPoint("TOPLEFT", form_frame, "TOPLEFT", 20, -45)
  style_font_string(fs_command)

  local but_autocomplete = StdUi:Button(form_frame, 40, 20, 'Auto')
  but_autocomplete:SetPoint("LEFT", fs_command, "RIGHT", 5, 0)
  apply_button_theme(but_autocomplete)

  local eb_name = StdUi:SimpleEditBox(form_frame, 100, 20, obj.infos.name)
  eb_name:SetPoint("LEFT", fs_name, "RIGHT")
  eb_name:SetPoint("RIGHT", obj, "RIGHT", -20, 0)
  if INTERNALS.apply_editbox_theme then INTERNALS.apply_editbox_theme(eb_name) end

  local eb_info = StdUi:SimpleEditBox(form_frame, 100, 20, obj.infos.info)
  eb_info:SetPoint("LEFT", fs_info, "RIGHT")
  eb_info:SetPoint("RIGHT", obj, "RIGHT", -20, 0)
  if INTERNALS.apply_editbox_theme then INTERNALS.apply_editbox_theme(eb_info) end

  local eb_command = StdUi:SimpleEditBox(form_frame, 10, 20, obj.infos.command)
  eb_command:SetPoint("LEFT", but_autocomplete, "RIGHT")
  eb_command:SetPoint("RIGHT", obj, "RIGHT", -20, 0)
  if INTERNALS.apply_editbox_theme then INTERNALS.apply_editbox_theme(eb_command) end

  local but_ok = StdUi:Button(form_frame, 100, 20, 'Enregistrer')
  local but_cancel = StdUi:Button(form_frame, 100, 20, 'Annuler')
  but_ok:SetPoint("TOPLEFT", form_frame, "TOPLEFT", 20, -65)
  but_cancel:SetPoint("LEFT", but_ok, "RIGHT")
  apply_button_theme(but_ok, true)
  apply_button_theme(but_cancel)

  but_autocomplete:SetScript("OnClick", function()
    eb_command:SetText("1-100")
  end)

  but_ok:SetScript("OnClick", function()
    obj.infos.name = eb_name:GetText()
    obj.infos.info = eb_info:GetText()
    obj.infos.command = eb_command:GetText()
    form_frame:Hide()
    UI.REFRESH()
  end)

  but_cancel:SetScript("OnClick", function()
    form_frame:Hide()
  end)

  return form_frame
end

UI.close_all_elem_forms = function()
  for i = 1, #UI.form_list do
    local form = UI.form_list[i]
    if form and form.parent then
      form.parent.formIsOpen = false
    end
    if form then
      form:Hide()
    end
  end
end
