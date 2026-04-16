-- Author : Prosper

local StateLib = _G.EasySanaluneStateLib
local Core = _G.EasySanaluneCore or {}
local UI = _G.EasySanaluneUI
local Locale = _G.EasySanaluneLocale
local Protocol = Core and Core.Protocol or nil
local UI_BUILT = false
---@type EasySanaluneState
local STATE = (StateLib and StateLib.DEF_STATE) or {}

local function L_print(key, ...)
	if Locale and Locale.print then
		Locale.print(key, ...)
		return
	end
	if Locale and Locale.get then
		if Locale.format_addon_print then
			print(Locale.format_addon_print(key, Locale.get(key, ...)))
		else
			print(Locale.get(key, ...))
		end
		return
	end
	print(tostring(key))
end

local function L_print_text(text)
	if Locale and Locale.print_text then
		Locale.print_text(text)
		return
	end
	if Locale and Locale.format_addon_print then
		print(Locale.format_addon_print("resolution_print_text", tostring(text or "")))
		return
	end
	print(tostring(text or ""))
end

local StdUi = LibStub('StdUi')
local font, fontSize = GameFontNormal:GetFont()
local _, largeFontSize = GameFontNormalLarge:GetFont()
StdUi.config = {
	font        = {
		family    = font,
		size      = fontSize,
		titleSize = largeFontSize,
		effect    = 'NONE',
		strata    = 'OVERLAY',
		color     = {
			normal   = { r = 1, g = 1, b = 1, a = 1 },
			disabled = { r = 0.55, g = 0.55, b = 0.55, a = 1 },
			header   = { r = 1, g = 0.9, b = 0, a = 1 },
		}
	},

	backdrop    = {
		texture        = [[Interface\Buttons\WHITE8X8]],
		panel          = { r = 0.0588, g = 0.0588, b = 0, a = 0.7 },
		slider         = { r = 0.15, g = 0.15, b = 0.15, a = 1 },

		highlight      = { r = 0.40, g = 0.40, b = 0, a = 0.5 },
		button         = { r = 0.20, g = 0.20, b = 0.20, a = 1 },
		buttonDisabled = { r = 0.15, g = 0.15, b = 0.15, a = 1 },

		border         = { r = 0.00, g = 0.00, b = 0.00, a = 1 },
		borderDisabled = { r = 0.40, g = 0.40, b = 0.40, a = 1 }
	},

	progressBar = {
		color = { r = 1, g = 0.9, b = 0, a = 0.5 },
	},

	highlight   = {
		color = { r = 1, g = 0.9, b = 0, a = 0.4 },
		blank = { r = 0, g = 0, b = 0, a = 0 }
	},

	dialog      = {
		width  = 400,
		height = 100,
		button = {
			width  = 100,
			height = 20,
			margin = 5
		}
	},

	tooltip     = {
		padding = 10
	}
}
_G.StdUi = StdUi

local addon_id = "EasySanalune"
local addon_channel = (Protocol and Protocol.CHANNEL) or "easysanalune2"
local legacy_addon_channel = (Protocol and Protocol.LEGACY_CHANNEL) or "easysanalune"

local function get_saved_state()
	return _G.EASY_SANALUNE_SAVED_STATE
end

local function set_saved_state(state)
	_G.EASY_SANALUNE_SAVED_STATE = state
end

-- Init on load
local load_frame = CreateFrame("Frame")
load_frame:RegisterEvent("ADDON_LOADED")
load_frame:RegisterEvent("CHAT_MSG_ADDON")
load_frame:RegisterEvent("PLAYER_ENTERING_WORLD")
load_frame:RegisterEvent("GROUP_ROSTER_UPDATE")
load_frame:SetScript("OnEvent", function(_, event, addonPrefix, message, ...)
	if event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" then
		if UI and UI.SendMJAnnounce then
			UI.SendMJAnnounce(STATE and STATE.mj_enabled and true or false)
		end
		if UI and UI.MaybeAutoRefreshMJMobSync and STATE and STATE.mj_enabled then
			UI.MaybeAutoRefreshMJMobSync(event == "PLAYER_ENTERING_WORLD" and 1 or 0.5)
		end
		return
	end

	if event == "CHAT_MSG_ADDON" then
		if addonPrefix == addon_channel or addonPrefix == legacy_addon_channel then
			local channelType, senderName = ...
			if UI and UI.OnAddonMessage then
				UI.OnAddonMessage(addonPrefix, message, channelType, senderName)
			end
		end
		return
	end

	if event ~= "ADDON_LOADED" or addonPrefix ~= addon_id then
		return
	end

	C_ChatInfo.RegisterAddonMessagePrefix(addon_channel)
	if legacy_addon_channel ~= addon_channel then
		C_ChatInfo.RegisterAddonMessagePrefix(legacy_addon_channel)
	end
	L_print("addon_loaded")

	if type(Core.prepare_state) ~= "function" then
		print("EasySanalune: Core.prepare_state manquant. Verifie l'ordre de chargement TOC.")
		return
	end
	if not StateLib or not StateLib.DEF_STATE then
		print("EasySanalune: StateLib.DEF_STATE manquant. Impossible d'initialiser l'etat.")
		return
	end
	if not UI or type(UI.init_ui) ~= "function" or type(UI.build_ui) ~= "function" then
		print("EasySanalune: module UI incomplet. Verifie le chargement des fichiers ui/*.lua.")
		return
	end

	local saved_state = get_saved_state()
	if saved_state == nil or saved_state.pos_x == nil then
		L_print("addon_reset_detected")
	end
	STATE = Core.prepare_state(saved_state, StateLib.DEF_STATE)

	if not UI_BUILT then
		UI.init_ui(STATE)
		UI.init_minimap(STATE)
		UI.build_ui()
		if UI.MaybeShowInfosGuideOnce then
			UI.MaybeShowInfosGuideOnce()
		end
		UI.MAIN_FRAME:Hide()
		STATE.shown = false
		set_saved_state(STATE)
		UI_BUILT = true
		if UI.set_profile_mode then
			UI.set_profile_mode(STATE.profile_mode)
		end
	end

end)

SLASH_EASYSANALUNE1 = "/sanalune"
SLASH_EASYSANALUNE2 = "/easysanalune"
SLASH_EASYSANALUNE3 = "/easy"
SlashCmdList["EASYSANALUNE"] = function(msg)
	if not STATE then
		L_print("addon_not_loaded")
		return
	end

	local cmd = string.lower(tostring(msg or ""))
	if cmd == "profils" then
		STATE.profile_mode = not STATE.profile_mode
		set_saved_state(STATE)
		if UI and UI.set_profile_mode then
			UI.set_profile_mode(STATE.profile_mode)
		end
		L_print(STATE.profile_mode and "profile_mode_enabled" or "profile_mode_disabled")
	elseif cmd == "pj" then
		if UI and UI.MAIN_FRAME then
			if UI.MAIN_FRAME:IsShown() then
				UI.MAIN_FRAME:Hide()
			else
				UI.MAIN_FRAME:Show()
				if UI.EXPAND then
					UI.EXPAND()
				end
			end
		end
	elseif cmd == "mj" then
		if UI and UI.ToggleMJFrame then
			UI.ToggleMJFrame()
		elseif UI and UI.OpenMJFrame then
			UI.OpenMJFrame()
		end
	else
		L_print("profiles_help")
	end
end
