local UI = _G.EasySanaluneUI
if not UI then
  return
end

local INTERNALS = UI._internals or {}

local function L_get(key, ...)
  if INTERNALS.l_get then return INTERNALS.l_get(key, ...) end
  return select("#",...) > 0 and string.format(tostring(key),...) or tostring(key)
end
local function L_print(key, ...) if INTERNALS.l_print then INTERNALS.l_print(key, ...) end end

local function get_state()                           return INTERNALS.getState            and INTERNALS.getState()                      end
local function get_stdui()                           return INTERNALS.getStdUi            and INTERNALS.getStdUi()                      end
local function copy_outcomes(v)                      return INTERNALS.copy_outcomes       and INTERNALS.copy_outcomes(v)       or {}     end
local function copy_outcome_ranges(v)                return INTERNALS.copy_outcome_ranges and INTERNALS.copy_outcome_ranges(v)  or {}     end
local function parse_command(v)
  if type(INTERNALS.parse_command) == "function" then
    return INTERNALS.parse_command(v)
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
local function make_modal_draggable(m, k)    if INTERNALS.make_modal_draggable   then INTERNALS.make_modal_draggable(m, k)    end end
local function apply_modal_position(m, k)    if INTERNALS.apply_modal_position    then INTERNALS.apply_modal_position(m, k)    end end
local function add_outcome_to_modal(m, ev, et, u)    if INTERNALS.add_outcome_to_modal    then INTERNALS.add_outcome_to_modal(m, ev, et, u)    end end
local function remove_outcome_from_modal(m, ev, et, u) if INTERNALS.remove_outcome_from_modal then INTERNALS.remove_outcome_from_modal(m, ev, et, u) end end
local function apply_panel_theme(w, s, n)     if INTERNALS.apply_panel_theme       then INTERNALS.apply_panel_theme(w, s, n)     end end
local function apply_button_theme(w, p)      if INTERNALS.apply_button_theme      then INTERNALS.apply_button_theme(w, p)      end end
local function apply_editbox_theme(w)        if INTERNALS.apply_editbox_theme     then INTERNALS.apply_editbox_theme(w)        end end
local function apply_scrollbar_theme(w)      if INTERNALS.apply_scrollbar_theme   then INTERNALS.apply_scrollbar_theme(w)      end end
local function style_font_string(w, a)       if INTERNALS.style_font_string       then INTERNALS.style_font_string(w, a)       end end

local function trim_text(value)
  return (tostring(value or "")):match("^%s*(.-)%s*$")
end

local function normalize_command_text(cmd)
  local minVal, maxVal = parse_command(cmd)
  if not minVal or not maxVal then
    return nil
  end
  return string.format("%d-%d", minVal, maxVal)
end

local RAND_ROLE_OPTIONS = {
  { key = "offensive", label = L_get("rand_role_offensive") },
  { key = "support", label = L_get("rand_role_support") },
  { key = "defensive", label = L_get("rand_role_defensive") },
}

local function infer_rand_role_from_name(value)
  local raw = string.lower(trim_text(value))
  raw = string.gsub(raw, "[éèêë]", "e")
  raw = string.gsub(raw, "[àâä]", "a")
  raw = string.gsub(raw, "[îï]", "i")
  raw = string.gsub(raw, "[ôö]", "o")
  raw = string.gsub(raw, "[ùûü]", "u")
  raw = string.gsub(raw, "[^%w%s]", "")
  raw = string.gsub(raw, "%s+", " ")
  raw = trim_text(raw)

  if raw == "soutien" or raw == "support" then
    return "support"
  end
  if raw == "defense physique" or raw == "defense magique" or raw == "esquive" or raw == "dodge" then
    return "defensive"
  end
  return "offensive"
end

local function normalize_rand_role(value, nameFallback)
  local key = string.lower(trim_text(value))
  if key == "offensive" or key == "support" or key == "defensive" then
    return key
  end
  return infer_rand_role_from_name(nameFallback)
end

local function build_outcomes_label_updater(modal, outcomesLabel, outcomesContent)
  return function()
    local lines = {}
    local exactKeys = {}
    for k, v in pairs(modal.outcomes or {}) do
      local idx = tonumber(k)
      if idx and v and v ~= "" then
        table.insert(exactKeys, idx)
      end
    end
    table.sort(exactKeys)
    for i = 1, #exactKeys do
      local idx = exactKeys[i]
      table.insert(lines, string.format("%d = %s", idx, tostring(modal.outcomes[idx])))
    end

    local ranges = modal.outcomeRanges or {}
    table.sort(ranges, function(a, b)
      if a.min == b.min then
        return a.max < b.max
      end
      return a.min < b.min
    end)
    for i = 1, #ranges do
      local entry = ranges[i]
      table.insert(lines, string.format("%d-%d = %s", entry.min, entry.max, entry.text))
    end

    local text = #lines > 0 and (L_get("modal_issues_title") .. "\n" .. table.concat(lines, "\n")) or L_get("modal_issues_none")
    outcomesLabel:SetText(text)
    local neededHeight = outcomesLabel:GetStringHeight() + 8
    if neededHeight < 76 then
      neededHeight = 76
    end
    outcomesContent:SetHeight(neededHeight)
  end
