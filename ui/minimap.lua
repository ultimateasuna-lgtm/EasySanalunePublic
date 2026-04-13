local UI = _G.EasySanaluneUI

---@type EasySanaluneState
local STATE = (_G.EasySanaluneStateLib and _G.EasySanaluneStateLib.DEF_STATE) or {}

---@param state EasySanaluneState
UI.init_minimap = function(state)
  STATE = state
  UI.MinimapButton_Reposition()
end

local EasySanaluneMinimap = {}
_G.EasySanaluneMinimap = EasySanaluneMinimap

function EasySanaluneMinimap.MinimapButton_Reposition()
  local minimapButton = rawget(_G, "EasySanaluneMinimapButton")
  if not STATE or not minimapButton then
    return
  end
  minimapButton:SetPoint("TOPLEFT", "Minimap", "TOPLEFT", 52 - (80 * cos(STATE.minimap_button_pos)),
    (80 * sin(STATE.minimap_button_pos)) - 52)
end

UI.MinimapButton_Reposition = EasySanaluneMinimap.MinimapButton_Reposition

function EasySanaluneMinimap.MinimapButton_DraggingFrame_OnUpdate()
  if not STATE then
    return
  end
  local xpos, ypos = GetCursorPosition()
  local xmin, ymin = Minimap:GetLeft(), Minimap:GetBottom()

  xpos = xmin - xpos / UIParent:GetScale() + 70
  ypos = ypos / UIParent:GetScale() - ymin - 70

  STATE.minimap_button_pos = math.deg(math.atan2(ypos, xpos))
  EasySanaluneMinimap.MinimapButton_Reposition()
end

function EasySanaluneMinimap.MinimapButton_OnEnter(self)
  if (self.dragging) then
    return
  end
  GameTooltip:SetOwner(self or UIParent, "ANCHOR_LEFT")
  EasySanaluneMinimap.MinimapButton_Details(GameTooltip)
end

function EasySanaluneMinimap.MinimapButton_Details(tt, ldb)
  tt:ClearLines()
  tt:SetText("EasySanalune")
  tt:AddLine("Clic gauche: Afficher/Cacher l'interface\nClic droit: Recentrer l'interface + reset fenêtres draggable", 1, 1, 1)
  tt:Show()
end

function EasySanaluneMinimap.MinimapButton_OnClick()
  if not STATE then
    return
  end
  local buttonMod = GetMouseButtonClicked()
  if buttonMod == "LeftButton" then
    local MF = UI.MAIN_FRAME
    if not MF then
      return
    end
    if MF:IsShown() then
      MF:Hide()
    else
      MF:Show()
      if STATE.shown then
        UI.EXPAND()
      else
        UI.HIDE()
      end
    end
  elseif buttonMod == "RightButton" then
    STATE.pos_x = 500
    STATE.pos_y = 500
    STATE.dim_show_w = 325
    STATE.dim_show_h = 400
    if UI and UI.reset_modal_positions then
      UI.reset_modal_positions()
    end
    _G.EASY_SANALUNE_SAVED_STATE = STATE

    local MF = UI and UI.MAIN_FRAME
    if MF then
      if STATE.shown then
        MF:SetWidth(STATE.dim_show_w)
        MF:SetHeight(STATE.dim_show_h)
      else
        MF:SetWidth(STATE.dim_hide_w)
        MF:SetHeight(STATE.dim_hide_h)
      end

      MF:ClearAllPoints()
      MF:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", STATE.pos_x, STATE.pos_y)

      if MF.texture then
        MF.texture:SetSize(MF:GetWidth(), MF:GetHeight())
      end
    end
  end
end