end

local ICON_BANK_MAX = 1500

local EPSILON_ICON_PATHS = {
  "Interface\\AddOns\\EpsilonLib\\Resources\\Epsilon_Icon.blp",
  "Interface\\AddOns\\Epsilon_AuraManager\\Texture\\EpsilonAuraIcon.blp",
  "Interface\\AddOns\\Epsilon_Launcher\\assets\\EpsilonTrayIcon.blp",
  "Interface\\AddOns\\Epsilon_Launcher\\assets\\EpsilonTrayIcon2025.blp",
  "Interface\\AddOns\\Epsilon_Launcher\\assets\\EpsilonBlueprintManagerIcon.blp",
  "Interface\\AddOns\\Epsilon_Launcher\\assets\\EpsilonBlueprintManagerIcon2025.blp",
  "Interface\\AddOns\\Epsilon_Merchant\\Icons\\SellJunk.tga",
  "Interface\\AddOns\\Epsilon_Phase_Codex\\assets\\CodexAdd.blp",
  "Interface\\AddOns\\Epsilon_Phase_Codex\\assets\\CodexDelete.blp",
  "Interface\\AddOns\\Epsilon_Phase_Codex\\assets\\CodexSave.blp",
}

local function set_icon_preview(textureWidget, icon)
  if not textureWidget then
    return
  end
  if icon and icon ~= "" then
    textureWidget:SetTexture(icon)
    textureWidget:Show()
  else
    textureWidget:SetTexture(nil)
    textureWidget:Hide()
  end
end

local function build_icon_bank()
  local icons = {}
  local dedup = {}
  local result = {}

  local function normalize_icon_path(icon)
    if type(icon) ~= "string" then
      return nil
    end
    if icon == "" then
      return nil
    end
    if string.find(icon, "\\") or string.find(icon, "/") then
      return icon
    end
    return "Interface\\ICONS\\" .. icon
  end

  local function add_icon(icon)
    local normalized = normalize_icon_path(icon)
    if normalized and not dedup[normalized] then
      dedup[normalized] = true
      result[#result + 1] = normalized
    end
  end

  if type(GetMacroIcons) == "function" then
    pcall(GetMacroIcons, icons)
  end

  if type(GetLooseMacroIcons) == "function" then
    pcall(GetLooseMacroIcons, icons)
  end

  if type(GetLooseMacroItemIcons) == "function" then
    pcall(GetLooseMacroItemIcons, icons)
  end

  for i = 1, #icons do
    add_icon(icons[i])
  end

  local trp3Api = rawget(_G, "TRP3_API")
  if trp3Api
      and trp3Api.utils
      and trp3Api.utils.resources
      and type(trp3Api.utils.resources.getIconList) == "function" then
    local ok, trpIcons = pcall(trp3Api.utils.resources.getIconList, "")
    if ok and type(trpIcons) == "table" then
      for i = 1, #trpIcons do
        add_icon(trpIcons[i])
      end
    end
  end

  for i = 1, #EPSILON_ICON_PATHS do
    add_icon(EPSILON_ICON_PATHS[i])
  end

  return result
end

local function open_icon_picker(currentIcon, onSelect)
  local StdUi = get_stdui()
  if not StdUi or not onSelect then
    return
  end

  if not UI.ICON_PICKER_MODAL then
    local modal = StdUi:Panel(UIParent, 430, 360)
    modal:SetFrameStrata("DIALOG")
    modal:SetFrameLevel(250)
    modal:EnableMouse(true)
    modal:ClearAllPoints()
    modal:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    apply_panel_theme(modal)
    make_modal_draggable(modal, "icon_picker")
    apply_modal_position(modal, "icon_picker")
    modal:Hide()

    local title = StdUi:FontString(modal, L_get("modal_icon_picker_title"))
    title:SetPoint("TOP", modal, "TOP", 0, -10)
    style_font_string(title, true)

    local iconScroll = StdUi:ScrollFrame(modal, 402, 250)
    iconScroll:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -32)
    apply_scrollbar_theme(iconScroll)
    local iconContent = iconScroll.scrollChild

    local btnUse = StdUi:Button(modal, 120, 22, L_get("modal_icon_use"))
    btnUse:SetPoint("BOTTOMLEFT", modal, "BOTTOMLEFT", 24, 14)
    local btnNone = StdUi:Button(modal, 120, 22, L_get("modal_icon_none"))
    btnNone:SetPoint("LEFT", btnUse, "RIGHT", 8, 0)
    local btnCancel = StdUi:Button(modal, 120, 22, L_get("common_close"))
    btnCancel:SetPoint("LEFT", btnNone, "RIGHT", 8, 0)

    apply_button_theme(btnUse, true)
    apply_button_theme(btnNone)
    apply_button_theme(btnCancel)

    local lblSearch = StdUi:FontString(modal, L_get("modal_search"))
    lblSearch:SetPoint("BOTTOMLEFT", modal, "BOTTOMLEFT", 14, 47)
    style_font_string(lblSearch)
    local ebSearch = StdUi:SimpleEditBox(modal, 170, 20, "")
    ebSearch:SetPoint("LEFT", lblSearch, "RIGHT", 8, 0)
    apply_editbox_theme(ebSearch)

    local lblSelected = StdUi:FontString(modal, L_get("modal_selection"))
    lblSelected:SetPoint("LEFT", ebSearch, "RIGHT", 10, 0)
    style_font_string(lblSelected, true)

    local selectedPreviewFrame = CreateFrame("Frame", nil, modal, "BackdropTemplate")
    selectedPreviewFrame:SetSize(26, 26)
    selectedPreviewFrame:SetPoint("LEFT", lblSelected, "RIGHT", 6, 0)
    selectedPreviewFrame:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      edgeSize = 10,
      insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    selectedPreviewFrame:SetBackdropColor(0.06, 0.10, 0.18, 0.95)
    selectedPreviewFrame:SetBackdropBorderColor(0.62, 0.72, 0.90, 0.9)

    local selectedPreview = selectedPreviewFrame:CreateTexture(nil, "ARTWORK")
    selectedPreview:SetPoint("TOPLEFT", selectedPreviewFrame, "TOPLEFT", 2, -2)
    selectedPreview:SetPoint("BOTTOMRIGHT", selectedPreviewFrame, "BOTTOMRIGHT", -2, 2)

    local function update_selected_preview(icon)
      if icon and icon ~= "" then
        selectedPreview:SetTexture(icon)
        selectedPreview:Show()
      else
        selectedPreview:SetTexture(nil)
        selectedPreview:Hide()
      end
    end

    modal.iconButtons = {}
    modal.icons = build_icon_bank()
    modal.pendingIcon = nil
    modal.onSelect = nil

    local columns = 11
    local cellSize = 30
    local gap = 5
    local maxIcons = min(#modal.icons, ICON_BANK_MAX)
    local lastButton = nil

    for i = 1, maxIcons do
      local icon = modal.icons[i]
      local btn = StdUi:Button(iconContent, cellSize, cellSize, "")
      local tex = btn:CreateTexture(nil, "ARTWORK")
      tex:SetPoint("TOPLEFT", btn, "TOPLEFT", 4, -4)
      tex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -4, 4)
      tex:SetTexture(icon)
      btn.iconTexture = tex
      btn.iconValue = icon

      local col = (i - 1) % columns
      local row = math.floor((i - 1) / columns)
      btn:SetPoint("TOPLEFT", iconContent, "TOPLEFT", col * (cellSize + gap), -row * (cellSize + gap))

      btn:SetScript("OnClick", function(self)
        modal.pendingIcon = self.iconValue
        update_selected_preview(self.iconValue)
        for j = 1, #modal.iconButtons do
          local candidate = modal.iconButtons[j]
          if candidate and candidate.SetBackdropBorderColor then
            if candidate == self then
              candidate:SetBackdropBorderColor(1, 0.85, 0, 1)
            else
              candidate:SetBackdropBorderColor(0, 0, 0, 1)
            end
          end
        end
      end)

      modal.iconButtons[#modal.iconButtons + 1] = btn
      lastButton = btn
    end

    if lastButton then
      local bottom = lastButton:GetBottom()
      local top = iconContent:GetTop()
      if bottom and top then
        local h = top - bottom + 8
        if h > 0 then
          iconContent:SetHeight(h)
        end
      end
    end

    modal.applyFilter = function(filterText)
      local filter = string.lower(tostring(filterText or ""))
      local visibleIndex = 0

      for i = 1, #modal.iconButtons do
        local btn = modal.iconButtons[i]
        local icon = btn and btn.iconValue
        local show = true

        if filter ~= "" then
          local hay = string.lower(tostring(icon or ""))
          show = string.find(hay, filter, 1, true) ~= nil
        end

        if show and btn then
          visibleIndex = visibleIndex + 1
          local col = (visibleIndex - 1) % columns
          local row = math.floor((visibleIndex - 1) / columns)
          btn:ClearAllPoints()
          btn:SetPoint("TOPLEFT", iconContent, "TOPLEFT", col * (cellSize + gap), -row * (cellSize + gap))
          btn:Show()
        elseif btn then
          btn:Hide()
        end
      end

      if visibleIndex > 0 then
        local rows = math.floor((visibleIndex - 1) / columns) + 1
        local height = rows * (cellSize + gap) + 8
        iconContent:SetHeight(height)
      else
        iconContent:SetHeight(40)
      end
    end

    ebSearch:SetScript("OnTextChanged", function(self)
      modal.applyFilter(self:GetText())
    end)

    btnUse:SetScript("OnClick", function()
      local value = modal.pendingIcon
      local callback = modal.onSelect
      modal:Hide()
      if callback then
        callback(value)
      end
    end)

    btnNone:SetScript("OnClick", function()
      local callback = modal.onSelect
      modal:Hide()
      if callback then
        callback(nil)
      end
    end)

    btnCancel:SetScript("OnClick", function()
      modal:Hide()
    end)

    modal.updateSelection = function(selected)
      modal.pendingIcon = selected
      update_selected_preview(selected)
      ebSearch:SetText("")
      modal.applyFilter("")
      for i = 1, #modal.iconButtons do
        local btn = modal.iconButtons[i]
        if btn and btn.SetBackdropBorderColor then
          if selected and btn.iconValue == selected then
            btn:SetBackdropBorderColor(1, 0.85, 0, 1)
          else
            btn:SetBackdropBorderColor(0, 0, 0, 1)
          end
        end
      end
    end

    UI.ICON_PICKER_MODAL = modal
  end

  local modal = UI.ICON_PICKER_MODAL
  modal.onSelect = onSelect
  modal.updateSelection(currentIcon)
  modal:Show()
end

UI.open_new_rand_form = function(onAccept)
  local StdUi = get_stdui()
  if not StdUi then
    return
  end

  if not UI.NEW_RAND_MODAL then
    local modal = StdUi:Panel(UIParent, 360, 360)
    modal:SetFrameStrata("DIALOG")
    modal:SetFrameLevel(200)
    modal:EnableMouse(true)
    apply_panel_theme(modal)
    modal:Hide()
    make_modal_draggable(modal, "new_rand")
    apply_modal_position(modal, "new_rand")

    local title = StdUi:FontString(modal, L_get("modal_new_rand_title"))
    title:SetPoint("TOP", modal, "TOP", 0, -10)
    style_font_string(title, true)

    local lblName = StdUi:FontString(modal, L_get("modal_label_name"))
    lblName:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -35)
    style_font_string(lblName)
    local ebName = StdUi:SimpleEditBox(modal, 230, 20, "")
    ebName:SetPoint("LEFT", lblName, "RIGHT", 8, 0)
    apply_editbox_theme(ebName)

    local lblInfo = StdUi:FontString(modal, L_get("modal_label_info"))
    lblInfo:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -62)
    style_font_string(lblInfo)
    local ebInfo = StdUi:SimpleEditBox(modal, 230, 20, "1-100")
    ebInfo:SetPoint("LEFT", lblInfo, "RIGHT", 10, 0)
    apply_editbox_theme(ebInfo)

    local lblCmd = StdUi:FontString(modal, L_get("modal_label_rand"))
    lblCmd:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -89)
    style_font_string(lblCmd)
    local ebCmd = StdUi:SimpleEditBox(modal, 230, 20, "1-100")
    ebCmd:SetPoint("LEFT", lblCmd, "RIGHT", 7, 0)
    apply_editbox_theme(ebCmd)

    local lblRole = StdUi:FontString(modal, L_get("modal_label_rand_role"))
    lblRole:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -116)
    style_font_string(lblRole)

    local btnRoleOff = StdUi:Button(modal, 92, 20, L_get("rand_role_offensive"))
    btnRoleOff:SetPoint("LEFT", lblRole, "RIGHT", 8, 0)
    local btnRoleSupport = StdUi:Button(modal, 92, 20, L_get("rand_role_support"))
    btnRoleSupport:SetPoint("LEFT", btnRoleOff, "RIGHT", 4, 0)
    local btnRoleDef = StdUi:Button(modal, 92, 20, L_get("rand_role_defensive"))
    btnRoleDef:SetPoint("LEFT", btnRoleSupport, "RIGHT", 4, 0)

    local lblIcon = StdUi:FontString(modal, L_get("modal_label_icon"))
    lblIcon:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -143)
    style_font_string(lblIcon)
    local iconPreview = modal:CreateTexture(nil, "ARTWORK")
    iconPreview:SetSize(18, 18)
    iconPreview:SetPoint("LEFT", lblIcon, "RIGHT", 8, 0)
    local btnPickIcon = StdUi:Button(modal, 90, 20, L_get("modal_choose"))
    btnPickIcon:SetPoint("LEFT", iconPreview, "RIGHT", 8, 0)
    local btnClearIcon = StdUi:Button(modal, 70, 20, L_get("modal_icon_none"))
    btnClearIcon:SetPoint("LEFT", btnPickIcon, "RIGHT", 6, 0)

    local lblOutcomeValue = StdUi:FontString(modal, L_get("modal_label_result"))
    lblOutcomeValue:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -173)
    style_font_string(lblOutcomeValue)
    local ebOutcomeValue = StdUi:SimpleEditBox(modal, 45, 20, "")
    ebOutcomeValue:SetPoint("LEFT", lblOutcomeValue, "RIGHT", 8, 0)
    apply_editbox_theme(ebOutcomeValue)

    local lblOutcomeText = StdUi:FontString(modal, L_get("modal_label_action"))
    lblOutcomeText:SetPoint("LEFT", ebOutcomeValue, "RIGHT", 12, 0)
    style_font_string(lblOutcomeText)
    local ebOutcomeText = StdUi:SimpleEditBox(modal, 130, 20, "")
    ebOutcomeText:SetPoint("LEFT", lblOutcomeText, "RIGHT", 8, 0)
    apply_editbox_theme(ebOutcomeText)

    local btnAddOutcome = StdUi:Button(modal, 110, 20, L_get("modal_add_outcome"))
    btnAddOutcome:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -201)
    local btnRemoveOutcome = StdUi:Button(modal, 110, 20, L_get("modal_remove_outcome"))
    btnRemoveOutcome:SetPoint("LEFT", btnAddOutcome, "RIGHT", 8, 0)

    local outcomesScroll = StdUi:ScrollFrame(modal, 332, 90)
    outcomesScroll:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -227)
    apply_scrollbar_theme(outcomesScroll)
    local outcomesContent = outcomesScroll.scrollChild
    local outcomesLabel = StdUi:FontString(outcomesContent, L_get("modal_issues_none"))
    outcomesLabel:SetPoint("TOPLEFT", outcomesContent, "TOPLEFT", 0, 0)
    outcomesLabel:SetWidth(312)
    outcomesLabel:SetJustifyH("LEFT")
    outcomesLabel:SetJustifyV("TOP")

    local btnOk = StdUi:Button(modal, 110, 22, L_get("modal_create"))
    btnOk:SetPoint("BOTTOMLEFT", modal, "BOTTOMLEFT", 70, 14)
    local btnCancel = StdUi:Button(modal, 110, 22, L_get("common_cancel"))
    btnCancel:SetPoint("LEFT", btnOk, "RIGHT", 8, 0)
    apply_button_theme(btnPickIcon)
    apply_button_theme(btnClearIcon)
    apply_button_theme(btnRoleOff)
    apply_button_theme(btnRoleSupport)
    apply_button_theme(btnRoleDef)
    apply_button_theme(btnAddOutcome)
    apply_button_theme(btnRemoveOutcome)
    apply_button_theme(btnOk, true)
    apply_button_theme(btnCancel)

    local roleButtons = {
      offensive = btnRoleOff,
      support = btnRoleSupport,
      defensive = btnRoleDef,
    }
    local function set_selected_role(roleKey)
      modal.selectedRandRole = normalize_rand_role(roleKey, modal.ebName and modal.ebName:GetText() or "")
      for _, option in ipairs(RAND_ROLE_OPTIONS) do
        local btn = roleButtons[option.key]
        if btn then
          apply_button_theme(btn, option.key == modal.selectedRandRole)
          if option.key == modal.selectedRandRole then
            if btn.SetBackdropColor then
              btn:SetBackdropColor(0.18, 0.45, 0.18, 0.95)
            end
            if btn.SetBackdropBorderColor then
              btn:SetBackdropBorderColor(0.30, 0.85, 0.30, 0.9)
            end
          end
        end
      end
    end

    btnRoleOff:SetScript("OnClick", function() set_selected_role("offensive") end)
    btnRoleSupport:SetScript("OnClick", function() set_selected_role("support") end)
    btnRoleDef:SetScript("OnClick", function() set_selected_role("defensive") end)

    local update_outcomes_label = build_outcomes_label_updater(modal, outcomesLabel, outcomesContent)

    btnAddOutcome:SetScript("OnClick", function()
      add_outcome_to_modal(modal, ebOutcomeValue, ebOutcomeText, update_outcomes_label)
    end)

    btnRemoveOutcome:SetScript("OnClick", function()
      remove_outcome_from_modal(modal, ebOutcomeValue, ebOutcomeText, update_outcomes_label)
    end)

    btnPickIcon:SetScript("OnClick", function()
      open_icon_picker(modal.selectedIcon, function(icon)
        modal.selectedIcon = icon
        set_icon_preview(iconPreview, icon)
      end)
    end)

    btnClearIcon:SetScript("OnClick", function()
      modal.selectedIcon = nil
      set_icon_preview(iconPreview, nil)
    end)

    btnOk:SetScript("OnClick", function()
      local name = trim_text(ebName:GetText())
      local info = trim_text(ebInfo:GetText())
      local cmd = trim_text(ebCmd:GetText())

      if name == "" then
        L_print("rand_name_required")
        return
      end

      local normalizedCmd = normalize_command_text(cmd)
      if not normalizedCmd then
        L_print("rand_format_invalid")
        return
      end
      cmd = normalizedCmd

      if info == "" then
        info = cmd
      end

      local callback = modal.onAccept
      modal:Hide()
      if callback then
        callback({
          type = "rand",
          name = name,
          info = info,
          command = cmd,
          rand_role = normalize_rand_role(modal.selectedRandRole, name),
          icon = modal.selectedIcon,
          is_default = false,
          outcomes = copy_outcomes(modal.outcomes),
          outcome_ranges = copy_outcome_ranges(modal.outcomeRanges),
        })
      end
    end)

    btnCancel:SetScript("OnClick", function()
      modal:Hide()
    end)

    modal.ebName = ebName
    modal.ebInfo = ebInfo
    modal.ebCmd = ebCmd
    modal.iconPreview = iconPreview
    modal.selectedIcon = nil
    modal.ebOutcomeValue = ebOutcomeValue
    modal.ebOutcomeText = ebOutcomeText
    modal.updateOutcomesLabel = update_outcomes_label
    modal.setSelectedRole = set_selected_role
    UI.NEW_RAND_MODAL = modal
  end

  local modal = UI.NEW_RAND_MODAL
  modal.onAccept = onAccept
  modal.ebName:SetText("")
  modal.ebInfo:SetText("1-100")
  modal.ebCmd:SetText("1-100")
  modal.selectedIcon = nil
  set_icon_preview(modal.iconPreview, nil)
  modal.outcomes = {}
  modal.outcomeRanges = {}
  modal.ebOutcomeValue:SetText("")
  modal.ebOutcomeText:SetText("")
  modal.updateOutcomesLabel()
  modal.setSelectedRole("offensive")
  modal:Show()
  modal.ebName:SetFocus()
end

UI.open_edit_rand_form = function(randData)
  local StdUi = get_stdui()
  if not StdUi or not randData then
    return
  end

  if not UI.EDIT_RAND_MODAL then
    local modal = StdUi:Panel(UIParent, 360, 360)
    modal:SetFrameStrata("DIALOG")
    modal:SetFrameLevel(200)
    modal:EnableMouse(true)
    apply_panel_theme(modal)
    modal:Hide()
    make_modal_draggable(modal, "edit_rand")
    apply_modal_position(modal, "edit_rand")

    local title = StdUi:FontString(modal, L_get("modal_edit_rand_title"))
    title:SetPoint("TOP", modal, "TOP", 0, -10)
    style_font_string(title, true)

    local lblName = StdUi:FontString(modal, L_get("modal_label_name"))
    lblName:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -35)
    style_font_string(lblName)
    local ebName = StdUi:SimpleEditBox(modal, 230, 20, "")
    ebName:SetPoint("LEFT", lblName, "RIGHT", 8, 0)
    apply_editbox_theme(ebName)

    local lblInfo = StdUi:FontString(modal, L_get("modal_label_info"))
    lblInfo:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -62)
    style_font_string(lblInfo)
    local ebInfo = StdUi:SimpleEditBox(modal, 230, 20, "")
    ebInfo:SetPoint("LEFT", lblInfo, "RIGHT", 10, 0)
    apply_editbox_theme(ebInfo)

    local lblCmd = StdUi:FontString(modal, L_get("modal_label_rand"))
    lblCmd:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -89)
    style_font_string(lblCmd)
    local ebCmd = StdUi:SimpleEditBox(modal, 230, 20, "")
    ebCmd:SetPoint("LEFT", lblCmd, "RIGHT", 7, 0)
    apply_editbox_theme(ebCmd)

    local lblRole = StdUi:FontString(modal, L_get("modal_label_rand_role"))
    lblRole:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -116)
    style_font_string(lblRole)

    local btnRoleOff = StdUi:Button(modal, 92, 20, L_get("rand_role_offensive"))
    btnRoleOff:SetPoint("LEFT", lblRole, "RIGHT", 8, 0)
    local btnRoleSupport = StdUi:Button(modal, 92, 20, L_get("rand_role_support"))
    btnRoleSupport:SetPoint("LEFT", btnRoleOff, "RIGHT", 4, 0)
    local btnRoleDef = StdUi:Button(modal, 92, 20, L_get("rand_role_defensive"))
    btnRoleDef:SetPoint("LEFT", btnRoleSupport, "RIGHT", 4, 0)

    local lblIcon = StdUi:FontString(modal, L_get("modal_label_icon"))
    lblIcon:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -143)
    style_font_string(lblIcon)
    local iconPreview = modal:CreateTexture(nil, "ARTWORK")
    iconPreview:SetSize(18, 18)
    iconPreview:SetPoint("LEFT", lblIcon, "RIGHT", 8, 0)
    local btnPickIcon = StdUi:Button(modal, 90, 20, L_get("modal_choose"))
    btnPickIcon:SetPoint("LEFT", iconPreview, "RIGHT", 8, 0)
    local btnClearIcon = StdUi:Button(modal, 70, 20, L_get("modal_icon_none"))
    btnClearIcon:SetPoint("LEFT", btnPickIcon, "RIGHT", 6, 0)

    local lblOutcomeValue = StdUi:FontString(modal, L_get("modal_label_result"))
    lblOutcomeValue:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -173)
    style_font_string(lblOutcomeValue)
    local ebOutcomeValue = StdUi:SimpleEditBox(modal, 45, 20, "")
    ebOutcomeValue:SetPoint("LEFT", lblOutcomeValue, "RIGHT", 8, 0)
    apply_editbox_theme(ebOutcomeValue)

    local lblOutcomeText = StdUi:FontString(modal, L_get("modal_label_action"))
    lblOutcomeText:SetPoint("LEFT", ebOutcomeValue, "RIGHT", 12, 0)
    style_font_string(lblOutcomeText)
    local ebOutcomeText = StdUi:SimpleEditBox(modal, 130, 20, "")
    ebOutcomeText:SetPoint("LEFT", lblOutcomeText, "RIGHT", 8, 0)
    apply_editbox_theme(ebOutcomeText)

    local btnAddOutcome = StdUi:Button(modal, 110, 20, L_get("modal_add_outcome"))
    btnAddOutcome:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -201)
    local btnRemoveOutcome = StdUi:Button(modal, 110, 20, L_get("modal_remove_outcome"))
    btnRemoveOutcome:SetPoint("LEFT", btnAddOutcome, "RIGHT", 8, 0)

    local outcomesScroll = StdUi:ScrollFrame(modal, 332, 90)
    outcomesScroll:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -227)
    apply_scrollbar_theme(outcomesScroll)
    local outcomesContent = outcomesScroll.scrollChild
    local outcomesLabel = StdUi:FontString(outcomesContent, L_get("modal_issues_none"))
    outcomesLabel:SetPoint("TOPLEFT", outcomesContent, "TOPLEFT", 0, 0)
    outcomesLabel:SetWidth(312)
    outcomesLabel:SetJustifyH("LEFT")
    outcomesLabel:SetJustifyV("TOP")

    local btnOk = StdUi:Button(modal, 110, 22, L_get("common_save"))
    btnOk:SetPoint("BOTTOMLEFT", modal, "BOTTOMLEFT", 70, 14)
    local btnCancel = StdUi:Button(modal, 110, 22, L_get("common_cancel"))
    btnCancel:SetPoint("LEFT", btnOk, "RIGHT", 8, 0)
    apply_button_theme(btnPickIcon)
    apply_button_theme(btnClearIcon)
    apply_button_theme(btnRoleOff)
    apply_button_theme(btnRoleSupport)
    apply_button_theme(btnRoleDef)
    apply_button_theme(btnAddOutcome)
    apply_button_theme(btnRemoveOutcome)
    apply_button_theme(btnOk, true)
    apply_button_theme(btnCancel)

    local roleButtons = {
      offensive = btnRoleOff,
      support = btnRoleSupport,
      defensive = btnRoleDef,
    }
    local function set_selected_role(roleKey)
      modal.selectedRandRole = normalize_rand_role(roleKey, modal.ebName and modal.ebName:GetText() or "")
      for _, option in ipairs(RAND_ROLE_OPTIONS) do
        local btn = roleButtons[option.key]
        if btn then
          apply_button_theme(btn, option.key == modal.selectedRandRole)
          if option.key == modal.selectedRandRole then
            if btn.SetBackdropColor then
              btn:SetBackdropColor(0.18, 0.45, 0.18, 0.95)
            end
            if btn.SetBackdropBorderColor then
              btn:SetBackdropBorderColor(0.30, 0.85, 0.30, 0.9)
            end
          end
        end
      end
    end

    btnRoleOff:SetScript("OnClick", function() set_selected_role("offensive") end)
    btnRoleSupport:SetScript("OnClick", function() set_selected_role("support") end)
    btnRoleDef:SetScript("OnClick", function() set_selected_role("defensive") end)

    local update_outcomes_label = build_outcomes_label_updater(modal, outcomesLabel, outcomesContent)

    btnAddOutcome:SetScript("OnClick", function()
      add_outcome_to_modal(modal, ebOutcomeValue, ebOutcomeText, update_outcomes_label)
    end)

    btnRemoveOutcome:SetScript("OnClick", function()
      remove_outcome_from_modal(modal, ebOutcomeValue, ebOutcomeText, update_outcomes_label)
    end)

    btnPickIcon:SetScript("OnClick", function()
      open_icon_picker(modal.selectedIcon, function(icon)
        modal.selectedIcon = icon
        set_icon_preview(iconPreview, icon)
      end)
    end)

    btnClearIcon:SetScript("OnClick", function()
      modal.selectedIcon = nil
      set_icon_preview(iconPreview, nil)
    end)

    btnOk:SetScript("OnClick", function()
      local target = modal.targetRand
      if not target then
        modal:Hide()
        return
      end

      local name = trim_text(ebName:GetText())
      local info = trim_text(ebInfo:GetText())
      local cmd = trim_text(ebCmd:GetText())

      if name == "" then
        L_print("rand_name_required")
        return
      end

      local normalizedCmd = normalize_command_text(cmd)
      if not normalizedCmd then
        L_print("rand_format_invalid")
        return
      end
      cmd = normalizedCmd

      local previousCommand = trim_text(target.command)
      if info == "" or target.is_default or info == previousCommand then
        info = cmd
      end

      target.name = name
      target.info = info
      target.command = cmd
      target.rand_role = normalize_rand_role(modal.selectedRandRole, name)
      target.icon = modal.selectedIcon
      target.outcomes = copy_outcomes(modal.outcomes)
      target.outcome_ranges = copy_outcome_ranges(modal.outcomeRanges)

      modal:Hide()
      UI.REFRESH()
    end)

    btnCancel:SetScript("OnClick", function()
      modal:Hide()
    end)

    modal.ebName = ebName
    modal.ebInfo = ebInfo
    modal.ebCmd = ebCmd
    modal.iconPreview = iconPreview
    modal.selectedIcon = nil
    modal.ebOutcomeValue = ebOutcomeValue
    modal.ebOutcomeText = ebOutcomeText
    modal.updateOutcomesLabel = update_outcomes_label
    modal.setSelectedRole = set_selected_role
    UI.EDIT_RAND_MODAL = modal
  end

  local modal = UI.EDIT_RAND_MODAL
  modal.targetRand = randData
  modal.ebName:SetText(tostring(randData.name or ""))
  modal.ebInfo:SetText(tostring(randData.info or ""))
  modal.ebCmd:SetText(tostring(randData.command or ""))
  modal.selectedIcon = randData.icon
  set_icon_preview(modal.iconPreview, randData.icon)
  modal.outcomes = copy_outcomes(randData.outcomes)
  modal.outcomeRanges = copy_outcome_ranges(randData.outcome_ranges)
  modal.ebOutcomeValue:SetText("")
  modal.ebOutcomeText:SetText("")
  modal.updateOutcomesLabel()
  modal.setSelectedRole(normalize_rand_role(randData.rand_role, randData.name))
  modal:Show()
  modal.ebName:SetFocus()
end

UI.open_new_section_form = function(onAccept)
  local StdUi = get_stdui()
  if not StdUi then
    return
  end

  if not UI.NEW_SECTION_MODAL then
    local modal = StdUi:Panel(UIParent, 320, 110)
    modal:SetFrameStrata("DIALOG")
    modal:SetFrameLevel(200)
    modal:EnableMouse(true)
    apply_panel_theme(modal)
    modal:Hide()
    make_modal_draggable(modal, "new_section")
    apply_modal_position(modal, "new_section")

    local title = StdUi:FontString(modal, L_get("modal_new_section_title"))
    title:SetPoint("TOP", modal, "TOP", 0, -10)
    style_font_string(title, true)

    local lblName = StdUi:FontString(modal, L_get("modal_label_name"))
    lblName:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -40)
    style_font_string(lblName)
    local ebName = StdUi:SimpleEditBox(modal, 220, 20, "")
    ebName:SetPoint("LEFT", lblName, "RIGHT", 8, 0)
    apply_editbox_theme(ebName)

    local btnOk = StdUi:Button(modal, 110, 22, L_get("modal_create"))
    btnOk:SetPoint("BOTTOMLEFT", modal, "BOTTOMLEFT", 48, 10)
    local btnCancel = StdUi:Button(modal, 110, 22, L_get("common_cancel"))
    btnCancel:SetPoint("LEFT", btnOk, "RIGHT", 8, 0)
    apply_button_theme(btnOk, true)
    apply_button_theme(btnCancel)

    btnOk:SetScript("OnClick", function()
      local name = tostring(ebName:GetText() or "")
      if name == "" then
        L_print("section_name_required")
        return
      end

      local callback = modal.onAccept
      modal:Hide()
      if callback then
        callback({ type = "section", name = name, expanded = true, items = {} })
      end
    end)

    btnCancel:SetScript("OnClick", function()
      modal:Hide()
    end)

    modal.ebName = ebName
    UI.NEW_SECTION_MODAL = modal
  end

  local modal = UI.NEW_SECTION_MODAL
  modal.onAccept = onAccept
  modal.ebName:SetText("")
  modal:Show()
  modal.ebName:SetFocus()
end

UI.open_edit_section_form = function(sectionData)
  local StdUi = get_stdui()
  if not StdUi or not sectionData then
    return
  end

  if not UI.EDIT_SECTION_MODAL then
    local modal = StdUi:Panel(UIParent, 320, 110)
    modal:SetFrameStrata("DIALOG")
    modal:SetFrameLevel(200)
    modal:EnableMouse(true)
    apply_panel_theme(modal)
    modal:Hide()
    make_modal_draggable(modal, "edit_section")
    apply_modal_position(modal, "edit_section")

    local title = StdUi:FontString(modal, L_get("modal_edit_section_title"))
    title:SetPoint("TOP", modal, "TOP", 0, -10)
    style_font_string(title, true)

    local lblName = StdUi:FontString(modal, L_get("modal_label_name"))
    lblName:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -40)
    style_font_string(lblName)
    local ebName = StdUi:SimpleEditBox(modal, 220, 20, "")
    ebName:SetPoint("LEFT", lblName, "RIGHT", 8, 0)
    apply_editbox_theme(ebName)

    local btnOk = StdUi:Button(modal, 110, 22, L_get("common_save"))
    btnOk:SetPoint("BOTTOMLEFT", modal, "BOTTOMLEFT", 48, 10)
    local btnCancel = StdUi:Button(modal, 110, 22, L_get("common_cancel"))
    btnCancel:SetPoint("LEFT", btnOk, "RIGHT", 8, 0)
    apply_button_theme(btnOk, true)
    apply_button_theme(btnCancel)

    btnOk:SetScript("OnClick", function()
      local target = modal.targetSection
      if not target then
        modal:Hide()
        return
      end

      local name = tostring(ebName:GetText() or "")
      if name == "" then
        L_print("section_name_required")
        return
      end

      target.name = name
      modal:Hide()
      UI.REFRESH()
    end)

    btnCancel:SetScript("OnClick", function()
      modal:Hide()
    end)

    modal.ebName = ebName
    UI.EDIT_SECTION_MODAL = modal
  end

  local modal = UI.EDIT_SECTION_MODAL
  modal.targetSection = sectionData
  modal.ebName:SetText(tostring(sectionData.name or ""))
  modal:Show()
  modal.ebName:SetFocus()
end
