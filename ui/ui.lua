local UI = {}
_G.EasySanaluneUI = UI

---@type EasySanaluneStateLib|nil
local StateLib = rawget(_G, "EasySanaluneStateLib")
local Core = rawget(_G, "EasySanaluneCore") or {}
---@cast Core EasySanaluneCore
local Locale = _G.EasySanaluneLocale
---@type EasySanaluneMJLogic|nil
local MJLogic = Core and Core.MJ or nil
---@type EasySanaluneResolutionLogic|nil
local ResolutionLogic = Core and Core.Resolution or nil
local Protocol = Core and Core.Protocol or nil
---@type EasySanaluneCombatSessionLogic|nil
local CombatSessionLogic = Core and Core.CombatSession or nil

---@class EasySanaluneOutcomeModal
---@field outcomes table<integer, string>
---@field outcomeRanges EasySanaluneOutcomeRange[]

---@type EasySanaluneState
local STATE = (StateLib and StateLib.DEF_STATE) or {}
---@type any
local StdUi = nil
local randPattern = nil
local randListenerFrame = nil
local INTERNALS = {}
UI._internals = INTERNALS
local DEFAULT_CRIT_THRESHOLD = 70
local DEFAULT_DODGE_BACK_PERCENT = 50
local DEFAULT_HIT_POINTS = 5
local DEFAULT_ARMOR_TYPE = "nue"
local DEFAULT_DURABILITY_MAX = 5
local MIN_HIT_POINTS = -2
local ARMOR_TYPE_OPTIONS = {
  { value = "nue", labelKey = "ui_armor_type_nue" },
  { value = "legere", labelKey = "ui_armor_type_light" },
  { value = "intermediaire", labelKey = "ui_armor_type_medium" },
  { value = "lourde", labelKey = "ui_armor_type_heavy" },
  { value = "special", labelKey = "ui_armor_type_special" },
}
local EXTRA_MAINFRAME_HEIGHT = 0

local function normalize_armor_type(value)
  if Core and type(Core.normalize_armor_type) == "function" then
    return Core.normalize_armor_type(value)
  end

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

  return DEFAULT_ARMOR_TYPE
end

local function get_armor_type_label(value)
  local normalizedType = normalize_armor_type(value)
  for i = 1, #ARMOR_TYPE_OPTIONS do
    local option = ARMOR_TYPE_OPTIONS[i]
    if option.value == normalizedType then
      if option.label and option.label ~= "" then
        return tostring(option.label)
      end
      if option.labelKey and Locale and Locale.get then
        return Locale.get(option.labelKey)
      end
      return tostring(option.value)
    end
  end
  return tostring(normalizedType)
end

-- -----------------------------------------------------------------------------
-- Fonctions de secours (utilisees si les helpers du Core sont absents)
-- -----------------------------------------------------------------------------
local function fallback_copy_outcomes(value)
  local out = {}
  if type(value) ~= "table" then
    return out
  end
  for k, v in pairs(value) do
    out[k] = v
  end
  return out
end

local function fallback_copy_outcome_ranges(value)
  local out = {}
  if type(value) ~= "table" then
    return out
  end
  for i = 1, #value do
    local e = value[i]
    if type(e) == "table" then
      out[#out + 1] = {
        min = tonumber(e.min),
        max = tonumber(e.max),
        text = tostring(e.text or ""),
      }
    end
  end
  return out
end

local function fallback_parse_outcome_selector(input)
  local raw = tostring(input or "")
  raw = string.gsub(raw, "^%s+", "")
  raw = string.gsub(raw, "%s+$", "")
  if raw == "" then
    return nil, nil, nil
  end
  local single = tonumber(raw)
  if single and single >= 0 and math.floor(single) == single then
    return single, single, "single"
  end
  local minVal, maxVal = string.match(raw, "^(%d+)%s*%-%s*(%d+)$")
  minVal = tonumber(minVal)
  maxVal = tonumber(maxVal)
  if minVal and maxVal then
    if minVal > maxVal then
      minVal, maxVal = maxVal, minVal
    end
    return minVal, maxVal, "range"
  end
  return nil, nil, nil
end

local function fallback_parse_command(input)
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

local function fallback_normalize_chars(_)
  return
end

local function fallback_deep_clone_chars(list)
  local copy = {}
  if type(list) ~= "table" then
    return copy
  end
  for i = 1, #list do
    local e = list[i]
    if type(e) == "table" then
      local item = {}
      for k, v in pairs(e) do
        item[k] = v
      end
      copy[i] = item
    else
      copy[i] = e
    end
  end
  return copy
end

local copy_outcomes = type(Core.copy_outcomes) == "function" and Core.copy_outcomes or fallback_copy_outcomes
local copy_outcome_ranges = type(Core.copy_outcome_ranges) == "function" and Core.copy_outcome_ranges or fallback_copy_outcome_ranges
local parse_outcome_selector = type(Core.parse_outcome_selector) == "function" and Core.parse_outcome_selector or fallback_parse_outcome_selector
local parse_command = type(Core.parse_command) == "function" and Core.parse_command or fallback_parse_command
local normalize_chars = type(Core.normalize_chars) == "function" and Core.normalize_chars or fallback_normalize_chars
local deep_clone_chars = type(Core.deep_clone_chars) == "function" and Core.deep_clone_chars or fallback_deep_clone_chars
local normalize_survival_data = type(Core.normalize_survival_data) == "function" and Core.normalize_survival_data or function(data) return data end
local get_survival_snapshot = type(Core.get_survival_snapshot) == "function" and Core.get_survival_snapshot or function(data) return data or {} end
local format_durability_text = type(Core.format_durability_text) == "function" and Core.format_durability_text or function(data)
  local snapshot = data or {}
  if snapshot.durability_infinite then
    return "infini"
  end
  return string.format("%s / %s", tostring(snapshot.durability_current or 5), tostring(snapshot.durability_max or 5))
end
local parse_durability_input = type(Core.parse_durability_input) == "function" and Core.parse_durability_input or function(value, fallbackCurrent, fallbackMax, fallbackInfinite)
  local raw = tostring(value or "")
  raw = string.gsub(raw, "^%s+", "")
  raw = string.gsub(raw, "%s+$", "")
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

-- -----------------------------------------------------------------------------
-- Aide pour les textes localises et l'affichage en chat
-- -----------------------------------------------------------------------------
local function L_get(key, ...)
  if Locale and Locale.get then
    return Locale.get(key, ...)
  end
  return tostring(key)
end

local function L_print(key, ...)
  if Locale and Locale.print then
    Locale.print(key, ...)
    return
  end
  if Locale and Locale.format_addon_print then
    print(Locale.format_addon_print(key, L_get(key, ...)))
    return
  end
  print(L_get(key, ...))
end

local function print_resolution_for_local_context(text)
  local isMjContext = STATE and STATE.mj_enabled and true or false
  if Locale and Locale.print_with_context then
    Locale.print_with_context("resolution_print_text", isMjContext, text)
    return
  end
  local resultPrintKey = isMjContext and "mj_resolution_text" or "resolution_print_text"
  L_print(resultPrintKey, text)
end

local function escape_chat_message(text)
  local value = tostring(text or "")
  return string.gsub(value, "|", "||")
end

local function warn_missing_core()
  if not _G.EasySanaluneCore then
    print("EasySanalune: module core manquant, mode degrade actif.")
    return
  end
  if type(_G.EasySanaluneCore.prepare_state) ~= "function" then
    print("EasySanalune: Core.prepare_state absent, verifie l'ordre du TOC.")
  end
end

warn_missing_core()

local function clamp_percent(value, defaultValue)
  local numeric = tonumber(value)
  if numeric == nil then
    return defaultValue
  end
  numeric = math.floor(numeric)
  if numeric < 0 then
    return 0
  end
  if numeric > 100 then
    return 100
  end
  return numeric
end

-- -----------------------------------------------------------------------------
-- Branchement des utilitaires internes
-- -----------------------------------------------------------------------------
INTERNALS.l_get = L_get
INTERNALS.l_print = L_print

INTERNALS.copy_outcomes = copy_outcomes
INTERNALS.copy_outcome_ranges = copy_outcome_ranges
INTERNALS.parse_command = parse_command
---@return EasySanaluneState
INTERNALS.get_state = function()
  return STATE
end
INTERNALS.getState = INTERNALS.get_state
INTERNALS.get_std_ui = function()
  return StdUi
end
INTERNALS.getStdUi = INTERNALS.get_std_ui

local THEME = {
  panelBg = { r = 0.03, g = 0.06, b = 0.12, a = 0.93 },
  panelBgSoft = { r = 0.05, g = 0.09, b = 0.16, a = 0.92 },
  panelBorder = { r = 0.86, g = 0.80, b = 0.62, a = 1 },
  accent = { r = 0.81, g = 0.87, b = 1.00, a = 1 },
  text = { r = 0.95, g = 0.95, b = 0.95, a = 1 },
}

-- Le contenu du guide est defini ici pour etre simple a maintenir.
local INFOS_GUIDE_LINES = {
  "Bienvenue dans EasySanalune.",
  "",
  "Ce guide explique toutes les fonctions essentielles, cote joueur et cote MJ, avec les actions clic/survol.",
  "Lis les sections dans l'ordre si tu decouvres l'addon.",
  "",
  "==============================",
  "1) Mainframe (fenetre principale) (/easy pj)",
  "==============================",
  "- Le mainframe centralise ta fiche, tes rands et tes categories.",
  "- Tu peux le deplacer en cliquant-glissant la zone de titre.",
  "- Le redimensionnement se fait avec la poignee de resize.",
  "- Le bouton ^ jaune réduit la fenetre principale.",
  "",
  "Boutons du header:",
  "- Reset: remet le profil courant a zero (fiche + buffs + seuils), avec confirmation.",
  "  Le bouton n'apparait que si quelque chose est vraiment modifie.",
  "- Infos: ouvre ce guide complet.",
  "- Buffs: ouvre la fenetre Buffs/Debuffs.",
  "- Fenetre MJ: ouvre la fenetre MJ (visible si mode MJ active).",
  "- Fiche: ouvre la fenetre de parametrage de la fiche (crits, PDV, armure).",
  "",
  "Cases a cocher du header:",
  "- Message raid: envoie les resultats vers le canal raid selon la logique addon.",
  "- Lire resultat rand: active la lecture/interpretation automatique de tes rands.",
  "- MJ: active les fonctions MJ (bouton Fenetre MJ, comportement associe).",
  "- Resolution privee: force les resolutions en mode prive si necessaire.",
  "",
  "==============================",
  "2) Profils (/easy profils)",
  "==============================",
  "- Le bloc Profil permet d'avoir plusieurs configurations (perso, roleplay, scenes, etc.).",
  "- Dropdown Profil: clic pour choisir un profil existant.",
  "- Bouton + a droite du profil: ouvre les actions de profil (nouveau, renommer, exporter).",
  "",
  "Conseils profils:",
  "- Fais un profil par style de jeu (combat, social, event).",
  "- Renomme clairement les profils pour les retrouver vite.",
  "- Exporte ton profil pour sauvegarde/partage.",
  "",
  "==============================",
  "3) Liste des categories et rands (zone centrale)",
  "==============================",
  "- Les categories regroupent les rands.",
  "- Clic gauche sur une categorie: reduire/etendre.",
  "- Clic droit sur une categorie/rand: modifier la categorie/rand.",
  "",
  "Actions visibles au survol d'une ligne (categorie ou rand):",
  "- Edit: ouvre la fenetre d'edition.",
  "- x: supprime l'element.",
  "- ^: remonte l'element.",
  "- v: descend l'element.",
  "",
  "Important:",
  "- Le survol sert a garder une interface propre: les boutons apparaissent quand utiles.",
  "- Sur un rand, le texte d'info et la valeur sont recalcules selon ton contexte (buffs/debuffs).",
  "",
  "==============================",
  "4) Fenetre Buffs / Debuffs",
  "==============================",
  "- Ouvre-la via le bouton Buffs du header.",
  "- Elle est draggable, redimensionnable, et sauvegarde sa taille/position.",
  "",
  "Dans cette fenetre:",
  "- Nouveau buff: creer une entree buff/debuff.",
  "- Nouvelle categorie: creer un groupe de buffs.",
  "- Reset: vide les buffs du profil courant (visible seulement s'il y a des donnees).",
  "",
  "Interactions utiles:",
  "- Clic gauche sur categorie: reduire/etendre.",
  "- Clic droit sur categorie/buff: modifier la categorie/buff.",
  "- Survol ligne: actions Edit/x/^/v apparaissent.",
  "- Un buff peut impacter une ou plusieurs stats selon sa configuration.",
  "",
  "==============================",
  "5) Fiche (crits, PDV, armure)",
  "==============================",
  "- Le bouton Fiche ouvre le reglage de la fiche personnage.",
  "- Ces seuils influencent les resolutions et lectures de rands.",
  "- Valeurs par defaut: 1-100 standard, puis personnalisation possible.",
  "- WIP, cette partie est amenee a evoluer pour plus de flexibilite et de types de seuils.",
  "",
  "==============================",
  "6) Fenetre MJ (/easy mj)",
  "==============================",
  "- Accessible via Fenetre MJ si la case MJ est activee.",
  "- Cette fenetre est draggable/fermable, comme les autres.",
  "",
  "Bloc mobs:",
  "- Liste des mobs: clic gauche pour selectionner le mob actif, clic droit pour edition.",
  "- Nouveau: cree un nouveau mob avec les champs courants.",
  "- Sauvegarder: enregistre les modifications du mob en edition.",
  "- Supprimer: retire le mob en edition.",
  "- Importer un profil: colle un export joueur pour creer un mob rapidement.",
  "",
  "Bloc attaque du mob vers joueur:",
  "- Dropdown cible joueur: selectionne le joueur cible.",
  "- Champ nom + Ajouter: ajoute une cible a la liste.",
  "- Retirer: retire la cible selectionnee.",
  "- Atk phys / Atk mag: lance l'attaque selon le type.",
  "- Quand le MJ lance une attaque vers un joueur, le joueur recoit une alerte contextuelle a l'ecran.",
  "- Cette alerte explique l'attaque recue et propose les boutons de reaction adaptes (defense/esquive selon le contexte).",
  "- Le joueur peut donc repondre rapidement sans devoir chercher manuellement la bonne action.",
  "",
  "Resets MJ (affichage intelligent):",
  "- Reset mobs: visible seulement s'il y a des mobs/donnees MJ a vider.",
  "- Reset joueurs: visible seulement s'il y a des cibles joueurs enregistrees.",
  "- Chaque reset demande une confirmation avant execution.",
  "",
  "==============================",
  "7) Demandes en attente (MJ)",
  "==============================",
  "- Cette section affiche les demandes a traiter.",
  "- Le menu de choix du mob dans une demande suit la meme logique visuelle que les autres listes.",
  "- Verifie le mob selectionne avant de valider une reponse.",
  "",
  "==============================",
  "8) Conseils de prise en main rapide",
  "==============================",
  "1. Cree un profil propre a ton personnage.",
  "2. Configure tes seuils dans Fiche.",
  "3. Ajoute tes rands principaux par categories.",
  "4. Ajoute tes buffs/debuffs courants.",
  "5. Si tu es MJ, cree/importe les mobs puis prepare tes cibles joueurs.",
  "6. Teste une attaque MJ de bout en bout pour valider ton flux (alerte joueur, defense, resultat).",
  "",
  "==============================",
  "9) Depannage simple",
  "==============================",
  "- Un bouton n'apparait pas: souvent normal (affichage conditionnel selon donnees).",
  "- Une action semble inactive: verifie d'abord le profil courant et la selection active.",
  "- En MJ, si Atk ne part pas: verifie le mob actif, la cible joueur et les valeurs de rands.",
  "- Si l'alerte contextuelle joueur n'apparait pas: verifie que le bon joueur est cible et que la resolution privee/canal correspond a ton contexte.",
  "- En cas de doute, utilise ce guide puis teste etape par etape.",
  "",
  "==============================",
  "10) Fenetres et interactions globales",
  "==============================",
  "- Toutes les fenetres principales (mainframe, buffs, MJ, modales) sont deplacables.",
  "- Les positions et dimensions utiles sont memorisees entre les ouvertures.",
  "- La plupart des actions destructives passent par une confirmation.",
  "- De nombreux boutons sont conditionnels: ils apparaissent seulement quand une action est pertinente.",
  "",
  "Comportements de survol/clic a retenir:",
  "- Survol des lignes: revele les actions rapides (Edit/x/^/v).",
  "- Clic gauche: action principale (selection, ouverture, reduction/extension).",
  "- Clic droit: edition rapide sur les elements qui le supportent.",
  "",
  "==============================",
  "11) Commandes utiles",
  "==============================",
  "- /easy pj : ouvre la fenetre joueur (mainframe).",
  "- /easy mj : ouvre la fenetre MJ.",
  "- /easy profils : acces rapide au mode profils.",
  "",
  "==============================",
  "12) Bonnes pratiques",
  "==============================",
  "- Garde des noms de profils clairs et stables.",
  "- Evite les doublons de rands/buffs pour garder une lecture simple.",
  "- Verifie regulierement ton mob actif avant d'envoyer une attaque MJ.",
  "- Utilise les resets seulement quand necessaire et apres verification.",
  "",
  "Fin du guide."
}

local UI_LAYOUT = {
  header = {
    topRightX = -5,
    topRightY = -4,
    buttonHeight = 18,
    gap = 4,
    infoUnderResetY = -2,
    infoWhenNoResetY = -24,
    resetWidth = 54,
    infoWidth = 54,
    buffsWidth = 54,
    mjWidth = 72,
    ficheWidth = 58,
  },
  infoWindow = {
    width = 640,
    height = 560,
    topPad = 14,
    titleTop = -10,
    closeTop = -6,
    closeRight = -6,
    scrollLeft = 12,
    scrollTop = -38,
    scrollRight = -12,
    scrollBottom = 40,
    contentInset = 8,
    closeButtonWidth = 110,
    closeButtonHeight = 22,
    closeButtonRight = -12,
    closeButtonBottom = 12,
  },
  profile = {
    barHeight = 40,
    barTopOffset = 10,
    barSideInset = 5,
    actionBtnWidth = 22,
    actionBtnHeight = 20,
    actionBtnRight = -6,
    actionBtnTop = -12,
    dropBtnWidth = 170,
    dropBtnHeight = 20,
    dropBtnGap = 6,
    dropTextLeft = 8,
    dropTextRight = -18,
    dropArrowRight = -6,
    popupRowHeight = 22,
    popupWidth = 170,
    popupRowInset = 2,
    popupTopOffset = -2,
    popupMenuWidth = 132,
    popupMenuHeight = 124,
    popupMenuBtnWidth = 128,
    popupMenuStepY = 24,
    popupAnchorOffsetY = -2,
    normalBg = { r = 0.08, g = 0.13, b = 0.23, a = 0.92 },
    normalBorder = { r = 1.0, g = 0.84, b = 0.30, a = 0.9 },
    highlightedBg = { r = 0.12, g = 0.20, b = 0.34, a = 0.95 },
    highlightedBorder = { r = 1.0, g = 0.88, b = 0.42, a = 0.95 },
  },
  textFieldsModal = {
    width = 320,
    minHeight = 130,
    initialHeight = 150,
    frameLevel = 610,
    titleTop = -10,
    okWidth = 80,
    okHeight = 22,
    okRight = -12,
    okBottom = 10,
    cancelWidth = 70,
    cancelHeight = 22,
    rowWidth = 286,
    rowHeight = 22,
    rowEditWidth = 70,
    rowEditHeight = 18,
    firstRowTop = -10,
    rowSpacing = -8,
    baseHeight = 86,
    perRowHeight = 30,
  },
  mainScroll = {
    initialWidth = 200,
    initialHeight = 400,
    topInset = 2,
    topOffset = -2,
    bottomInset = 2,
    bottomOffset = 6,
    rightInset = -2,
    sectionItemGapY = 0,
  },
}

local PROFILE_BACKDROP = {
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  edgeSize = 10,
  insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

-- -----------------------------------------------------------------------------
-- Aide de style visuel (panneaux, boutons, couleurs)
-- ---------------------------------------------------------------------

local function apply_panel_theme(frame, soft, noShading)
  if not frame then
    return
  end

  if frame.SetBackdrop then
    frame:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      edgeSize = 12,
      insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
  end

  local bg = soft and THEME.panelBgSoft or THEME.panelBg
  if frame.SetBackdropColor then
    frame:SetBackdropColor(bg.r, bg.g, bg.b, bg.a)
  end
  if frame.SetBackdropBorderColor then
    frame:SetBackdropBorderColor(THEME.panelBorder.r, THEME.panelBorder.g, THEME.panelBorder.b, THEME.panelBorder.a)
  end

  if not noShading then
    if not frame.esTopSheen then
      local topSheen = frame:CreateTexture(nil, "BORDER")
      topSheen:SetTexture("Interface\\Buttons\\WHITE8X8")
      topSheen:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
      topSheen:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -3)
      topSheen:SetHeight(1)
      topSheen:SetVertexColor(1, 1, 1, 0.08)
      frame.esTopSheen = topSheen
    end

    if not frame.esBottomShade then
      local bottomShade = frame:CreateTexture(nil, "BORDER")
      bottomShade:SetTexture("Interface\\Buttons\\WHITE8X8")
      bottomShade:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 3, 3)
      bottomShade:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
      bottomShade:SetHeight(1)
      bottomShade:SetVertexColor(0, 0, 0, 0.18)
      frame.esBottomShade = bottomShade
    end
  end

end

local function style_font_string(fs, accent)
  if not fs or not fs.SetTextColor then
    return
  end
  local c = accent and THEME.accent or THEME.text
  fs:SetTextColor(c.r, c.g, c.b, c.a)
end

local function apply_button_theme(button, isPrimary)
  if not button then
    return
  end

  if button.SetBackdrop then
    button:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      edgeSize = 10,
      insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
  end

  local bgR, bgG, bgB, bgA = 0.08, 0.13, 0.23, 0.92

  if button.SetBackdropColor then
    button:SetBackdropColor(bgR, bgG, bgB, bgA)
  end
  if button.SetBackdropBorderColor then
    button:SetBackdropBorderColor(1.0, 0.84, 0.30, 0.9)
  end

  if not button.esButtonSheen then
    local sheen = button:CreateTexture(nil, "ARTWORK")
    sheen:SetTexture("Interface\\Buttons\\WHITE8X8")
    sheen:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    sheen:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
    sheen:SetHeight(1)
    sheen:SetVertexColor(1, 1, 1, 0.12)
    button.esButtonSheen = sheen
  end

  if not button.esButtonShade then
    local shade = button:CreateTexture(nil, "ARTWORK")
    shade:SetTexture("Interface\\Buttons\\WHITE8X8")
    shade:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 2, 2)
    shade:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    shade:SetHeight(1)
    shade:SetVertexColor(0, 0, 0, 0.2)
    button.esButtonShade = shade
  end

  local fs = button.text or button.label or button:GetFontString()
  style_font_string(fs, true)
end

local function create_header_button(parent, width, text, isPrimary)
  if not StdUi then
    return nil
  end
  local button = StdUi:Button(parent, width, UI_LAYOUT.header.buttonHeight, text)
  apply_button_theme(button, isPrimary)
  return button
end

local function set_profile_surface_colors(frame, highlighted)
  if not frame then
    return
  end

  local bg = highlighted and UI_LAYOUT.profile.highlightedBg or UI_LAYOUT.profile.normalBg
  local border = highlighted and UI_LAYOUT.profile.highlightedBorder or UI_LAYOUT.profile.normalBorder

  if frame.SetBackdropColor then
    frame:SetBackdropColor(bg.r, bg.g, bg.b, bg.a)
  end
  if frame.SetBackdropBorderColor then
    frame:SetBackdropBorderColor(border.r, border.g, border.b, border.a)
  end
end

local function apply_profile_surface(frame, highlighted)
  if not frame then
    return
  end
  if frame.SetBackdrop then
    frame:SetBackdrop(PROFILE_BACKDROP)
  end
  set_profile_surface_colors(frame, highlighted)
end

local function apply_icon_arrow_button_theme(button)
  if not button then
    return
  end

  if button.SetBackdrop then
    button:SetBackdrop(nil)
  end
  if button.SetBackdropColor then
    button:SetBackdropColor(0, 0, 0, 0)
  end
  if button.SetBackdropBorderColor then
    button:SetBackdropBorderColor(0, 0, 0, 0)
  end

  local normal = button.GetNormalTexture and button:GetNormalTexture()
  local pushed = button.GetPushedTexture and button:GetPushedTexture()
  local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
  local disabled = button.GetDisabledTexture and button:GetDisabledTexture()

  if normal then normal:SetAlpha(0) end
  if pushed then pushed:SetAlpha(0) end
  if highlight then highlight:SetAlpha(0) end
  if disabled then disabled:SetAlpha(0) end

  if button.icon and button.icon.SetVertexColor then
    button.icon:SetVertexColor(THEME.panelBorder.r, THEME.panelBorder.g, THEME.panelBorder.b, 1)
  end
  if button.iconDisabled and button.iconDisabled.SetVertexColor then
    button.iconDisabled:SetVertexColor(0.55, 0.60, 0.72, 0.9)
  end

  if not button.esHoverGlow then
    local glow = button:CreateTexture(nil, "BACKGROUND")
    glow:SetTexture("Interface\\Buttons\\WHITE8X8")
    glow:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    glow:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    glow:SetVertexColor(THEME.accent.r, THEME.accent.g, THEME.accent.b, 0.18)
    glow:Hide()
    button.esHoverGlow = glow
  end

  local function set_arrow_hover_state(self, hovered)
    local isEnabled = true
    if self.IsEnabled then
      isEnabled = self:IsEnabled()
    end

    if self.icon and self.icon.SetVertexColor then
      if hovered and isEnabled then
        self.icon:SetVertexColor(THEME.accent.r, THEME.accent.g, THEME.accent.b, 1)
      else
        self.icon:SetVertexColor(THEME.panelBorder.r, THEME.panelBorder.g, THEME.panelBorder.b, 1)
      end
    end

    if self.icon and self.icon.SetSize then
      if hovered and isEnabled then
        self.icon:SetSize(11, 11)
      else
        self.icon:SetSize(10, 10)
      end
    end

    if self.esHoverGlow then
      if hovered and isEnabled then
        self.esHoverGlow:Show()
      else
        self.esHoverGlow:Hide()
      end
    end
  end

  set_arrow_hover_state(button, false)

  if not button.esArrowThemeHooked then
    button.esArrowThemeHooked = true
    button:HookScript("OnEnter", function(self)
      set_arrow_hover_state(self, true)
    end)
    button:HookScript("OnLeave", function(self)
      set_arrow_hover_state(self, false)
    end)
    hooksecurefunc(button, "Disable", function(self)
      set_arrow_hover_state(self, false)
    end)
    hooksecurefunc(button, "Enable", function(self)
      set_arrow_hover_state(self, false)
    end)
  end
end

local function apply_editbox_theme(editBox)
  if not editBox then
    return
  end

  if editBox.SetBackdrop then
    editBox:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      edgeSize = 10,
      insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    editBox:SetBackdropColor(0.06, 0.10, 0.18, 0.95)
    editBox:SetBackdropBorderColor(0.62, 0.72, 0.90, 0.75)
  end

  if editBox.SetTextInsets then
    editBox:SetTextInsets(6, 6, 2, 2)
  end
  if editBox.SetTextColor then
    editBox:SetTextColor(THEME.text.r, THEME.text.g, THEME.text.b, THEME.text.a)
  end

  if editBox.HookScript then
    editBox:HookScript("OnEditFocusGained", function(self)
      if self.SetBackdropBorderColor then
        self:SetBackdropBorderColor(THEME.panelBorder.r, THEME.panelBorder.g, THEME.panelBorder.b, 1)
      end
    end)
    editBox:HookScript("OnEditFocusLost", function(self)
      if self.SetBackdropBorderColor then
        self:SetBackdropBorderColor(0.62, 0.72, 0.90, 0.75)
      end
    end)
  end
end

local function apply_checkbox_theme(checkbox)
  if not checkbox then
    return
  end

  if checkbox.SetBackdrop then
    checkbox:SetBackdrop(nil)
  end
  if checkbox.SetBackdropColor then
    checkbox:SetBackdropColor(0, 0, 0, 0)
  end
  if checkbox.SetBackdropBorderColor then
    checkbox:SetBackdropBorderColor(0, 0, 0, 0)
  end

  if checkbox.target then
    if checkbox.target.SetBackdrop then
      checkbox.target:SetBackdrop(nil)
    end
    if checkbox.target.SetBackdropColor then
      checkbox.target:SetBackdropColor(0, 0, 0, 0)
    end
    if checkbox.target.SetBackdropBorderColor then
      checkbox.target:SetBackdropBorderColor(0, 0, 0, 0)
    end
  end

  if checkbox.Text then
    style_font_string(checkbox.Text)
    checkbox.Text:ClearAllPoints()
    checkbox.Text:SetPoint("LEFT", checkbox, "LEFT", 20, 0)
  end

  local normal = checkbox.GetNormalTexture and checkbox:GetNormalTexture()
  local pushed = checkbox.GetPushedTexture and checkbox:GetPushedTexture()
  local checked = checkbox.GetCheckedTexture and checkbox:GetCheckedTexture()
  local highlight = checkbox.GetHighlightTexture and checkbox:GetHighlightTexture()

  if normal then normal:SetAlpha(0) end
  if pushed then pushed:SetAlpha(0) end
  if checked then checked:SetAlpha(0) end
  if highlight then highlight:SetAlpha(0) end
  if checkbox.checkedTexture then checkbox.checkedTexture:SetAlpha(0) end
  if checkbox.disabledCheckedTexture then checkbox.disabledCheckedTexture:SetAlpha(0) end

  if not checkbox.esBox then
    local box = CreateFrame("Frame", nil, checkbox, "BackdropTemplate")
    box:SetSize(14, 14)
    if checkbox.target then
      box:SetPoint("CENTER", checkbox.target, "CENTER", 0, 0)
    else
      box:SetPoint("LEFT", checkbox, "LEFT", 0, 0)
    end
    box:SetFrameLevel((checkbox:GetFrameLevel() or 1) + 8)
    box:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      edgeSize = 10,
      insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    box:SetBackdropColor(0.06, 0.11, 0.19, 0.96)
    box:SetBackdropBorderColor(THEME.panelBorder.r, THEME.panelBorder.g, THEME.panelBorder.b, 0.9)
    box:EnableMouse(false)

    local checkTex = box:CreateTexture(nil, "ARTWORK")
    checkTex:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    checkTex:SetSize(14, 14)
    checkTex:SetPoint("CENTER", box, "CENTER", 0, 0)
    checkTex:SetVertexColor(THEME.panelBorder.r, THEME.panelBorder.g, THEME.panelBorder.b, 1)

    checkbox.esBox = box
    checkbox.esCheckTex = checkTex
  end

  local function update_checkbox_state(self)
    if not self.esBox or not self.esCheckTex then
      return
    end
    local isChecked = self:GetChecked() and true or false
    self.esCheckTex:SetShown(isChecked)
    if isChecked then
      self.esBox:SetBackdropBorderColor(THEME.panelBorder.r, THEME.panelBorder.g, THEME.panelBorder.b, 1)
    else
      self.esBox:SetBackdropBorderColor(THEME.panelBorder.r, THEME.panelBorder.g, THEME.panelBorder.b, 0.9)
    end
  end

  update_checkbox_state(checkbox)

  if not checkbox.esThemeHooked then
    checkbox.esThemeHooked = true
    checkbox:SetScript("OnClick", function(self)
      if self.isDisabled then
        return
      end
      self:SetChecked(not self:GetChecked())
      update_checkbox_state(self)
    end)
    checkbox:SetScript("OnEnter", function(self)
      if self.esBox then
        self.esBox:SetBackdropBorderColor(THEME.panelBorder.r, THEME.panelBorder.g, THEME.panelBorder.b, 1)
      end
      if self.target and self.target.SetBackdropBorderColor then
        self.target:SetBackdropBorderColor(0, 0, 0, 0)
      end
      if self.SetBackdropBorderColor then
        self:SetBackdropBorderColor(0, 0, 0, 0)
      end
    end)
    checkbox:SetScript("OnLeave", function(self)
      if self.target and self.target.SetBackdropBorderColor then
        self.target:SetBackdropBorderColor(0, 0, 0, 0)
      end
      if self.SetBackdropBorderColor then
        self:SetBackdropBorderColor(0, 0, 0, 0)
      end
      update_checkbox_state(self)
    end)

    checkbox:HookScript("OnEnter", function(self)
      if self.target and self.target.SetBackdropBorderColor then
        self.target:SetBackdropBorderColor(0, 0, 0, 0)
      end
    end)
    checkbox:HookScript("OnLeave", function(self)
      if self.target and self.target.SetBackdropBorderColor then
        self.target:SetBackdropBorderColor(0, 0, 0, 0)
      end
    end)
  end

  if not checkbox.esStateSyncHooked then
    checkbox.esStateSyncHooked = true
    hooksecurefunc(checkbox, "SetChecked", function(self)
      update_checkbox_state(self)
    end)
    hooksecurefunc(checkbox, "Enable", function(self)
      update_checkbox_state(self)
    end)
    hooksecurefunc(checkbox, "Disable", function(self)
      update_checkbox_state(self)
    end)
  end
end

local function apply_scrollbar_theme(scrollWidget)
  if not scrollWidget then
    return
  end

  local scrollBar = scrollWidget.scrollBar
  if not scrollBar then
    return
  end

  if scrollBar.SetBackdrop then
    scrollBar:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      edgeSize = 10,
      insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    scrollBar:SetBackdropColor(0.05, 0.09, 0.16, 0.95)
    scrollBar:SetBackdropBorderColor(0.62, 0.72, 0.90, 0.8)
  end

  if scrollWidget.scrollBarWidth then
    scrollWidget.scrollBarWidth = 14
  end
  if scrollWidget.UpdateSize then
    scrollWidget:UpdateSize(scrollWidget:GetWidth(), scrollWidget:GetHeight())
  end

  local thumb = scrollBar.thumbTexture or (scrollBar.GetThumbTexture and scrollBar:GetThumbTexture())
  if scrollBar.SetThumbTexture then
    scrollBar:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    thumb = scrollBar.thumbTexture or (scrollBar.GetThumbTexture and scrollBar:GetThumbTexture())
  end
  if thumb and thumb.SetColorTexture then
    thumb:SetColorTexture(THEME.panelBorder.r, THEME.panelBorder.g, THEME.panelBorder.b, 0.72)
  elseif thumb and thumb.SetVertexColor then
    thumb:SetVertexColor(THEME.panelBorder.r, THEME.panelBorder.g, THEME.panelBorder.b, 0.72)
  end

  if thumb and thumb.SetBlendMode then
    thumb:SetBlendMode("BLEND")
  end

  local function suppress_native_arrow_button(button)
    if not button then
      return
    end

    local function strip_all_textures(btn)
      if not btn or not btn.GetNumRegions then
        return
      end
      for i = 1, btn:GetNumRegions() do
        local region = select(i, btn:GetRegions())
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
          region:SetTexture(nil)
        end
      end
    end

    local function clear_visuals(btn)
      strip_all_textures(btn)
      if btn.SetNormalTexture then btn:SetNormalTexture(nil) end
      if btn.SetPushedTexture then btn:SetPushedTexture(nil) end
      if btn.SetHighlightTexture then btn:SetHighlightTexture(nil) end
      if btn.SetDisabledTexture then btn:SetDisabledTexture(nil) end
      if btn.SetBackdrop then btn:SetBackdrop(nil) end
      if btn.SetBackdropColor then btn:SetBackdropColor(0, 0, 0, 0) end
      if btn.SetBackdropBorderColor then btn:SetBackdropBorderColor(0, 0, 0, 0) end
      btn:SetAlpha(0)
      btn:SetSize(1, 1)
      btn:EnableMouse(false)
    end

    clear_visuals(button)
    if not button.esArrowSuppressed then
      button.esArrowSuppressed = true
      button:HookScript("OnShow", clear_visuals)
      hooksecurefunc(button, "Enable", clear_visuals)
      hooksecurefunc(button, "Disable", clear_visuals)
    end
  end

  local function ensure_proxy_arrow(direction)
    local arrowButtonSize = 14
    local key = direction == "UP" and "esProxyUp" or "esProxyDown"
    if scrollBar[key] then
      return scrollBar[key]
    end

    local parent = scrollBar.panel or scrollBar
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(arrowButtonSize, arrowButtonSize)
    btn:SetFrameLevel((parent:GetFrameLevel() or 1) + 8)
    btn:SetBackdrop(nil)
    if direction == "UP" then
      btn:SetPoint("TOP", parent, "TOP", 0, 0)
    else
      btn:SetPoint("BOTTOM", parent, "BOTTOM", 0, 0)
    end

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Buttons\\SquareButtonTextures")
    icon:SetSize(12, 12)
    icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
    if direction == "UP" then
      icon:SetTexCoord(0.45312500, 0.64062500, 0.01562500, 0.20312500)
    else
      icon:SetTexCoord(0.45312500, 0.64062500, 0.20312500, 0.01562500)
    end

    btn.esArrowIcon = icon
    scrollBar[key] = btn
    return btn
  end

  local function set_proxy_arrow_visual(button, hover)
    if not button or not button.esArrowIcon then
      return
    end

    local silverR, silverG, silverB, silverA = 0.84, 0.89, 0.98, 1
    local hoverR, hoverG, hoverB, hoverA = 0.97, 1.00, 1.00, 1
    local disabledR, disabledG, disabledB, disabledA = 0.48, 0.53, 0.63, 0.88

    local r, g, b, a = silverR, silverG, silverB, silverA
    if button.IsEnabled and not button:IsEnabled() then
      r, g, b, a = disabledR, disabledG, disabledB, disabledA
    elseif hover then
      r, g, b, a = hoverR, hoverG, hoverB, hoverA
    end

    button.esArrowIcon:SetVertexColor(r, g, b, a)
  end

  if scrollBar.ScrollUpButton then
    suppress_native_arrow_button(scrollBar.ScrollUpButton)
  end
  if scrollBar.ScrollDownButton then
    suppress_native_arrow_button(scrollBar.ScrollDownButton)
  end

  local proxyUp = ensure_proxy_arrow("UP")
  local proxyDown = ensure_proxy_arrow("DOWN")

  local trackInset = 15
  if scrollBar.ClearAllPoints and scrollBar.panel then
    scrollBar:ClearAllPoints()
    scrollBar:SetPoint("TOPLEFT", scrollBar.panel, "TOPLEFT", 0, -trackInset)
    scrollBar:SetPoint("TOPRIGHT", scrollBar.panel, "TOPRIGHT", 0, -trackInset)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBar.panel, "BOTTOMLEFT", 0, trackInset)
    scrollBar:SetPoint("BOTTOMRIGHT", scrollBar.panel, "BOTTOMRIGHT", 0, trackInset)
  end

  proxyUp:SetScript("OnClick", function()
    local value = scrollBar:GetValue()
    local minVal = select(1, scrollBar:GetMinMaxValues())
    local step = scrollBar.scrollStep or ((scrollWidget.scrollFrame and scrollWidget.scrollFrame:GetHeight()) or 40) / 2
    scrollBar:SetValue(math.max(minVal, value - step))
  end)
  proxyDown:SetScript("OnClick", function()
    local value = scrollBar:GetValue()
    local maxVal = select(2, scrollBar:GetMinMaxValues())
    local step = scrollBar.scrollStep or ((scrollWidget.scrollFrame and scrollWidget.scrollFrame:GetHeight()) or 40) / 2
    scrollBar:SetValue(math.min(maxVal, value + step))
  end)

  if not proxyUp.esHoverHooked then
    proxyUp.esHoverHooked = true
    proxyUp:HookScript("OnEnter", function(self) set_proxy_arrow_visual(self, true) end)
    proxyUp:HookScript("OnLeave", function(self) set_proxy_arrow_visual(self, false) end)
  end
  if not proxyDown.esHoverHooked then
    proxyDown.esHoverHooked = true
    proxyDown:HookScript("OnEnter", function(self) set_proxy_arrow_visual(self, true) end)
    proxyDown:HookScript("OnLeave", function(self) set_proxy_arrow_visual(self, false) end)
  end

  local function sync_proxy_arrows_state()
    local minVal, maxVal = scrollBar:GetMinMaxValues()
    local value = scrollBar:GetValue()
    local hasRange = (maxVal - minVal) > 0.005

    proxyUp:Show()
    proxyDown:Show()

    if not hasRange then
      proxyUp:Disable()
      proxyDown:Disable()
      set_proxy_arrow_visual(proxyUp, false)
      set_proxy_arrow_visual(proxyDown, false)
      return
    end

    if value > (minVal + 0.005) then
      proxyUp:Enable()
    else
      proxyUp:Disable()
    end

    if value < (maxVal - 0.005) then
      proxyDown:Enable()
    else
      proxyDown:Disable()
    end

    set_proxy_arrow_visual(proxyUp, false)
    set_proxy_arrow_visual(proxyDown, false)
  end

  if not scrollBar.esProxyStateHooked then
    scrollBar.esProxyStateHooked = true
    scrollBar:HookScript("OnValueChanged", sync_proxy_arrows_state)
    if scrollWidget.scrollFrame then
      scrollWidget.scrollFrame:HookScript("OnScrollRangeChanged", sync_proxy_arrows_state)
    end
  end

  sync_proxy_arrows_state()
end

INTERNALS.apply_panel_theme = apply_panel_theme
INTERNALS.apply_button_theme = apply_button_theme
INTERNALS.apply_icon_arrow_button_theme = apply_icon_arrow_button_theme
INTERNALS.style_font_string = style_font_string
INTERNALS.apply_editbox_theme = apply_editbox_theme
INTERNALS.apply_checkbox_theme = apply_checkbox_theme
INTERNALS.apply_scrollbar_theme = apply_scrollbar_theme

-- Suivi global des menus ouverts
INTERNALS.openMenus = INTERNALS.openMenus or {}
function INTERNALS.is_any_menu_open()
  for _ in pairs(INTERNALS.openMenus) do return true end
  return false
end
function INTERNALS.register_menu_open(menuKey)
  INTERNALS.openMenus[menuKey] = true
end
function INTERNALS.register_menu_close(menuKey)
  INTERNALS.openMenus[menuKey] = nil
end

---@param modal EasySanaluneOutcomeModal
local function add_outcome_to_modal(modal, ebOutcomeValue, ebOutcomeText, update_outcomes_label)
  modal.outcomes = modal.outcomes or {}
  modal.outcomeRanges = modal.outcomeRanges or {}
  local minVal, maxVal, kind = parse_outcome_selector(ebOutcomeValue:GetText())
  if not kind then
    L_print("outcome_invalid")
    return
  end

  local text = tostring(ebOutcomeText:GetText() or "")
  text = string.gsub(text, "[\r\n]", " ")
  if text == "" then
    L_print("outcome_text_required")
    return
  end

  if kind == "single" then
    local outcomeKey = minVal
    if outcomeKey == nil then
      return
    end
    modal.outcomes[outcomeKey] = text
  else
    local replaced = false
    for i = 1, #modal.outcomeRanges do
      local entry = modal.outcomeRanges[i]
      if entry.min == minVal and entry.max == maxVal then
        entry.text = text
        replaced = true
        break
      end
    end
    if not replaced then
      table.insert(modal.outcomeRanges, { min = minVal, max = maxVal, text = text })
    end
  end

  ebOutcomeValue:SetText("")
  ebOutcomeText:SetText("")
  update_outcomes_label()
end
INTERNALS.add_outcome_to_modal = add_outcome_to_modal

---@param modal EasySanaluneOutcomeModal
local function remove_outcome_from_modal(modal, ebOutcomeValue, ebOutcomeText, update_outcomes_label)
  modal.outcomes = modal.outcomes or {}
  modal.outcomeRanges = modal.outcomeRanges or {}
  local minVal, maxVal, kind = parse_outcome_selector(ebOutcomeValue:GetText())
  if not kind then
    L_print("outcome_remove_prompt")
    return
  end

  if kind == "single" then
    local outcomeKey = minVal
    if outcomeKey == nil then
      return
    end
    if not modal.outcomes[outcomeKey] then
      L_print("outcome_not_found_single", tostring(minVal))
      return
    end
    modal.outcomes[outcomeKey] = nil
  else
    local removed = false
    for i = #modal.outcomeRanges, 1, -1 do
      local entry = modal.outcomeRanges[i]
      if entry.min == minVal and entry.max == maxVal then
        table.remove(modal.outcomeRanges, i)
        removed = true
      end
    end
    if not removed then
      L_print("outcome_not_found_range", tostring(minVal), tostring(maxVal))
      return
    end
  end

  ebOutcomeText:SetText("")
  update_outcomes_label()
end
INTERNALS.remove_outcome_from_modal = remove_outcome_from_modal

local function build_rand_pattern()
  if randPattern then
    return randPattern
  end

  local source = tostring(RANDOM_ROLL_RESULT or "%s rolls %d (%d-%d)")
  source = string.gsub(source, "%%(%d+)%$s", "<<<S%1>>>")
  source = string.gsub(source, "%%s", "<<<S>>>")
  source = string.gsub(source, "%%(%d+)%$d", "<<<D%1>>>")
  source = string.gsub(source, "%%d", "<<<D>>>")
  source = string.gsub(source, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
  source = string.gsub(source, "<<<S%d*>>>", "(.+)")
  source = string.gsub(source, "<<<D%d*>>>", "(%%d+)")
  randPattern = source
  return randPattern
end

local function parse_roll_message(message)
  if not message or message == "" then
    return nil, nil, nil, nil
  end

  local pattern = build_rand_pattern()
  local roller, roll, min, max = string.match(message, pattern)
  if not roller then
    return nil, nil, nil, nil
  end

  roll = tonumber(roll)
  min = tonumber(min)
  max = tonumber(max)
  if not roll or not min or not max then
    return nil, nil, nil, nil
  end

  return roller, roll, min, max
end

local function is_local_player_roll(roller)
  local shortName = Ambiguate(tostring(roller or ""), "short")
  return shortName == UnitName("player")
end

local function setup_rand_listener()
  if randListenerFrame then
    return
  end

  randListenerFrame = CreateFrame("Frame")
  randListenerFrame:RegisterEvent("CHAT_MSG_SYSTEM")
  randListenerFrame:SetScript("OnEvent", function(_, _, message)
    if not STATE or not STATE.rand_result_reader then
      return
    end

    local pending = UI.pendingRand
    if not pending then
      return
    end

    if GetTime() - (pending.time or 0) > 8 then
      UI.pendingRand = nil
      return
    end

    local roller, roll, min, max = parse_roll_message(message)
    if not roller or not is_local_player_roll(roller) then
      return
    end

    if pending.min ~= min or pending.max ~= max then
      return
    end

    local outcomes = pending.outcomes
    local text = outcomes and outcomes[roll]
    if not text or text == "" then
      local ranges = pending.outcomeRanges
      if type(ranges) == "table" then
        for i = 1, #ranges do
          local entry = ranges[i]
          if entry and roll >= entry.min and roll <= entry.max then
            text = entry.text
            break
          end
        end
      end
    end
    if text and text ~= "" then
      if IsInRaid() then
        ---@diagnostic disable-next-line:deprecated
        SendChatMessage(escape_chat_message(text), "RAID")
      else
        L_print("rand_reader_text", text)
      end
    end

    UI.pendingRand = nil
  end)
end
  -- -----------------------------------------------------------------------------
  -- Outils UI generiques (listes, alignement pixel, placement des fenetres)
  -- -----------------------------------------------------------------------------

UI.form_list = {}
UI.isResizing = false
UI.draggedRand = nil
UI.dragHoverSection = nil
UI.draggedSection = nil
UI.dragHoverTargetSection = nil
UI.section_widgets = {}

local function release_body()
  if UI.BODY ~= nil then
    UI.BODY:Hide()
    UI.BODY:SetParent(nil)
    UI.BODY = nil
  end
end

local function toggle_widgets(widgets, visible)
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
INTERNALS.toggle_widgets = toggle_widgets

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

local function move_entry(list, entry, direction)
  if type(list) ~= "table" then
    return false
  end
  local count = #list
  for i = 1, count do
    if list[i] == entry then
      local target = i + direction
      if target < 1 or target > count then
        return false
      end
      local tmp = list[i]
      list[i] = list[target]
      list[target] = tmp
      return true
    end
  end
  return false
end

local function snap_to_pixel(value)
  local scale = UIParent and UIParent:GetEffectiveScale() or 1
  if not scale or scale <= 0 then
    return math.floor((value or 0) + 0.5)
  end
  return math.floor(((value or 0) * scale) + 0.5) / scale
end

local function apply_main_frame_position()
  local function get_min_main_frame_right(frameWidth)
    local minRight = frameWidth or 0
    if STATE and STATE.buffs_visible and STATE.shown ~= false then
      minRight = minRight + (tonumber(STATE.buff_dim_w) or 0) + 8
    end
    return minRight
  end

  STATE.pos_x = snap_to_pixel(UI.MAIN_FRAME:GetRight())
  STATE.pos_y = snap_to_pixel(UI.MAIN_FRAME:GetTop())
  STATE.pos_x = max(get_min_main_frame_right(UI.MAIN_FRAME:GetWidth()), STATE.pos_x)
  STATE.pos_x = min(STATE.pos_x, UIParent:GetWidth())
  STATE.pos_y = max(UI.MAIN_FRAME:GetHeight(), STATE.pos_y)
  STATE.pos_y = min(STATE.pos_y, UIParent:GetHeight())
  UI.MAIN_FRAME:ClearAllPoints()
  UI.MAIN_FRAME:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", snap_to_pixel(STATE.pos_x), snap_to_pixel(STATE.pos_y))
  if UI.Buffs and UI.Buffs.SyncToMainFrame then
    UI.Buffs.SyncToMainFrame()
  end
end

local function sync_main_frame_during_drag(frame)
  if not frame then
    return
  end

  local right = frame:GetRight()
  local top = frame:GetTop()
  if not right or not top then
    return
  end

  local minRight = frame:GetWidth() or 0
  if STATE and STATE.buffs_visible and STATE.shown ~= false then
    minRight = minRight + (tonumber(STATE.buff_dim_w) or 0) + 8
  end

  local clampedRight = max(minRight, min(right, UIParent:GetWidth()))
  local clampedTop = max(frame:GetHeight() or 0, min(top, UIParent:GetHeight()))

  if clampedRight ~= right or clampedTop ~= top then
    frame:ClearAllPoints()
    frame:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", snap_to_pixel(clampedRight), snap_to_pixel(clampedTop))
  end

  if UI.Buffs and UI.Buffs.SyncToMainFrame then
    UI.Buffs.SyncToMainFrame()
  end
end

local function clamp_main_frame_state_position(frameWidth, frameHeight)
  local minRight = frameWidth or 0
  if STATE and STATE.buffs_visible and STATE.shown ~= false then
    minRight = minRight + (tonumber(STATE.buff_dim_w) or 0) + 8
  end

  STATE.pos_x = max(minRight, STATE.pos_x)
  STATE.pos_x = min(UIParent:GetWidth(), STATE.pos_x)
  STATE.pos_y = max(frameHeight or 0, STATE.pos_y)
  STATE.pos_y = min(UIParent:GetHeight(), STATE.pos_y)
end

local function refresh_main_frame_texture()
  if not UI.MAIN_FRAME or not UI.MAIN_FRAME.texture then
    return
  end

  UI.MAIN_FRAME.texture:ClearAllPoints()
  UI.MAIN_FRAME.texture:SetPoint("TOPLEFT", UI.MAIN_FRAME, "TOPLEFT", 3, -3)
  UI.MAIN_FRAME.texture:SetPoint("BOTTOMRIGHT", UI.MAIN_FRAME, "BOTTOMRIGHT", -3, 3)
end

local function set_resize_visual_state(isActive)
  -- noop: keep border overlay visible during resize
end

local function ensure_modal_positions()
  if not STATE then
    return
  end
  if type(STATE.modal_positions) ~= "table" then
    STATE.modal_positions = {}
  end
end

local function apply_modal_position(modal, positionKey)
  if not modal or not positionKey then
    return
  end

  ensure_modal_positions()
  local saved = STATE and STATE.modal_positions and STATE.modal_positions[positionKey]
  if type(saved) == "table" and saved.x and saved.y then
    modal:ClearAllPoints()
    modal:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", saved.x, saved.y)
  else
    modal:ClearAllPoints()
    modal:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  end
end
INTERNALS.apply_modal_position = apply_modal_position

local function save_modal_position(modal, positionKey)
  if not modal or not positionKey then
    return
  end

  ensure_modal_positions()

  local x = modal:GetRight()
  local y = modal:GetTop()
  if not x or not y then
    return
  end

  x = max(modal:GetWidth(), x)
  x = min(x, UIParent:GetWidth())
  y = max(modal:GetHeight(), y)
  y = min(y, UIParent:GetHeight())

  STATE.modal_positions[positionKey] = { x = x, y = y }
  _G.EASY_SANALUNE_SAVED_STATE = STATE

  modal:ClearAllPoints()
  modal:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", x, y)
end

local function make_modal_draggable(modal, positionKey)
  if not modal then
    return
  end

  modal:SetMovable(true)
  modal:SetClampedToScreen(true)

  local dragHandle = CreateFrame("Frame", nil, modal)
  dragHandle:SetPoint("TOPLEFT", modal, "TOPLEFT", 0, 0)
  dragHandle:SetPoint("TOPRIGHT", modal, "TOPRIGHT", 0, 0)
  dragHandle:SetHeight(24)
  dragHandle:EnableMouse(true)
  dragHandle:RegisterForDrag("LeftButton")
  dragHandle:SetScript("OnDragStart", function()
    modal:StartMoving()
  end)
  dragHandle:SetScript("OnDragStop", function()
    modal:StopMovingOrSizing()
    save_modal_position(modal, positionKey)
  end)

  modal.dragHandle = dragHandle
end

local function create_themed_draggable_modal(frameName, width, height, frameLevel, positionKey, startHidden)
  local modal = CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
  modal:SetSize(width, height)
  modal:SetFrameStrata("DIALOG")
  modal:SetFrameLevel(frameLevel)
  modal:EnableMouse(true)
  modal:SetClampedToScreen(true)
  apply_panel_theme(modal)
  make_modal_draggable(modal, positionKey)
  if startHidden then
    modal:Hide()
  end
  return modal
end
INTERNALS.make_modal_draggable = make_modal_draggable

-- -----------------------------------------------------------------------------
-- Guide Infos (fenetre + ouverture automatique une seule fois)
-- -----------------------------------------------------------------------------
local infosGuideWindow = nil

local function get_infos_help_text()
  return table.concat(INFOS_GUIDE_LINES, "\n")
end

local function open_infos_guide_window()
  if not StdUi then
    return false
  end

  if not infosGuideWindow then
    infosGuideWindow = create_themed_draggable_modal(
      "EasySanaluneInfoWindow",
      UI_LAYOUT.infoWindow.width,
      UI_LAYOUT.infoWindow.height,
      610,
      "info_window",
      false
    )

    local titleFs = infosGuideWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleFs:SetPoint("TOPLEFT", infosGuideWindow, "TOPLEFT", UI_LAYOUT.infoWindow.topPad, UI_LAYOUT.infoWindow.titleTop)
    titleFs:SetText(L_get("ui_info_window_title"))
    style_font_string(titleFs, true)

    local closeBtn = StdUi:Button(infosGuideWindow, 20, 20, "x")
    closeBtn:SetPoint("TOPRIGHT", infosGuideWindow, "TOPRIGHT", UI_LAYOUT.infoWindow.closeRight, UI_LAYOUT.infoWindow.closeTop)
    apply_button_theme(closeBtn)

    local closeBtnLabel = closeBtn:GetFontString()
    if closeBtnLabel then
      closeBtnLabel:ClearAllPoints()
      closeBtnLabel:SetPoint("CENTER", closeBtn, "CENTER", 0, 1)
    end

    local guideScroll = StdUi:ScrollFrame(
      infosGuideWindow,
      UI_LAYOUT.infoWindow.width - 32,
      UI_LAYOUT.infoWindow.height - 84
    )
    guideScroll:SetPoint("TOPLEFT", infosGuideWindow, "TOPLEFT", UI_LAYOUT.infoWindow.scrollLeft, UI_LAYOUT.infoWindow.scrollTop)
    guideScroll:SetPoint("BOTTOMRIGHT", infosGuideWindow, "BOTTOMRIGHT", UI_LAYOUT.infoWindow.scrollRight, UI_LAYOUT.infoWindow.scrollBottom)
    apply_panel_theme(guideScroll, true)
    if INTERNALS.apply_scrollbar_theme then
      INTERNALS.apply_scrollbar_theme(guideScroll)
    end

    local guideContent = guideScroll.scrollChild
    if guideContent then
      local guideFs = guideContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      guideFs:SetPoint("TOPLEFT", guideContent, "TOPLEFT", UI_LAYOUT.infoWindow.contentInset, -UI_LAYOUT.infoWindow.contentInset)
      guideFs:SetPoint("TOPRIGHT", guideContent, "TOPRIGHT", -UI_LAYOUT.infoWindow.contentInset, -UI_LAYOUT.infoWindow.contentInset)
      guideFs:SetJustifyH("LEFT")
      guideFs:SetJustifyV("TOP")
      guideFs:SetTextColor(0.95, 0.95, 0.95)
      guideFs:SetText(get_infos_help_text())
      C_Timer.After(0, function()
        if not guideContent or not guideFs then
          return
        end
        local textHeight = guideFs:GetStringHeight() or 0
        guideContent:SetHeight(math.max(480, textHeight + 16))
      end)
    end

    local closeGuideBtn = StdUi:Button(
      infosGuideWindow,
      UI_LAYOUT.infoWindow.closeButtonWidth,
      UI_LAYOUT.infoWindow.closeButtonHeight,
      L_get("common_close")
    )
    closeGuideBtn:SetPoint("BOTTOMRIGHT", infosGuideWindow, "BOTTOMRIGHT", UI_LAYOUT.infoWindow.closeButtonRight, UI_LAYOUT.infoWindow.closeButtonBottom)
    apply_button_theme(closeGuideBtn)

    closeBtn:SetScript("OnClick", function()
      infosGuideWindow:Hide()
      INTERNALS.register_menu_close("infoWindow")
    end)
    closeGuideBtn:SetScript("OnClick", function()
      infosGuideWindow:Hide()
      INTERNALS.register_menu_close("infoWindow")
    end)
    infosGuideWindow:SetScript("OnHide", function()
      INTERNALS.register_menu_close("infoWindow")
    end)
  end

  apply_modal_position(infosGuideWindow, "info_window")
  infosGuideWindow:Show()
  INTERNALS.register_menu_open("infoWindow")
  return true
end

UI.OpenInfosGuide = function()
  return open_infos_guide_window()
end

UI.MaybeShowInfosGuideOnce = function()
  if not STATE then
    return
  end

  ensure_modal_positions()
  if STATE.modal_positions and STATE.modal_positions.info_window_first_open_done then
    return
  end

  C_Timer.After(0, function()
    if UI.OpenInfosGuide and UI.OpenInfosGuide() then
      ensure_modal_positions()
      STATE.modal_positions.info_window_first_open_done = { x = 1, y = 1 }
      _G.EASY_SANALUNE_SAVED_STATE = STATE
    end
  end)
end

-- -----------------------------------------------------------------------------
-- Cycle de vie de l'UI (init, construction, refresh, affichage)
-- -----------------------------------------------------------------------------
---@param state EasySanaluneState
UI.init_ui = function(state)
  STATE = state
  StdUi = _G.StdUi
  ensure_modal_positions()
  normalize_chars(STATE and STATE.CHARS)
  if STATE.rand_result_reader == nil then
    STATE.rand_result_reader = false
  end
  setup_rand_listener()
  if UI.EnsurePlayerSurvivalTooltipHook then
    UI.EnsurePlayerSurvivalTooltipHook()
  end
end

UI.reset_modal_positions = function()
  ensure_modal_positions()
  local infoGuideSeenMarker = nil
  if STATE.modal_positions then
    infoGuideSeenMarker = STATE.modal_positions.info_window_first_open_done
  end
  STATE.modal_positions = {}
  if infoGuideSeenMarker then
    STATE.modal_positions.info_window_first_open_done = infoGuideSeenMarker
  end
  _G.EASY_SANALUNE_SAVED_STATE = STATE

  local modals = {
    { UI.NEW_RAND_MODAL, "new_rand" },
    { UI.NEW_SECTION_MODAL, "new_section" },
    { UI.EDIT_RAND_MODAL, "edit_rand" },
    { UI.EDIT_SECTION_MODAL, "edit_section" },
    { UI.Buffs and UI.Buffs.modal or nil, "buff_modal" },
  }

  for i = 1, #modals do
    local modal = modals[i][1]
    local key = modals[i][2]
    if modal then
      apply_modal_position(modal, key)
    end
  end
end

UI.build_ui = function()
  UI.MAIN_FRAME = StdUi:PanelWithTitle(UIParent, 200, 50, UnitName("player"), 200, 32)
  UI.MAIN_FRAME.titlePanel.label:SetText(L_get("ui_title"))
  apply_panel_theme(UI.MAIN_FRAME)
  if UI.MAIN_FRAME.titlePanel then
    if UI.MAIN_FRAME.titlePanel.SetBackdrop then
      UI.MAIN_FRAME.titlePanel:SetBackdrop(nil)
    end
    if UI.MAIN_FRAME.titlePanel.SetBackdropColor then
      UI.MAIN_FRAME.titlePanel:SetBackdropColor(0, 0, 0, 0)
    end
    if UI.MAIN_FRAME.titlePanel.SetBackdropBorderColor then
      UI.MAIN_FRAME.titlePanel:SetBackdropBorderColor(0, 0, 0, 0)
    end
  end
  style_font_string(UI.MAIN_FRAME.titlePanel.label, true)

  UI.MAIN_FRAME.texture = UI.MAIN_FRAME:CreateTexture(nil, "BACKGROUND", nil, -8)
  refresh_main_frame_texture()
  UI.MAIN_FRAME.texture:SetBlendMode("BLEND")
  UI.MAIN_FRAME.texture:SetAlpha(0.12)
  UI.MAIN_FRAME.texture:SetTexture("Interface\\AddOns\\Epsilon_Map\\Assets\\UI\\CartographerPanelBG")

  -- Position de depart
  clamp_main_frame_state_position(UI.MAIN_FRAME:GetWidth(), UI.MAIN_FRAME:GetHeight())
  UI.MAIN_FRAME:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", STATE.pos_x, STATE.pos_y)

  -- Deplacement de la fenetre
  UI.MAIN_FRAME:SetMovable(true)
  UI.MAIN_FRAME:SetResizable(true)
  UI.MAIN_FRAME:EnableMouse(true)
  UI.MAIN_FRAME:RegisterForDrag("LeftButton")
  UI.MAIN_FRAME:SetScript("OnDragStart", function(self)
    self:StartMoving()
    self:SetScript("OnUpdate", function(frame)
      sync_main_frame_during_drag(frame)
    end)
  end)
  UI.MAIN_FRAME:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    self:SetScript("OnUpdate", nil)
    apply_main_frame_position()
    _G.EASY_SANALUNE_SAVED_STATE = STATE
  end)

  -- Redimensionnement
  UI.resizeButton = UI.build_resizeButton()

  -- Boutons ouvrir/fermer du contenu
  UI.BUTTON_EXPAND = StdUi:SquareButton(UI.MAIN_FRAME, 20, 20, 'DOWN')
  UI.BUTTON_EXPAND:SetPoint("TOPRIGHT")
  UI.BUTTON_EXPAND:SetScript("OnClick", UI.EXPAND)
  apply_button_theme(UI.BUTTON_EXPAND)

  UI.BUTTON_HIDE = StdUi:SquareButton(UI.MAIN_FRAME, 20, 20, 'UP')
  UI.BUTTON_HIDE:SetPoint("TOPRIGHT")
  UI.BUTTON_HIDE:SetScript("OnClick", UI.HIDE)
  apply_button_theme(UI.BUTTON_HIDE)

  -- Etat d'affichage initial
  if STATE.shown then
    UI.EXPAND()
  else
    UI.HIDE()
  end
end

-- Rafraichissement principal
UI.refresh_in_progress = false
UI.refresh_requested = false

UI.REFRESH = function()
  if UI.refresh_in_progress then
    UI.refresh_requested = true
    return
  end

  UI.refresh_in_progress = true
  repeat
    UI.refresh_requested = false
    if UI.update_reset_button_visibility then
      UI.update_reset_button_visibility()
    end
    UI.HIDE()
    UI.EXPAND()
  until not UI.refresh_requested
  UI.refresh_in_progress = false
end

local function get_min_frame_size()
  -- Largeur minimale adaptee au contexte: le mode MJ reserve plus d'espace aux actions de droite.
  local minWidth
  if STATE and STATE.mj_enabled then
    minWidth = 460
  else
    minWidth = 380
  end
  local bodyChromeHeight = 45
  local headerAndOffsets = 92   -- hauteur du bandeau (88) + marges techniques
  local profileAndOffsets = 48
  local minScrollHeight = 40 + EXTRA_MAINFRAME_HEIGHT

  local minBodyHeight = headerAndOffsets + profileAndOffsets + minScrollHeight

  local minHeight = bodyChromeHeight + minBodyHeight
  return minWidth, minHeight
end

UI.set_profile_mode = function(enabled)
  STATE.profile_mode = enabled and true or false
  if UI.profileBar then
    UI.profileBar:Show()
  end
  if UI.profileControls then
    for i = 1, #UI.profileControls do
      local w = UI.profileControls[i]
      if w then
        if STATE.profile_mode then
          w:Show()
        else
          w:Hide()
        end
      end
    end
  end
  if UI.update_scroll_anchor then
    UI.update_scroll_anchor()
  end

  local minWidth, minHeight = get_min_frame_size()
  if UI.MAIN_FRAME and UI.MAIN_FRAME.SetMinResize then
    UI.MAIN_FRAME:SetMinResize(minWidth, minHeight)
  end
  if UI.MAIN_FRAME and STATE.shown then
    local width = UI.MAIN_FRAME:GetWidth()
    local height = UI.MAIN_FRAME:GetHeight()
    local changed = false
    if width < minWidth then
      width = minWidth
      changed = true
    end
    if height < minHeight then
      height = minHeight
      changed = true
    end
    if changed then
      UI.MAIN_FRAME:SetWidth(width)
      UI.MAIN_FRAME:SetHeight(height)
      apply_main_frame_position()
      refresh_main_frame_texture()
      STATE.dim_show_w = UI.MAIN_FRAME:GetWidth()
      STATE.dim_show_h = UI.MAIN_FRAME:GetHeight()
      _G.EASY_SANALUNE_SAVED_STATE = STATE
    end
  end
end

UI.set_mj_mode = UI.set_profile_mode

-- Replier la fenetre
UI.HIDE = function()
  if UI.Buffs and UI.Buffs.OnMainHide then
    UI.Buffs.OnMainHide()
  end
  UI.BUTTON_HIDE:Hide()
  UI.BUTTON_EXPAND:Show()
  UI.resizeButton:Hide()
  UI.MAIN_FRAME:SetWidth(STATE.dim_hide_w)
  UI.MAIN_FRAME:SetHeight(STATE.dim_hide_h)
  release_body()
  UI.MAIN_FRAME:ClearAllPoints()
  UI.MAIN_FRAME:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", STATE.pos_x, STATE.pos_y)
  refresh_main_frame_texture()
  UI.MAIN_FRAME.texture:SetAlpha(0)
  STATE.shown = false
end

-- Deplier la fenetre
UI.EXPAND = function()
  UI.BUTTON_EXPAND:Hide()
  UI.BUTTON_HIDE:Show()
  UI.resizeButton:Show()
  release_body()
  local minWidth, minHeight = get_min_frame_size()
  STATE.dim_show_w = max(STATE.dim_show_w, minWidth)
  STATE.dim_show_h = max(STATE.dim_show_h, minHeight)
  UI.MAIN_FRAME:SetWidth(STATE.dim_show_w)
  UI.MAIN_FRAME:SetHeight(STATE.dim_show_h)
  UI.MAIN_FRAME:SetMinResize(minWidth, minHeight)
  UI.BODY = UI.build_body()
  UI.BODY:Show()
  STATE.shown = true
  clamp_main_frame_state_position(UI.MAIN_FRAME:GetWidth(), UI.MAIN_FRAME:GetHeight())
  UI.MAIN_FRAME:ClearAllPoints()
  UI.MAIN_FRAME:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", STATE.pos_x, STATE.pos_y)
  UI.MAIN_FRAME.texture:SetAlpha(0.14)
  refresh_main_frame_texture()

  if UI.Buffs and UI.Buffs.OnMainShow then
    UI.Buffs.OnMainShow()
  end
end

-- Construction du bouton de redimensionnement
UI.build_resizeButton = function()
  local resizeButton = CreateFrame("Button", nil, UI.MAIN_FRAME)
  resizeButton:SetMovable(true)
  resizeButton:EnableMouse(true)
  resizeButton:SetSize(16, 16)
  resizeButton:SetPoint("BOTTOMRIGHT", UI.MAIN_FRAME, "BOTTOMRIGHT", 0, 0)
  resizeButton:SetFrameLevel(UI.MAIN_FRAME:GetFrameLevel() + 10)
  resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

  local dragStartX = nil
  local dragStartY = nil
  local dragStartWidth = nil
  local dragStartHeight = nil
  local dragStartRight = nil
  local dragStartTop = nil
  local dragPending = false

  local function stop_resize()
    dragPending = false
    if not UI.isResizing then
      return
    end
    UI.isResizing = false
    set_resize_visual_state(false)
    STATE.dim_show_w = snap_to_pixel(UI.MAIN_FRAME:GetWidth())
    STATE.dim_show_h = snap_to_pixel(UI.MAIN_FRAME:GetHeight())
    UI.MAIN_FRAME:SetWidth(STATE.dim_show_w)
    UI.MAIN_FRAME:SetHeight(STATE.dim_show_h)
    apply_main_frame_position()
    refresh_main_frame_texture()
    _G.EASY_SANALUNE_SAVED_STATE = STATE
  end

  resizeButton:SetScript("OnMouseDown", function(self, button)
    if button ~= "LeftButton" then
      return
    end
    if not STATE.shown then
      return
    end
    dragPending = true
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    dragStartX = x / scale
    dragStartY = y / scale
    dragStartWidth = UI.MAIN_FRAME:GetWidth()
    dragStartHeight = UI.MAIN_FRAME:GetHeight()
    dragStartRight = UI.MAIN_FRAME:GetRight()
    dragStartTop = UI.MAIN_FRAME:GetTop()
  end)

  resizeButton:SetScript("OnUpdate", function(self)
    if not dragPending then
      return
    end

    if not IsMouseButtonDown("LeftButton") then
      stop_resize()
      return
    end

    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    local curX = x / scale
    local curY = y / scale
    local deltaX = math.abs(curX - (dragStartX or curX))
    local deltaY = math.abs(curY - (dragStartY or curY))

    if not UI.isResizing and (deltaX > 4 or deltaY > 4) then
      UI.isResizing = true
      set_resize_visual_state(true)
    end

    if UI.isResizing then
      local moveX = curX - (dragStartX or curX)
      local moveY = curY - (dragStartY or curY)
      local startWidth = dragStartWidth or UI.MAIN_FRAME:GetWidth()
      local minWidth, minHeight = get_min_frame_size()
      -- Pendant le redimensionnement, on garde un mouvement fluide sans forcer la grille pixel.
      local newWidth = max(minWidth, startWidth + moveX)
      local newHeight = max(minHeight, (dragStartHeight or UI.MAIN_FRAME:GetHeight()) - moveY)
      local appliedMoveX = newWidth - startWidth
      local newRight = (dragStartRight or UI.MAIN_FRAME:GetRight()) + appliedMoveX
      local newTop = dragStartTop or UI.MAIN_FRAME:GetTop()

      newRight = max(newWidth, newRight)
      newRight = min(newRight, UIParent:GetWidth())
      newTop = max(newHeight, newTop)
      newTop = min(newTop, UIParent:GetHeight())

      UI.MAIN_FRAME:SetWidth(newWidth)
      UI.MAIN_FRAME:SetHeight(newHeight)
      UI.MAIN_FRAME:ClearAllPoints()
      UI.MAIN_FRAME:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", newRight, newTop)
      -- On n'actualise pas la texture ici pour eviter les sauts visuels pendant le drag.
    end
  end)

  resizeButton:SetScript("OnMouseUp", function(self, button)
    if button ~= "LeftButton" then
      return
    end
    stop_resize()
  end)

  return resizeButton
end

-- -----------------------------------------------------------------------------
-- Construction du corps principal (header, controles, listes, profils)
-- -----------------------------------------------------------------------------
UI.build_body = function()
  UI.update_add_buttons_layout = nil
  UI.buttonAddElem = nil
  UI.buttonAddSection = nil

  UI.BODY = StdUi:Panel(UI.MAIN_FRAME, 10, 10)
  StdUi:GlueAcross(UI.BODY, UI.MAIN_FRAME, 5, -35, -5, 10)
  apply_panel_theme(UI.BODY, false)

  if UI.BODY and UI.BODY.SetBackdropBorderColor then
    UI.BODY:SetBackdropBorderColor(0, 0, 0, 0)
  end

  local bodyBorderOverlay = CreateFrame("Frame", nil, UI.BODY, "BackdropTemplate")
  bodyBorderOverlay:SetAllPoints(UI.BODY)
  bodyBorderOverlay:SetFrameStrata(UI.BODY:GetFrameStrata())
  bodyBorderOverlay:SetFrameLevel((UI.BODY:GetFrameLevel() or 1) + 40)
  bodyBorderOverlay:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
  })
  bodyBorderOverlay:SetBackdropBorderColor(THEME.panelBorder.r, THEME.panelBorder.g, THEME.panelBorder.b, THEME.panelBorder.a)
  if bodyBorderOverlay.SetBackdropColor then
    bodyBorderOverlay:SetBackdropColor(0, 0, 0, 0)
  end
  bodyBorderOverlay:EnableMouse(false)
  UI.bodyBorderOverlay = bodyBorderOverlay

  -- Bandeau principal
  UI.header = StdUi:Panel(UI.BODY, 10, 88)
  StdUi:GlueTop(UI.header, UI.BODY, 0, -5, "TOP")
  StdUi:GlueLeft(UI.header, UI.BODY, 5, 0)
  StdUi:GlueRight(UI.header, UI.BODY, -5, 0)
  if UI.header and UI.header.SetBackdrop then
    UI.header:SetBackdrop(nil)
  end
  if UI.header and UI.header.SetBackdropColor then
    UI.header:SetBackdropColor(0, 0, 0, 0)
  end
  if UI.header and UI.header.SetBackdropBorderColor then
    UI.header:SetBackdropBorderColor(0, 0, 0, 0)
  end

  UI.raidToggle = StdUi:Checkbox(UI.header, L_get("ui_toggle_raid"))
  UI.raidToggle:SetPoint("TOPLEFT", UI.header, "TOPLEFT", 5, -2)
  apply_checkbox_theme(UI.raidToggle)
  UI.raidToggle:SetChecked(STATE.raid_announce and true or false)
  UI.raidToggle.OnValueChanged = function(self, checked)
    STATE.raid_announce = checked and true or false
    _G.EASY_SANALUNE_SAVED_STATE = STATE
  end

  UI.randReaderToggle = StdUi:Checkbox(UI.header, L_get("ui_toggle_rand_reader"))
  UI.randReaderToggle:SetPoint("TOPLEFT", UI.raidToggle, "BOTTOMLEFT", 0, -1)
  apply_checkbox_theme(UI.randReaderToggle)
  UI.randReaderToggle:SetChecked(STATE.rand_result_reader and true or false)
  UI.randReaderToggle.OnValueChanged = function(self, checked)
    STATE.rand_result_reader = checked and true or false
    _G.EASY_SANALUNE_SAVED_STATE = STATE
  end

  local function parse_crit_threshold(text)
    local raw = tostring(text or "")
    raw = string.gsub(raw, "^%s+", "")
    raw = string.gsub(raw, "%s+$", "")
    if raw == "" then
      return nil, true
    end

    local value = tonumber(raw)
    if value and value >= 0 and math.floor(value) == value then
      return value, true
    end

    return nil, false
  end

  local function parse_hit_points_value(text)
    local raw = tostring(text or "")
    raw = string.gsub(raw, "^%s+", "")
    raw = string.gsub(raw, "%s+$", "")
    if raw == "" then
      return nil, true
    end

    local value = tonumber(raw)
    if value and math.floor(value) == value then
      if value < MIN_HIT_POINTS then
        value = MIN_HIT_POINTS
      end
      return value, true
    end

    return nil, false
  end

  local function ensure_profile_survival_tables()
    if not STATE.profile_hit_points then STATE.profile_hit_points = {} end
    if not STATE.profile_armor_type then STATE.profile_armor_type = {} end
    if not STATE.profile_durability_current then STATE.profile_durability_current = {} end
    if not STATE.profile_durability_max then STATE.profile_durability_max = {} end
    if not STATE.profile_durability_infinite then STATE.profile_durability_infinite = {} end
    if not STATE.profile_rda then STATE.profile_rda = {} end
    if not STATE.profile_rda_crit then STATE.profile_rda_crit = {} end
  end

  local function persist_survival_profile_state(index)
    ensure_profile_survival_tables()
    local targetIndex = index or STATE.profile_index or 1
    normalize_survival_data(STATE)
    STATE.profile_hit_points[targetIndex] = STATE.hit_points
    STATE.profile_armor_type[targetIndex] = STATE.armor_type
    STATE.profile_durability_current[targetIndex] = STATE.durability_current
    STATE.profile_durability_max[targetIndex] = STATE.durability_max
    STATE.profile_durability_infinite[targetIndex] = STATE.durability_infinite and true or false
    STATE.profile_rda[targetIndex] = STATE.rda
    STATE.profile_rda_crit[targetIndex] = STATE.rda_crit
    _G.EASY_SANALUNE_SAVED_STATE = STATE
    if UI and UI.SendPlayerSurvivalSync then
      UI.SendPlayerSurvivalSync()
    end
  end

  local textFieldsModal = nil
  local textFieldsModalOnConfirm = nil

  local function close_text_fields_modal()
    if textFieldsModal then
      textFieldsModal:Hide()
    end
    INTERNALS.register_menu_close("textFieldsModal")
    textFieldsModalOnConfirm = nil
  end

  local function update_text_field_select_row(row)
    if not row or not row.selectButton then
      return
    end

    local options = row.options or {}
    if #options == 0 then
      row.optionIndex = 1
      row.selectedValue = nil
      row.selectButton:SetText("")
      return
    end

    local index = tonumber(row.optionIndex) or 1
    if index < 1 or index > #options then
      index = 1
    end
    row.optionIndex = index

    local option = options[index]
    row.selectedValue = option.value
    row.selectButton:SetText(tostring(option.label or option.value or ""))
  end

  local function collect_text_fields_modal_values()
    local values = {}
    if not textFieldsModal or not textFieldsModal.rows then
      return values
    end

    for i = 1, #textFieldsModal.rows do
      local row = textFieldsModal.rows[i]
      if row and row:IsShown() and row.key then
        if row.inputType == "select" then
          values[row.key] = row.selectedValue
        else
          values[row.key] = tostring(row.edit:GetText() or "")
        end
      end
    end

    return values
  end

  local function set_text_fields_modal_value(key, value)
    if not textFieldsModal or not textFieldsModal.rows or not key then
      return
    end

    for i = 1, #textFieldsModal.rows do
      local row = textFieldsModal.rows[i]
      if row and row.key == key then
        if row.inputType == "select" then
          local targetValue = tostring(value or "")
          for optionIndex = 1, #(row.options or {}) do
            if tostring(row.options[optionIndex].value) == targetValue then
              row.optionIndex = optionIndex
              update_text_field_select_row(row)
              return
            end
          end
        elseif row.edit then
          row.edit:SetText(tostring(value or ""))
          return
        end
      end
    end
  end

  local function set_text_fields_modal_field_enabled(key, enabled)
    if not textFieldsModal or not textFieldsModal.rows or not key then
      return
    end

    for i = 1, #textFieldsModal.rows do
      local row = textFieldsModal.rows[i]
      if row and row.key == key and row.edit then
        local shouldEnable = enabled and true or false
        if shouldEnable then
          if row.edit.Enable then
            pcall(function() row.edit:Enable() end)
          elseif row.edit.SetEnabled then
            pcall(function() row.edit:SetEnabled(true) end)
          end
          if row.edit.EnableMouse then
            row.edit:EnableMouse(true)
          end
          if row.edit.SetTextColor then
            row.edit:SetTextColor(1, 1, 1)
          end
          row.edit:SetAlpha(1)
        else
          if row.edit.Disable then
            pcall(function() row.edit:Disable() end)
          elseif row.edit.SetEnabled then
            pcall(function() row.edit:SetEnabled(false) end)
          end
          if row.edit.EnableMouse then
            row.edit:EnableMouse(false)
          end
          if row.edit.ClearFocus and row.edit:HasFocus() then
            row.edit:ClearFocus()
          end
          if row.edit.SetTextColor then
            row.edit:SetTextColor(0.68, 0.68, 0.68)
          end
          row.edit:SetAlpha(0.85)
        end
        return
      end
    end
  end

  local function run_text_fields_modal_live_change(changedKey)
    if not textFieldsModal or type(textFieldsModal.onLiveChange) ~= "function" then
      return
    end

    textFieldsModal.onLiveChange(
      collect_text_fields_modal_values(),
      set_text_fields_modal_value,
      set_text_fields_modal_field_enabled,
      changedKey
    )
  end

  local function open_text_fields_modal(config)
    if not config or type(config) ~= "table" then
      return
    end

    if not textFieldsModal then
      textFieldsModal = create_themed_draggable_modal(
        "EasySanaluneTextFieldsModal",
        UI_LAYOUT.textFieldsModal.width,
        UI_LAYOUT.textFieldsModal.initialHeight,
        UI_LAYOUT.textFieldsModal.frameLevel,
        "text_fields_modal",
        false
      )

      textFieldsModal.titleFs = textFieldsModal:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
      textFieldsModal.titleFs:SetPoint("TOP", textFieldsModal, "TOP", 0, UI_LAYOUT.textFieldsModal.titleTop)
      style_font_string(textFieldsModal.titleFs, true)
      textFieldsModal.rows = {}

      textFieldsModal.btnOk = StdUi:Button(textFieldsModal, UI_LAYOUT.textFieldsModal.okWidth, UI_LAYOUT.textFieldsModal.okHeight, L_get("common_confirm"))
      textFieldsModal.btnOk:SetPoint("BOTTOMRIGHT", textFieldsModal, "BOTTOMRIGHT", UI_LAYOUT.textFieldsModal.okRight, UI_LAYOUT.textFieldsModal.okBottom)
      apply_button_theme(textFieldsModal.btnOk, true)

      textFieldsModal.btnCancel = StdUi:Button(textFieldsModal, UI_LAYOUT.textFieldsModal.cancelWidth, UI_LAYOUT.textFieldsModal.cancelHeight, L_get("common_cancel"))
      textFieldsModal.btnCancel:SetPoint("RIGHT", textFieldsModal.btnOk, "LEFT", -UI_LAYOUT.header.gap - 2, 0)
      apply_button_theme(textFieldsModal.btnCancel)

      textFieldsModal.btnCancel:SetScript("OnClick", close_text_fields_modal)
      textFieldsModal.btnOk:SetScript("OnClick", function()
        local values = {}
        for i = 1, #textFieldsModal.rows do
          local row = textFieldsModal.rows[i]
          if row and row:IsShown() and row.key then
            if row.inputType == "select" then
              values[row.key] = row.selectedValue
            else
              values[row.key] = tostring(row.edit:GetText() or "")
            end
          end
        end

        if textFieldsModalOnConfirm then
          local ok = textFieldsModalOnConfirm(values)
          if ok == false then
            return
          end
        end

        close_text_fields_modal()
      end)
    end

    local fields = config.fields or {}
    textFieldsModal.titleFs:SetText(config.title or "")
    textFieldsModalOnConfirm = config.onConfirm
    textFieldsModal.onLiveChange = config.onLiveChange

    for i = 1, #fields do
      local row = textFieldsModal.rows[i]
      if not row then
        row = CreateFrame("Frame", nil, textFieldsModal)
        row:SetSize(UI_LAYOUT.textFieldsModal.rowWidth, UI_LAYOUT.textFieldsModal.rowHeight)
        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
        style_font_string(row.label)
        row.edit = StdUi:SimpleEditBox(row, UI_LAYOUT.textFieldsModal.rowEditWidth, UI_LAYOUT.textFieldsModal.rowEditHeight, "")
        row.edit:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        apply_editbox_theme(row.edit)
        row.selectButton = StdUi:Button(row, UI_LAYOUT.textFieldsModal.rowEditWidth, UI_LAYOUT.textFieldsModal.rowEditHeight, "")
        row.selectButton:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        apply_button_theme(row.selectButton)
        row.selectButton:SetScript("OnClick", function(self, button)
          local parentRow = self:GetParent()
          if not parentRow then
            return
          end

          local options = parentRow.options or {}
          if #options == 0 then
            return
          end

          local direction = (button == "RightButton") and -1 or 1
          local nextIndex = (tonumber(parentRow.optionIndex) or 1) + direction
          if nextIndex > #options then
            nextIndex = 1
          elseif nextIndex < 1 then
            nextIndex = #options
          end
          parentRow.optionIndex = nextIndex
          update_text_field_select_row(parentRow)
          run_text_fields_modal_live_change(parentRow.key)
        end)
        textFieldsModal.rows[i] = row
      end

      local field = fields[i]
      row.key = field.key
      row.inputType = field.inputType == "select" and "select" or "text"
      row.label:SetText(field.label or "")
      row:ClearAllPoints()
      if i == 1 then
        row:SetPoint("TOP", textFieldsModal.titleFs, "BOTTOM", 0, UI_LAYOUT.textFieldsModal.firstRowTop)
      else
        row:SetPoint("TOP", textFieldsModal.rows[i - 1], "BOTTOM", 0, UI_LAYOUT.textFieldsModal.rowSpacing)
      end

      if row.inputType == "select" then
        row.options = {}
        local options = field.options or {}
        for optionIndex = 1, #options do
          local option = options[optionIndex]
          row.options[#row.options + 1] = {
            value = option.value,
            label = option.label or (option.labelKey and L_get(option.labelKey)) or tostring(option.value or ""),
          }
        end

        row.optionIndex = 1
        for optionIndex = 1, #row.options do
          if tostring(row.options[optionIndex].value) == tostring(field.value) then
            row.optionIndex = optionIndex
            break
          end
        end

        update_text_field_select_row(row)
        row.edit:Hide()
        row.selectButton:Show()
      else
        row.options = nil
        row.optionIndex = nil
        row.selectedValue = nil
        row.edit:SetText(tostring(field.value or ""))
        row.edit:Show()
        row.selectButton:Hide()
      end

      row:Show()
    end

    for i = #fields + 1, #textFieldsModal.rows do
      local row = textFieldsModal.rows[i]
      if row then
        row:Hide()
      end
    end

    local desiredHeight = UI_LAYOUT.textFieldsModal.baseHeight + (#fields * UI_LAYOUT.textFieldsModal.perRowHeight)
    textFieldsModal:SetHeight(math.max(UI_LAYOUT.textFieldsModal.minHeight, desiredHeight))
    apply_modal_position(textFieldsModal, "text_fields_modal")
    textFieldsModal:Show()
    INTERNALS.register_menu_open("textFieldsModal")
    run_text_fields_modal_live_change(nil)

    for i = 1, #textFieldsModal.rows do
      local row = textFieldsModal.rows[i]
      if row and row:IsShown() and row.inputType ~= "select" and row.edit then
        row.edit:SetFocus()
        break
      end
    end
  end

  UI.OpenTextFieldsModal = open_text_fields_modal

  UI.OpenCritThresholdModal = function()
    local survivalSnapshot = get_survival_snapshot(STATE)
    open_text_fields_modal({
      title = "Fiche de personnage",
      fields = {
        {
          key = "hit_points",
          label = L_get("ui_label_hit_points"),
          value = tostring(tonumber(survivalSnapshot.hit_points) or DEFAULT_HIT_POINTS),
        },
        {
          key = "armor_type",
          label = L_get("ui_label_armor_type"),
          inputType = "select",
          value = normalize_armor_type(survivalSnapshot.armor_type),
          options = ARMOR_TYPE_OPTIONS,
        },
        {
          key = "durability",
          label = L_get("ui_label_durability"),
          value = format_durability_text(survivalSnapshot),
        },
        {
          key = "rda",
          label = L_get("ui_label_rda"),
          value = tostring(tonumber(survivalSnapshot.rda) or 0),
        },
        {
          key = "rda_crit",
          label = L_get("ui_label_rda_crit"),
          value = tostring(tonumber(survivalSnapshot.rda_crit) or 0),
        },
        {
          key = "crit_off_success",
          label = L_get("ui_label_crit_off_success"),
          value = tostring(STATE.crit_off_success ~= nil and STATE.crit_off_success or DEFAULT_CRIT_THRESHOLD),
        },
        {
          key = "crit_def_success",
          label = L_get("ui_label_crit_def_success"),
          value = tostring(STATE.crit_def_success ~= nil and STATE.crit_def_success or DEFAULT_CRIT_THRESHOLD),
        },
        {
          key = "crit_off_failure_visual",
          label = L_get("ui_label_crit_off_failure_visual"),
          value = tostring(STATE.crit_off_failure_visual ~= nil and STATE.crit_off_failure_visual or 0),
        },
        {
          key = "crit_def_failure_visual",
          label = L_get("ui_label_crit_def_failure_visual"),
          value = tostring(STATE.crit_def_failure_visual ~= nil and STATE.crit_def_failure_visual or 0),
        },
        {
          key = "dodge_back_percent",
          label = L_get("ui_label_dodge_back_percent"),
          value = tostring(clamp_percent(STATE.dodge_back_percent, DEFAULT_DODGE_BACK_PERCENT)),
        },
      },
      onLiveChange = function(values, applyValue, setFieldEnabled, changedKey)
        if changedKey ~= nil and changedKey ~= "armor_type" then
          return
        end

        local armorType = normalize_armor_type(values.armor_type)
        local isSpecialArmor = armorType == "special"
        setFieldEnabled("durability", isSpecialArmor)
        setFieldEnabled("rda", isSpecialArmor)
        setFieldEnabled("rda_crit", isSpecialArmor)

        local hitPointsValue, _ = parse_hit_points_value(values.hit_points)
        local durabilityCurrent = nil
        local durabilityMax = nil
        local durabilityInfinite = false
        local rdaValue = 0
        local rdaCritValue = 0

        if isSpecialArmor then
          local okDurability = false
          durabilityCurrent, durabilityMax, durabilityInfinite, okDurability = parse_durability_input(
            values.durability,
            survivalSnapshot.durability_current,
            survivalSnapshot.durability_max,
            survivalSnapshot.durability_infinite
          )
          if not okDurability then
            durabilityCurrent = survivalSnapshot.durability_current
            durabilityMax = survivalSnapshot.durability_max
            durabilityInfinite = survivalSnapshot.durability_infinite
          end

          local okRda = false
          rdaValue, okRda = parse_crit_threshold(values.rda)
          if not okRda then
            rdaValue = tonumber(survivalSnapshot.rda) or 0
          end

          local okRdaCrit = false
          rdaCritValue, okRdaCrit = parse_crit_threshold(values.rda_crit)
          if not okRdaCrit then
            rdaCritValue = tonumber(survivalSnapshot.rda_crit) or 0
          end
        end

        local preview = get_survival_snapshot({
          hit_points = hitPointsValue ~= nil and hitPointsValue or DEFAULT_HIT_POINTS,
          armor_type = armorType,
          durability_current = durabilityCurrent,
          durability_max = durabilityMax,
          durability_infinite = durabilityInfinite and true or false,
          rda = rdaValue ~= nil and rdaValue or 0,
          rda_crit = rdaCritValue ~= nil and rdaCritValue or 0,
        })

        applyValue("durability", format_durability_text(preview))
        applyValue("rda", tostring(tonumber(preview.rda) or 0))
        applyValue("rda_crit", tostring(tonumber(preview.rda_crit) or 0))
      end,
      onConfirm = function(values)
        local offValue, okOff = parse_crit_threshold(values.crit_off_success)
        if not okOff then
          L_print("crit_threshold_invalid", L_get("ui_label_crit_off_success"))
          return false
        end

        local defValue, okDef = parse_crit_threshold(values.crit_def_success)
        if not okDef then
          L_print("crit_threshold_invalid", L_get("ui_label_crit_def_success"))
          return false
        end

        local offFailureValue, okOffFailure = parse_crit_threshold(values.crit_off_failure_visual)
        if not okOffFailure then
          L_print("crit_threshold_invalid", L_get("ui_label_crit_off_failure_visual"))
          return false
        end

        local defFailureValue, okDefFailure = parse_crit_threshold(values.crit_def_failure_visual)
        if not okDefFailure then
          L_print("crit_threshold_invalid", L_get("ui_label_crit_def_failure_visual"))
          return false
        end

        local dodgeBackPercent = clamp_percent(values.dodge_back_percent, nil)
        if dodgeBackPercent == nil then
          L_print("crit_threshold_invalid", L_get("ui_label_dodge_back_percent"))
          return false
        end

        local hitPointsValue, okHitPoints = parse_hit_points_value(values.hit_points)
        if not okHitPoints then
          L_print("hit_points_invalid", L_get("ui_label_hit_points"))
          return false
        end

        local armorTypeApplied = normalize_armor_type(values.armor_type)
        local isSpecialArmor = armorTypeApplied == "special"

        local durabilityCurrent = nil
        local durabilityMax = nil
        local durabilityInfinite = false
        if isSpecialArmor then
          local okDurability = false
          durabilityCurrent, durabilityMax, durabilityInfinite, okDurability = parse_durability_input(
            values.durability,
            survivalSnapshot.durability_current,
            survivalSnapshot.durability_max,
            survivalSnapshot.durability_infinite
          )
          if not okDurability then
            L_print("durability_invalid", L_get("ui_label_durability"))
            return false
          end
        end

        local rdaValue = 0
        local okRda = true
        if isSpecialArmor then
          rdaValue, okRda = parse_crit_threshold(values.rda)
          if not okRda then
            L_print("crit_threshold_invalid", L_get("ui_label_rda"))
            return false
          end
        end

        local rdaCritValue = 0
        local okRdaCrit = true
        if isSpecialArmor then
          rdaCritValue, okRdaCrit = parse_crit_threshold(values.rda_crit)
          if not okRdaCrit then
            L_print("crit_threshold_invalid", L_get("ui_label_rda_crit"))
            return false
          end
        end

        local offApplied = offValue ~= nil and offValue or DEFAULT_CRIT_THRESHOLD
        local defApplied = defValue ~= nil and defValue or DEFAULT_CRIT_THRESHOLD
        local offFailureApplied = offFailureValue ~= nil and offFailureValue or 0
        local defFailureApplied = defFailureValue ~= nil and defFailureValue or 0
        local hitPointsApplied = hitPointsValue ~= nil and hitPointsValue or DEFAULT_HIT_POINTS

        STATE.crit_off_success = offApplied
        STATE.crit_def_success = defApplied
        STATE.crit_off_failure_visual = offFailureApplied
        STATE.crit_def_failure_visual = defFailureApplied
        STATE.dodge_back_percent = dodgeBackPercent
        STATE.hit_points = hitPointsApplied
        STATE.armor_type = armorTypeApplied
        if isSpecialArmor then
          STATE.durability_current = durabilityCurrent
          STATE.durability_max = durabilityMax or DEFAULT_DURABILITY_MAX
          STATE.durability_infinite = durabilityInfinite and true or false
          STATE.rda = rdaValue ~= nil and rdaValue or (tonumber(survivalSnapshot.rda) or 0)
          STATE.rda_crit = rdaCritValue ~= nil and rdaCritValue or (tonumber(survivalSnapshot.rda_crit) or 0)
        else
          STATE.durability_current = nil
          STATE.durability_max = nil
          STATE.durability_infinite = false
          STATE.rda = 0
          STATE.rda_crit = 0
        end

        if not STATE.profile_crit_off_success then
          STATE.profile_crit_off_success = {}
        end
        if not STATE.profile_crit_def_success then
          STATE.profile_crit_def_success = {}
        end
        if not STATE.profile_crit_off_failure_visual then
          STATE.profile_crit_off_failure_visual = {}
        end
        if not STATE.profile_crit_def_failure_visual then
          STATE.profile_crit_def_failure_visual = {}
        end
        if not STATE.profile_dodge_back_percent then
          STATE.profile_dodge_back_percent = {}
        end

        STATE.profile_crit_off_success[STATE.profile_index] = offApplied
        STATE.profile_crit_def_success[STATE.profile_index] = defApplied
        STATE.profile_crit_off_failure_visual[STATE.profile_index] = offFailureApplied
        STATE.profile_crit_def_failure_visual[STATE.profile_index] = defFailureApplied
        STATE.profile_dodge_back_percent[STATE.profile_index] = dodgeBackPercent
        persist_survival_profile_state(STATE.profile_index)
        return true
      end,
    })
  end

  UI.resetButton = create_header_button(UI.header, UI_LAYOUT.header.resetWidth, L_get("ui_reset"))
  UI.resetButton:SetPoint("TOPRIGHT", UI.header, "TOPRIGHT", UI_LAYOUT.header.topRightX, UI_LAYOUT.header.topRightY)

  UI.infoButton = create_header_button(UI.header, UI_LAYOUT.header.infoWidth, L_get("ui_info_button"))
  UI.infoButton:SetPoint("TOPRIGHT", UI.resetButton, "BOTTOMRIGHT", 0, UI_LAYOUT.header.infoUnderResetY)

  UI.buffsButton = create_header_button(UI.header, UI_LAYOUT.header.buffsWidth, L_get("ui_buffs_button"))
  UI.buffsButton:SetPoint("RIGHT", UI.resetButton, "LEFT", -UI_LAYOUT.header.gap, 0)
  UI.buffsButton:SetScript("OnClick", function()
    if UI.Buffs and UI.Buffs.Toggle then
      UI.Buffs.Toggle()
    end
  end)

  -- Bouton Fenetre MJ (visible uniquement si le mode MJ est actif)
  UI.mjPanelButton = create_header_button(UI.header, UI_LAYOUT.header.mjWidth, L_get("ui_mj_window_button"), true)
  UI.mjPanelButton:SetPoint("RIGHT", UI.buffsButton, "LEFT", -UI_LAYOUT.header.gap, 0)
  UI.mjPanelButton:SetScript("OnClick", function()
    if UI.ToggleMJFrame then
      UI.ToggleMJFrame()
    end
  end)
  if not STATE.mj_enabled then
    UI.mjPanelButton:Hide()
  end

  UI.critThresholdButton = create_header_button(UI.header, UI_LAYOUT.header.ficheWidth, "Fiche")
  UI.critThresholdButton:SetScript("OnClick", function()
    if UI.OpenCritThresholdModal then
      UI.OpenCritThresholdModal()
    end
  end)

  -- Position de depart du bouton Fiche selon l'etat MJ
  local function update_fiche_btn_anchor()
    if not UI.critThresholdButton then return end
    UI.critThresholdButton:ClearAllPoints()
    if STATE.mj_enabled then
      UI.critThresholdButton:SetPoint("RIGHT", UI.mjPanelButton, "LEFT", -UI_LAYOUT.header.gap, 0)
    else
      UI.critThresholdButton:SetPoint("RIGHT", UI.buffsButton, "LEFT", -UI_LAYOUT.header.gap, 0)
    end
  end
  update_fiche_btn_anchor()

  -- Case a cocher du mode MJ
  UI.mjToggle = StdUi:Checkbox(UI.header, L_get("ui_mj"))
  UI.mjToggle:SetPoint("TOPLEFT", UI.randReaderToggle, "BOTTOMLEFT", 0, -1)
  apply_checkbox_theme(UI.mjToggle)
  UI.mjToggle:SetChecked(STATE.mj_enabled and true or false)
  UI.mjToggle.OnValueChanged = function(self, checked)
    STATE.mj_enabled = checked and true or false
    _G.EASY_SANALUNE_SAVED_STATE = STATE
    if UI.mjPanelButton then
      if STATE.mj_enabled then
        UI.mjPanelButton:Show()
      else
        UI.mjPanelButton:Hide()
      end
    end
    -- Repositionne le bouton Fiche selon la visibilite du bouton Fenetre MJ.
    if update_fiche_btn_anchor then
      update_fiche_btn_anchor()
    end
    -- Garantit une largeur suffisante si la configuration active exige plus d'espace.
    if UI.MAIN_FRAME and STATE.shown then
      local minWidth, minHeight = get_min_frame_size()
      if UI.MAIN_FRAME.SetMinResize then
        UI.MAIN_FRAME:SetMinResize(minWidth, minHeight)
      end
      local curWidth = UI.MAIN_FRAME:GetWidth()
      if curWidth < minWidth then
        UI.MAIN_FRAME:SetWidth(minWidth)
        apply_main_frame_position()
        refresh_main_frame_texture()
        STATE.dim_show_w = UI.MAIN_FRAME:GetWidth()
        _G.EASY_SANALUNE_SAVED_STATE = STATE
      end
    end
    UI.SendMJAnnounce(STATE.mj_enabled)
  end

  UI.resolutionPrivateToggle = StdUi:Checkbox(UI.header, L_get("ui_resolution_private"))
  UI.resolutionPrivateToggle:SetPoint("TOPLEFT", UI.mjToggle, "BOTTOMLEFT", 0, -1)
  apply_checkbox_theme(UI.resolutionPrivateToggle)
  UI.resolutionPrivateToggle:SetChecked((STATE and STATE.resolution_private_print) and true or false)
  UI.resolutionPrivateToggle.OnValueChanged = function(self, checked)
    STATE.resolution_private_print = checked and true or false
    _G.EASY_SANALUNE_SAVED_STATE = STATE
  end

  UI.profileBar = StdUi:Panel(UI.BODY, 10, UI_LAYOUT.profile.barHeight)
  -- Place la barre de profil dans l'espace libre du header pour garder une lecture compacte.
  StdUi:GlueBelow(UI.profileBar, UI.header, 0, UI_LAYOUT.profile.barTopOffset)
  StdUi:GlueLeft(UI.profileBar, UI.BODY, UI_LAYOUT.profile.barSideInset, 0)
  StdUi:GlueRight(UI.profileBar, UI.BODY, -UI_LAYOUT.profile.barSideInset, 0)
  -- Barre de profil epuree: sans contour, avec menu de selection et bouton d'action.
  UI.profileBar:SetBackdrop(nil)

  -- Declarations anticipees utilisees par les callbacks du menu et du bouton.
  local switch_profile
  local OpenProfileNameModal

  local profileDropdown = nil
  local profileDropdownOpen = false
  local profileActionMenu = nil
  local profileActionMenuOpen = false
  local profileMenuClickGuard = nil
  local CloseProfileActionMenu

  local function ensure_profile_menu_click_guard()
    if profileMenuClickGuard then
      return
    end

    profileMenuClickGuard = CreateFrame("Frame", nil, UIParent)
    profileMenuClickGuard:SetAllPoints(UIParent)
    profileMenuClickGuard:SetFrameStrata("TOOLTIP")
    profileMenuClickGuard:SetFrameLevel(499)
    profileMenuClickGuard:EnableMouse(true)
    profileMenuClickGuard:Hide()
  end

  -- Bouton d'actions profil (+)
  UI.profileActionBtn = CreateFrame("Button", nil, UI.profileBar, "BackdropTemplate")
  UI.profileActionBtn:SetSize(UI_LAYOUT.profile.actionBtnWidth, UI_LAYOUT.profile.actionBtnHeight)
  UI.profileActionBtn:SetPoint("RIGHT", UI.profileBar, "RIGHT", UI_LAYOUT.profile.actionBtnRight, UI_LAYOUT.profile.actionBtnTop)
  apply_profile_surface(UI.profileActionBtn)
  local actionBtnFs = UI.profileActionBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  actionBtnFs:SetPoint("CENTER", UI.profileActionBtn, "CENTER", 0, 0)
  actionBtnFs:SetText("+")
  actionBtnFs:SetTextColor(0.95, 0.95, 0.95)

  -- Bouton de selection de profil, visuellement aligne avec le style MJ.
  UI.profileDropBtn = CreateFrame("Button", nil, UI.profileBar, "BackdropTemplate")
  UI.profileDropBtn:SetSize(UI_LAYOUT.profile.dropBtnWidth, UI_LAYOUT.profile.dropBtnHeight)
  UI.profileDropBtn:SetPoint("RIGHT", UI.profileActionBtn, "LEFT", -UI_LAYOUT.profile.dropBtnGap, 0)
  apply_profile_surface(UI.profileDropBtn)
  UI.profileDropBtnNameFs = UI.profileDropBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  UI.profileDropBtnNameFs:SetPoint("LEFT", UI.profileDropBtn, "LEFT", UI_LAYOUT.profile.dropTextLeft, 0)
  UI.profileDropBtnNameFs:SetPoint("RIGHT", UI.profileDropBtn, "RIGHT", UI_LAYOUT.profile.dropTextRight, 0)
  UI.profileDropBtnNameFs:SetJustifyH("LEFT")
  UI.profileDropBtnNameFs:SetTextColor(0.95, 0.95, 0.95)

  local profileDropArrowFs = UI.profileDropBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  profileDropArrowFs:SetPoint("RIGHT", UI.profileDropBtn, "RIGHT", UI_LAYOUT.profile.dropArrowRight, 0)
  profileDropArrowFs:SetText("v")
  profileDropArrowFs:SetTextColor(0.95, 0.95, 0.95)

  local function CloseProfileDropdown()
    if profileDropdown then profileDropdown:Hide() end
    profileDropdownOpen = false
    if profileMenuClickGuard and not profileActionMenuOpen then
      profileMenuClickGuard:Hide()
    end
    INTERNALS.register_menu_close("profileDropdown")
  end

  local function OpenProfileDropdown()
    ensure_profile_menu_click_guard()

    local guard = profileMenuClickGuard
    if guard then
      guard:SetScript("OnMouseDown", function()
        CloseProfileDropdown()
        if profileActionMenuOpen and CloseProfileActionMenu then
          CloseProfileActionMenu()
        end
      end)
      guard:Show()
    end

    if not profileDropdown then
      profileDropdown = CreateFrame("Frame", "EasySanaluneProfileDrop", UIParent, "BackdropTemplate")
      profileDropdown:SetFrameStrata("TOOLTIP")
      profileDropdown:SetFrameLevel(500)
      profileDropdown:EnableMouse(true)
      profileDropdown:SetClampedToScreen(true)
      apply_profile_surface(profileDropdown)
    end

    if profileDropdown.dropRows then
      for _, row in ipairs(profileDropdown.dropRows) do
        row:Hide()
        row:SetParent(nil)
      end
    end
    profileDropdown.dropRows = {}

    local profiles = STATE.profiles or {}
    local rowH = UI_LAYOUT.profile.popupRowHeight
    local dropW = UI_LAYOUT.profile.popupWidth
    local yOff = UI_LAYOUT.profile.popupTopOffset
    for i, pName in ipairs(profiles) do
      local capturedIdx = i
      local row = CreateFrame("Button", nil, profileDropdown, "BackdropTemplate")
      row:SetSize(dropW - 4, rowH)
      row:SetPoint("TOPLEFT", profileDropdown, "TOPLEFT", UI_LAYOUT.profile.popupRowInset, yOff)
      if row.SetBackdrop then
        row:SetBackdrop(PROFILE_BACKDROP)
      end

      local isActive = (capturedIdx == STATE.profile_index)
      set_profile_surface_colors(row, isActive)

      row:SetScript("OnEnter", function(self)
        if capturedIdx ~= STATE.profile_index then
          set_profile_surface_colors(self, true)
        end
      end)
      row:SetScript("OnLeave", function(self)
        if capturedIdx ~= STATE.profile_index then
          set_profile_surface_colors(self, false)
        end
      end)

      local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      fs:SetPoint("LEFT", row, "LEFT", 6, 0)
      fs:SetText(pName)
      fs:SetTextColor(0.95, 0.95, 0.95)

      row:SetScript("OnClick", function()
        switch_profile(capturedIdx)
        CloseProfileDropdown()
      end)

      profileDropdown.dropRows[#profileDropdown.dropRows + 1] = row
      yOff = yOff - rowH - 2
    end

    local totalH = math.max(26, #profiles * (rowH + 2) + 4)
    profileDropdown:SetSize(dropW, totalH)
    profileDropdown:ClearAllPoints()
    profileDropdown:SetPoint("TOPLEFT", UI.profileDropBtn, "BOTTOMLEFT", 0, UI_LAYOUT.profile.popupAnchorOffsetY)
    profileDropdown:Show()
    profileDropdownOpen = true
    INTERNALS.register_menu_open("profileDropdown")
  end

  CloseProfileActionMenu = function()
    if profileActionMenu then profileActionMenu:Hide() end
    profileActionMenuOpen = false
    if profileMenuClickGuard and not profileDropdownOpen then
      profileMenuClickGuard:Hide()
    end
    INTERNALS.register_menu_close("profileAction")
  end

  local function OpenProfileActionMenu()
    ensure_profile_menu_click_guard()

    local guard = profileMenuClickGuard
    if guard then
      guard:SetScript("OnMouseDown", function()
        CloseProfileActionMenu()
        if profileDropdownOpen then
          CloseProfileDropdown()
        end
      end)
      guard:Show()
    end

    if not profileActionMenu then
      profileActionMenu = CreateFrame("Frame", "EasySanaluneProfileActionMenu", UIParent, "BackdropTemplate")
      profileActionMenu:SetFrameStrata("TOOLTIP")
      profileActionMenu:SetFrameLevel(500)
      profileActionMenu:EnableMouse(true)
      profileActionMenu:SetClampedToScreen(true)
      apply_profile_surface(profileActionMenu)
      profileActionMenu:SetSize(UI_LAYOUT.profile.popupMenuWidth, UI_LAYOUT.profile.popupMenuHeight)

      local actions = {
        { label = L_get("common_new"), callback = function()
          CloseProfileActionMenu()
          OpenProfileNameModal(L_get("ui_profile_modal_new_title"), "", function(name)
            table.insert(STATE.profiles, name)
            if not STATE.profile_buffs then STATE.profile_buffs = {} end
            STATE.profile_buffs[#STATE.profiles] = {}
            if not STATE.profile_crit_off_success then STATE.profile_crit_off_success = {} end
            if not STATE.profile_crit_def_success then STATE.profile_crit_def_success = {} end
            if not STATE.profile_crit_off_failure_visual then STATE.profile_crit_off_failure_visual = {} end
            if not STATE.profile_crit_def_failure_visual then STATE.profile_crit_def_failure_visual = {} end
            if not STATE.profile_dodge_back_percent then STATE.profile_dodge_back_percent = {} end
            ensure_profile_survival_tables()
            STATE.profile_crit_off_success[#STATE.profiles] = DEFAULT_CRIT_THRESHOLD
            STATE.profile_crit_def_success[#STATE.profiles] = DEFAULT_CRIT_THRESHOLD
            STATE.profile_crit_off_failure_visual[#STATE.profiles] = 0
            STATE.profile_crit_def_failure_visual[#STATE.profiles] = 0
            STATE.profile_dodge_back_percent[#STATE.profiles] = DEFAULT_DODGE_BACK_PERCENT
            STATE.profile_hit_points[#STATE.profiles] = DEFAULT_HIT_POINTS
            STATE.profile_armor_type[#STATE.profiles] = DEFAULT_ARMOR_TYPE
            STATE.profile_durability_current[#STATE.profiles] = DEFAULT_DURABILITY_MAX
            STATE.profile_durability_max[#STATE.profiles] = DEFAULT_DURABILITY_MAX
            STATE.profile_durability_infinite[#STATE.profiles] = false
            STATE.profile_rda[#STATE.profiles] = 0
            STATE.profile_rda_crit[#STATE.profiles] = 0
            switch_profile(#STATE.profiles)
          end)
        end },
        { label = L_get("ui_profile_rename"), callback = function()
          CloseProfileActionMenu()
          local profiles = STATE.profiles or {}
          local currentName = profiles[STATE.profile_index] or ""
          OpenProfileNameModal(L_get("ui_profile_modal_rename_title"), currentName, function(name)
            STATE.profiles[STATE.profile_index] = name
            _G.EASY_SANALUNE_SAVED_STATE = STATE
            UI.update_profile_label()
          end)
        end },
        { label = L_get("common_delete"), callback = function()
          CloseProfileActionMenu()
          if STATE.profile_index == 1 then
            L_print("profile_delete_base_forbidden")
            return
          end
          table.remove(STATE.profiles, STATE.profile_index)
          if STATE.profile_chars then table.remove(STATE.profile_chars, STATE.profile_index) end
          if STATE.profile_buffs then table.remove(STATE.profile_buffs, STATE.profile_index) end
          if STATE.profile_crit_off_success then table.remove(STATE.profile_crit_off_success, STATE.profile_index) end
          if STATE.profile_crit_def_success then table.remove(STATE.profile_crit_def_success, STATE.profile_index) end
          if STATE.profile_crit_off_failure_visual then table.remove(STATE.profile_crit_off_failure_visual, STATE.profile_index) end
          if STATE.profile_crit_def_failure_visual then table.remove(STATE.profile_crit_def_failure_visual, STATE.profile_index) end
          if STATE.profile_dodge_back_percent then table.remove(STATE.profile_dodge_back_percent, STATE.profile_index) end
          if STATE.profile_hit_points then table.remove(STATE.profile_hit_points, STATE.profile_index) end
          if STATE.profile_armor_type then table.remove(STATE.profile_armor_type, STATE.profile_index) end
          if STATE.profile_durability_current then table.remove(STATE.profile_durability_current, STATE.profile_index) end
          if STATE.profile_durability_max then table.remove(STATE.profile_durability_max, STATE.profile_index) end
          if STATE.profile_durability_infinite then table.remove(STATE.profile_durability_infinite, STATE.profile_index) end
          if STATE.profile_rda then table.remove(STATE.profile_rda, STATE.profile_index) end
          if STATE.profile_rda_crit then table.remove(STATE.profile_rda_crit, STATE.profile_index) end
          local newIndex = STATE.profile_index
          if newIndex > 1 then newIndex = newIndex - 1 end
          switch_profile(newIndex)
        end },
        { label = L_get("ui_profile_export"), callback = function()
          CloseProfileActionMenu()
          if UI.OpenExportModal then UI.OpenExportModal() end
        end },
        { label = L_get("common_import"), callback = function()
          CloseProfileActionMenu()
          if UI.OpenImportModal then UI.OpenImportModal() end
        end },
      }

      local yOff = UI_LAYOUT.profile.popupTopOffset
      for _, action in ipairs(actions) do
        local btn = CreateFrame("Button", nil, profileActionMenu, "BackdropTemplate")
        btn:SetSize(UI_LAYOUT.profile.popupMenuBtnWidth, UI_LAYOUT.profile.popupRowHeight)
        btn:SetPoint("TOPLEFT", profileActionMenu, "TOPLEFT", UI_LAYOUT.profile.popupRowInset, yOff)
        apply_profile_surface(btn)
        btn:SetScript("OnEnter", function(self)
          set_profile_surface_colors(self, true)
        end)
        btn:SetScript("OnLeave", function(self)
          set_profile_surface_colors(self, false)
        end)
        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("CENTER", btn, "CENTER", 0, 0)
        fs:SetText(action.label)
        fs:SetTextColor(0.95, 0.95, 0.95)
        btn:SetScript("OnClick", action.callback)
        yOff = yOff - UI_LAYOUT.profile.popupMenuStepY
      end
    end

    profileActionMenu:ClearAllPoints()
    profileActionMenu:SetPoint("TOPRIGHT", UI.profileActionBtn, "BOTTOMRIGHT", 0, UI_LAYOUT.profile.popupAnchorOffsetY)
    profileActionMenu:Show()
    profileActionMenuOpen = true
    INTERNALS.register_menu_open("profileAction")
  end

  UI.profileDropBtn:SetScript("OnClick", function()
    if profileDropdownOpen and profileDropdown and profileDropdown:IsShown() then
      CloseProfileDropdown()
    else
      OpenProfileDropdown()
    end
  end)

  UI.profileActionBtn:SetScript("OnClick", function()
    if profileActionMenuOpen and profileActionMenu and profileActionMenu:IsShown() then
      CloseProfileActionMenu()
    else
      OpenProfileActionMenu()
    end
  end)

  UI.profileControls = {
    UI.profileDropBtn,
    UI.profileActionBtn,
  }

  local function clone_chars(list)
    return deep_clone_chars(list)
  end

  local function default_chars()
    if StateLib and StateLib.DEF_STATE and StateLib.DEF_STATE.CHARS then
      return clone_chars(StateLib.DEF_STATE.CHARS)
    end
    return {}
  end

  local function ensure_profile_chars(index)
    if not STATE.profile_chars then
      STATE.profile_chars = {}
    end
    if not STATE.profile_chars[index] then
      STATE.profile_chars[index] = default_chars()
    end
  end

  local function ensure_profile_buffs(index)
    if not STATE.profile_buffs then
      STATE.profile_buffs = {}
    end
    if not STATE.profile_buffs[index] then
      STATE.profile_buffs[index] = {}
    end
  end

  local function ensure_profile_crit(index)
    if not STATE.profile_crit_off_success then
      STATE.profile_crit_off_success = {}
    end
    if not STATE.profile_crit_def_success then
      STATE.profile_crit_def_success = {}
    end
    if not STATE.profile_crit_off_failure_visual then
      STATE.profile_crit_off_failure_visual = {}
    end
    if not STATE.profile_crit_def_failure_visual then
      STATE.profile_crit_def_failure_visual = {}
    end
    if not STATE.profile_dodge_back_percent then
      STATE.profile_dodge_back_percent = {}
    end
    ensure_profile_survival_tables()

    if STATE.profile_crit_off_success[index] == nil then
      STATE.profile_crit_off_success[index] = DEFAULT_CRIT_THRESHOLD
    end
    if STATE.profile_crit_def_success[index] == nil then
      STATE.profile_crit_def_success[index] = DEFAULT_CRIT_THRESHOLD
    end
    if STATE.profile_crit_off_failure_visual[index] == nil then
      STATE.profile_crit_off_failure_visual[index] = 0
    end
    if STATE.profile_crit_def_failure_visual[index] == nil then
      STATE.profile_crit_def_failure_visual[index] = 0
    end
    if STATE.profile_dodge_back_percent[index] == nil then
      STATE.profile_dodge_back_percent[index] = DEFAULT_DODGE_BACK_PERCENT
    end
    if STATE.profile_hit_points[index] == nil then
      STATE.profile_hit_points[index] = DEFAULT_HIT_POINTS
    end
    if STATE.profile_armor_type[index] == nil or tostring(STATE.profile_armor_type[index]) == "" then
      STATE.profile_armor_type[index] = DEFAULT_ARMOR_TYPE
    end
    if STATE.profile_durability_current[index] == nil then
      STATE.profile_durability_current[index] = DEFAULT_DURABILITY_MAX
    end
    if STATE.profile_durability_max[index] == nil then
      STATE.profile_durability_max[index] = DEFAULT_DURABILITY_MAX
    end
    if STATE.profile_durability_infinite[index] == nil then
      STATE.profile_durability_infinite[index] = false
    end
    if STATE.profile_rda[index] == nil then
      STATE.profile_rda[index] = 0
    end
    if STATE.profile_rda_crit[index] == nil then
      STATE.profile_rda_crit[index] = 0
    end
  end

  switch_profile = function(index)
    STATE.profile_index = index
    ensure_profile_chars(index)
    ensure_profile_buffs(index)
    ensure_profile_crit(index)
    STATE.CHARS = STATE.profile_chars[index]
    STATE.buffs = STATE.profile_buffs[index]
    STATE.crit_off_success = STATE.profile_crit_off_success[index]
    STATE.crit_def_success = STATE.profile_crit_def_success[index]
    STATE.crit_off_failure_visual = STATE.profile_crit_off_failure_visual[index]
    STATE.crit_def_failure_visual = STATE.profile_crit_def_failure_visual[index]
    STATE.dodge_back_percent = STATE.profile_dodge_back_percent[index]
    STATE.hit_points = STATE.profile_hit_points[index]
    STATE.armor_type = STATE.profile_armor_type[index]
    STATE.durability_current = STATE.profile_durability_current[index]
    STATE.durability_max = STATE.profile_durability_max[index]
    STATE.durability_infinite = STATE.profile_durability_infinite[index] and true or false
    STATE.rda = STATE.profile_rda[index]
    STATE.rda_crit = STATE.profile_rda_crit[index]
    normalize_survival_data(STATE)
    persist_survival_profile_state(index)
    normalize_chars(STATE.CHARS)
    UI.update_profile_label()
    UI.REFRESH()
  end

  UI.switch_profile = switch_profile

  local function reset_current_profile()
    STATE.CHARS = default_chars()
    normalize_chars(STATE.CHARS)
    if not STATE.profile_chars then
      STATE.profile_chars = {}
    end
    STATE.profile_chars[STATE.profile_index] = STATE.CHARS
    if not STATE.profile_buffs then
      STATE.profile_buffs = {}
    end
    STATE.profile_buffs[STATE.profile_index] = {}
    STATE.buffs = STATE.profile_buffs[STATE.profile_index]
    if not STATE.profile_crit_off_success then
      STATE.profile_crit_off_success = {}
    end
    if not STATE.profile_crit_def_success then
      STATE.profile_crit_def_success = {}
    end
    if not STATE.profile_crit_off_failure_visual then
      STATE.profile_crit_off_failure_visual = {}
    end
    if not STATE.profile_crit_def_failure_visual then
      STATE.profile_crit_def_failure_visual = {}
    end
    if not STATE.profile_dodge_back_percent then
      STATE.profile_dodge_back_percent = {}
    end
    ensure_profile_survival_tables()
    STATE.profile_crit_off_success[STATE.profile_index] = DEFAULT_CRIT_THRESHOLD
    STATE.profile_crit_def_success[STATE.profile_index] = DEFAULT_CRIT_THRESHOLD
    STATE.profile_crit_off_failure_visual[STATE.profile_index] = 0
    STATE.profile_crit_def_failure_visual[STATE.profile_index] = 0
    STATE.profile_dodge_back_percent[STATE.profile_index] = DEFAULT_DODGE_BACK_PERCENT
    STATE.profile_hit_points[STATE.profile_index] = DEFAULT_HIT_POINTS
    STATE.profile_armor_type[STATE.profile_index] = DEFAULT_ARMOR_TYPE
    STATE.profile_durability_current[STATE.profile_index] = DEFAULT_DURABILITY_MAX
    STATE.profile_durability_max[STATE.profile_index] = DEFAULT_DURABILITY_MAX
    STATE.profile_durability_infinite[STATE.profile_index] = false
    STATE.profile_rda[STATE.profile_index] = 0
    STATE.profile_rda_crit[STATE.profile_index] = 0
    STATE.crit_off_success = DEFAULT_CRIT_THRESHOLD
    STATE.crit_def_success = DEFAULT_CRIT_THRESHOLD
    STATE.crit_off_failure_visual = 0
    STATE.crit_def_failure_visual = 0
    STATE.dodge_back_percent = DEFAULT_DODGE_BACK_PERCENT
    STATE.hit_points = DEFAULT_HIT_POINTS
    STATE.armor_type = DEFAULT_ARMOR_TYPE
    STATE.durability_current = DEFAULT_DURABILITY_MAX
    STATE.durability_max = DEFAULT_DURABILITY_MAX
    STATE.durability_infinite = false
    STATE.rda = 0
    STATE.rda_crit = 0
    persist_survival_profile_state(STATE.profile_index)
    UI.REFRESH()
  end

  local function tables_equal(a, b)
    if a == b then
      return true
    end
    if type(a) ~= type(b) then
      return false
    end
    if type(a) ~= "table" then
      return false
    end

    for k, v in pairs(a) do
      if not tables_equal(v, b[k]) then
        return false
      end
    end
    for k in pairs(b) do
      if a[k] == nil then
        return false
      end
    end
    return true
  end

  local function has_current_profile_data_to_reset()
    local index = STATE.profile_index

    local chars = nil
    if type(STATE.profile_chars) == "table" then
      chars = STATE.profile_chars[index]
    end
    if type(chars) ~= "table" then
      chars = STATE.CHARS or {}
    end

    local defaultChars = default_chars()
    local charsChanged = not tables_equal(chars, defaultChars)

    local critOff = STATE.crit_off_success
    if type(STATE.profile_crit_off_success) == "table" and STATE.profile_crit_off_success[index] ~= nil then
      critOff = STATE.profile_crit_off_success[index]
    end
    local critDef = STATE.crit_def_success
    if type(STATE.profile_crit_def_success) == "table" and STATE.profile_crit_def_success[index] ~= nil then
      critDef = STATE.profile_crit_def_success[index]
    end
    local critOffFailure = STATE.crit_off_failure_visual
    if type(STATE.profile_crit_off_failure_visual) == "table" and STATE.profile_crit_off_failure_visual[index] ~= nil then
      critOffFailure = STATE.profile_crit_off_failure_visual[index]
    end
    local critDefFailure = STATE.crit_def_failure_visual
    if type(STATE.profile_crit_def_failure_visual) == "table" and STATE.profile_crit_def_failure_visual[index] ~= nil then
      critDefFailure = STATE.profile_crit_def_failure_visual[index]
    end
    local dodgeBackPercent = STATE.dodge_back_percent
    if type(STATE.profile_dodge_back_percent) == "table" and STATE.profile_dodge_back_percent[index] ~= nil then
      dodgeBackPercent = STATE.profile_dodge_back_percent[index]
    end
    local survivalSnapshot = get_survival_snapshot({
      hit_points = type(STATE.profile_hit_points) == "table" and STATE.profile_hit_points[index] or STATE.hit_points,
      armor_type = type(STATE.profile_armor_type) == "table" and STATE.profile_armor_type[index] or STATE.armor_type,
      durability_current = type(STATE.profile_durability_current) == "table" and STATE.profile_durability_current[index] or STATE.durability_current,
      durability_max = type(STATE.profile_durability_max) == "table" and STATE.profile_durability_max[index] or STATE.durability_max,
      durability_infinite = type(STATE.profile_durability_infinite) == "table" and STATE.profile_durability_infinite[index] or STATE.durability_infinite,
      rda = type(STATE.profile_rda) == "table" and STATE.profile_rda[index] or STATE.rda,
      rda_crit = type(STATE.profile_rda_crit) == "table" and STATE.profile_rda_crit[index] or STATE.rda_crit,
    })

    local ficheChanged = (tonumber(critOff) or DEFAULT_CRIT_THRESHOLD) ~= DEFAULT_CRIT_THRESHOLD
      or (tonumber(critDef) or DEFAULT_CRIT_THRESHOLD) ~= DEFAULT_CRIT_THRESHOLD
      or (tonumber(critOffFailure) or 0) ~= 0
      or (tonumber(critDefFailure) or 0) ~= 0
      or (tonumber(dodgeBackPercent) or DEFAULT_DODGE_BACK_PERCENT) ~= DEFAULT_DODGE_BACK_PERCENT
      or (tonumber(survivalSnapshot.hit_points) or DEFAULT_HIT_POINTS) ~= DEFAULT_HIT_POINTS
      or normalize_armor_type(survivalSnapshot.armor_type) ~= DEFAULT_ARMOR_TYPE
      or (survivalSnapshot.durability_infinite and true or false)
      or (tonumber(survivalSnapshot.durability_current) or DEFAULT_DURABILITY_MAX) ~= DEFAULT_DURABILITY_MAX
      or (tonumber(survivalSnapshot.durability_max) or DEFAULT_DURABILITY_MAX) ~= DEFAULT_DURABILITY_MAX
      or (tonumber(survivalSnapshot.rda) or 0) ~= 0
      or (tonumber(survivalSnapshot.rda_crit) or 0) ~= 0

    return charsChanged or ficheChanged
  end

  local function has_current_profile_buffs()
    local index = STATE.profile_index
    local buffs = nil
    if type(STATE.profile_buffs) == "table" then
      buffs = STATE.profile_buffs[index]
    end
    if type(buffs) ~= "table" then
      buffs = STATE.buffs
    end

    return type(buffs) == "table" and next(buffs) ~= nil
  end

  local function update_main_reset_button_visibility()
    if not UI.resetButton or not UI.infoButton or not UI.buffsButton or not UI.header then
      return
    end

    local showReset = has_current_profile_data_to_reset()
    if showReset then
      UI.resetButton:Show()
    else
      UI.resetButton:Hide()
    end

    UI.infoButton:ClearAllPoints()
    if showReset then
      UI.infoButton:SetPoint("TOPRIGHT", UI.resetButton, "BOTTOMRIGHT", 0, UI_LAYOUT.header.infoUnderResetY)
    else
      UI.infoButton:SetPoint("TOPRIGHT", UI.header, "TOPRIGHT", UI_LAYOUT.header.topRightX, UI_LAYOUT.header.infoWhenNoResetY)
    end

    UI.buffsButton:ClearAllPoints()
    if showReset then
      UI.buffsButton:SetPoint("RIGHT", UI.resetButton, "LEFT", -UI_LAYOUT.header.gap, 0)
    else
      UI.buffsButton:SetPoint("TOPRIGHT", UI.header, "TOPRIGHT", UI_LAYOUT.header.topRightX, UI_LAYOUT.header.topRightY)
    end
  end
  UI.update_reset_button_visibility = update_main_reset_button_visibility

  UI.infoButton:SetScript("OnClick", function()
    if UI.OpenInfosGuide then
      UI.OpenInfosGuide()
    end
  end)

  -- Fenetre de saisie du nom de profil
  local profileNameModal = nil
  local profileNameModalCallback = nil

  OpenProfileNameModal = function(title, defaultText, callback)
    if not profileNameModal then
      profileNameModal = create_themed_draggable_modal(
        "EasySanaluneProfileNameModal",
        280,
        100,
        600,
        "profile_name_modal",
        false
      )

      profileNameModal.titleFs = profileNameModal:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
      profileNameModal.titleFs:SetPoint("TOP", profileNameModal, "TOP", 0, -10)
      style_font_string(profileNameModal.titleFs, true)

      profileNameModal.eb = StdUi:SimpleEditBox(profileNameModal, 240, 22, "")
      profileNameModal.eb:SetPoint("TOP", profileNameModal.titleFs, "BOTTOM", 0, -8)
      apply_editbox_theme(profileNameModal.eb)

      profileNameModal.btnOk = StdUi:Button(profileNameModal, 80, 22, L_get("common_confirm"))
      profileNameModal.btnOk:SetPoint("BOTTOMRIGHT", profileNameModal, "BOTTOMRIGHT", -12, 10)
      apply_button_theme(profileNameModal.btnOk, true)

      profileNameModal.btnCancel = StdUi:Button(profileNameModal, 70, 22, L_get("common_cancel"))
      profileNameModal.btnCancel:SetPoint("RIGHT", profileNameModal.btnOk, "LEFT", -6, 0)
      apply_button_theme(profileNameModal.btnCancel)

      profileNameModal.btnOk:SetScript("OnClick", function()
        local name = tostring(profileNameModal.eb:GetText() or "")
        name = name:match("^%s*(.-)%s*$")
        if name ~= "" and profileNameModalCallback then
          profileNameModalCallback(name)
        end
        profileNameModal:Hide()
        INTERNALS.register_menu_close('profileNameModal')
        profileNameModalCallback = nil
      end)
      profileNameModal.btnCancel:SetScript("OnClick", function()
        profileNameModal:Hide()
        INTERNALS.register_menu_close('profileNameModal')
        profileNameModalCallback = nil
      end)
    end

    profileNameModal.titleFs:SetText(title)
    profileNameModal.eb:SetText(defaultText or "")
    profileNameModal.eb:SetFocus()
    profileNameModalCallback = callback
    apply_modal_position(profileNameModal, "profile_name_modal")
    profileNameModal:Show()
    INTERNALS.register_menu_open('profileNameModal')
  end

  UI.update_profile_label = function()
    local profiles = STATE.profiles or {}
    local name = profiles[STATE.profile_index] or L_get("ui_profile_default_name")
    UI.profileDropBtnNameFs:SetText("Profil: " .. name)
  end

  UI.resetButton:SetScript("OnClick", function()
    if not has_current_profile_data_to_reset() then
      L_print("ui_reset_nothing")
      return
    end

    StaticPopupDialogs["EASYSANALUNE_RESET_PROFILE"] = {
      text = L_get("ui_reset_profile_popup_text"),
      button1 = L_get("ui_reset_profile_popup_confirm"),
      button2 = L_get("common_cancel"),
      OnAccept = function()
        reset_current_profile()
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
    StaticPopup_Show("EASYSANALUNE_RESET_PROFILE")
  end)

  update_main_reset_button_visibility()

  UI.update_profile_label()
  UI.set_profile_mode(STATE.profile_mode)

  -- Zone scrollable principale
  UI.scroll = StdUi:ScrollFrame(UI.BODY, UI_LAYOUT.mainScroll.initialWidth, UI_LAYOUT.mainScroll.initialHeight)
  apply_panel_theme(UI.scroll, false, true)
  if UI.scroll.SetBackdropBorderColor then
    UI.scroll:SetBackdropBorderColor(0, 0, 0, 0)
  end
  if UI.scroll and UI.scroll.scrollBar then
    apply_scrollbar_theme(UI.scroll)
  end
  if UI.scroll and UI.scroll.scrollFrame then
    UI.scroll.scrollFrame.scrollBarHideable = false
  end
  UI.update_scroll_anchor = function()
    if not UI.scroll then
      return
    end

    local topAnchor = UI.header
    if UI.profileBar and UI.profileBar:IsShown() then
      topAnchor = UI.profileBar
    end

    UI.scroll:ClearAllPoints()
    UI.scroll:SetPoint("TOPLEFT", topAnchor, "BOTTOMLEFT", UI_LAYOUT.mainScroll.topInset, UI_LAYOUT.mainScroll.topOffset)
    UI.scroll:SetPoint("TOPRIGHT", topAnchor, "BOTTOMRIGHT", UI_LAYOUT.mainScroll.rightInset, UI_LAYOUT.mainScroll.topOffset)
    UI.scroll:SetPoint("BOTTOMLEFT", UI.BODY, "BOTTOMLEFT", UI_LAYOUT.mainScroll.bottomInset, UI_LAYOUT.mainScroll.bottomOffset)
    UI.scroll:SetPoint("BOTTOMRIGHT", UI.BODY, "BOTTOMRIGHT", UI_LAYOUT.mainScroll.rightInset, UI_LAYOUT.mainScroll.bottomOffset)
  end
  UI.update_scroll_anchor()

  local function update_scroll_guard()
    if not UI.scroll or not UI.scroll.scrollFrame or not UI.scroll.scrollBar then
      return
    end

    local yRange = UI.scroll.scrollFrame:GetVerticalScrollRange() or 0
    local hasRange = yRange > 0.005

    UI.scroll.scrollFrame:EnableMouseWheel(hasRange)
    if not hasRange then
      UI.scroll.scrollBar:SetValue(0)
      UI.scroll.scrollFrame:SetVerticalScroll(0)
    else
      local currentVal = UI.scroll.scrollBar:GetValue()
      if currentVal > yRange then
        UI.scroll.scrollBar:SetValue(yRange)
        UI.scroll.scrollFrame:SetVerticalScroll(yRange)
      end
    end
  end

  if UI.scroll and UI.scroll.scrollFrame and not UI.scroll.scrollFrame.esScrollGuardHooked then
    UI.scroll.scrollFrame.esScrollGuardHooked = true
    UI.scroll.scrollFrame:HookScript("OnScrollRangeChanged", function()
      update_scroll_guard()
    end)
    UI.scroll.scrollFrame:HookScript("OnVerticalScroll", function(_, offset)
      local yRange = UI.scroll.scrollFrame:GetVerticalScrollRange() or 0
      if offset > yRange then
        UI.scroll.scrollFrame:SetVerticalScroll(yRange)
        UI.scroll.scrollBar:SetValue(yRange)
      end
    end)
  end

  update_scroll_guard()

  -- Contenu interne de la zone scrollable
  UI.scrollContent = UI.scroll.scrollChild
  UI.scrollContent:SetScript("OnSizeChanged", function()
    UI.scroll.scrollChild:SetPoint("RIGHT", UI.scroll, "RIGHT")
    if UI.update_add_buttons_layout then
      UI.update_add_buttons_layout()
    end
    update_scroll_guard()
    if not UI.isResizing then
      refresh_main_frame_texture()
    end
  end)
  StdUi:ApplyBackdrop(UI.scrollContent, 'panel')
  apply_panel_theme(UI.scrollContent, false, true)
  if UI.scrollContent.SetBackdropBorderColor then
    UI.scrollContent:SetBackdropBorderColor(0, 0, 0, 0)
  end
  if UI.scrollContent.SetBackdropColor then
    UI.scrollContent:SetBackdropColor(0, 0, 0, 0)
  end
  if UI.scroll and UI.scroll.SetBackdropBorderColor then
    UI.scroll:SetBackdropBorderColor(0, 0, 0, 0)
  end
  if UI.scroll and UI.scroll.scrollFrame and UI.scroll.scrollFrame.SetBackdropBorderColor then
    UI.scroll.scrollFrame:SetBackdropBorderColor(0, 0, 0, 0)
  end

  -- Liste des elements affiches
  local obj_list = {}
  obj_list.N = 0
  UI.section_widgets = {}

  local function set_section_highlight(sectionWidget, enabled)
    if not sectionWidget then
      return
    end
    if enabled then
      sectionWidget:SetAlpha(0.75)
    else
      sectionWidget:SetAlpha(1.0)
    end
  end

  local function find_hover_section_widget(excludedWidget)
    if not UI.section_widgets then
      return nil
    end
    for i = 1, #UI.section_widgets do
      local sectionWidget = UI.section_widgets[i]
      if sectionWidget
          and sectionWidget ~= excludedWidget
          and sectionWidget:IsMouseOver()
          and sectionWidget.infos
          and not sectionWidget.infos.is_fixed then
        return sectionWidget
      end
    end
    return nil
  end

  local function move_section_relative(sectionElem, targetSectionWidget, placeAfter)
    if not sectionElem or not sectionElem.infos or sectionElem.infos.is_fixed then
      return false
    end
    if not targetSectionWidget or not targetSectionWidget.infos or targetSectionWidget.infos.is_fixed then
      return false
    end

    local movingSection = sectionElem.infos
    local targetSection = targetSectionWidget.infos
    local sourceIndex = nil
    local targetIndex = nil

    for i = 1, #STATE.CHARS do
      if STATE.CHARS[i] == movingSection then
        sourceIndex = i
      end
      if STATE.CHARS[i] == targetSection then
        targetIndex = i
      end
    end

    if not sourceIndex or not targetIndex or sourceIndex == targetIndex then
      return false
    end

    table.remove(STATE.CHARS, sourceIndex)

    if sourceIndex < targetIndex then
      targetIndex = targetIndex - 1
    end

    local insertIndex = targetIndex
    if placeAfter then
      insertIndex = targetIndex + 1
    end

    if insertIndex < 2 then
      insertIndex = 2
    end
    if insertIndex > #STATE.CHARS + 1 then
      insertIndex = #STATE.CHARS + 1
    end

    table.insert(STATE.CHARS, insertIndex, movingSection)
    return true
  end

  local function move_rand_to_section(randElem, targetSection)
    if not randElem or not randElem.infos or not targetSection then
      return false
    end
    if targetSection.is_fixed then
      return false
    end
    if randElem.infos.is_default then
      return false
    end

    local randData = randElem.infos

    if randElem.parentSection then
      local sourceItems = randElem.parentSection.items or {}
      for i = 1, #sourceItems do
        if sourceItems[i] == randData then
          table.remove(sourceItems, i)
          break
        end
      end
    else
      for i = 1, #STATE.CHARS do
        if STATE.CHARS[i] == randData then
          table.remove(STATE.CHARS, i)
          break
        end
      end
    end

    if type(targetSection.items) ~= "table" then
      targetSection.items = {}
    end
    randData.type = "rand"
    targetSection.items[#targetSection.items + 1] = randData
    targetSection.expanded = true
    return true
  end

  local function move_rand_to_main_list(randElem)
    if not randElem or not randElem.infos then
      return false
    end
    if randElem.infos.is_default then
      return false
    end
    if not randElem.parentSection then
      return false
    end

    local randData = randElem.infos
    local sourceItems = randElem.parentSection.items or {}
    for i = 1, #sourceItems do
      if sourceItems[i] == randData then
        table.remove(sourceItems, i)
        break
      end
    end

    randData.type = "rand"
    STATE.CHARS[#STATE.CHARS + 1] = randData
    return true
  end

  local function glue_below_with_section_spacing(widget, previousWidget)
    local yOffset = 0
    if (widget and widget.is_section_item) or (previousWidget and previousWidget.is_section_item) then
      yOffset = UI_LAYOUT.mainScroll.sectionItemGapY
    end
    StdUi:GlueBelow(widget, previousWidget, 0, yOffset)
  end

  normalize_chars(STATE.CHARS)
  for i = 1, #STATE.CHARS do
    local char = STATE.CHARS[i]
    local elem = nil

    if char.type == "section" then
      elem = UI.make_section_elem(UI.scrollContent, char)
      UI.section_widgets[#UI.section_widgets + 1] = elem
      StdUi:GlueLeft(elem, UI.scrollContent, 2, 0, 0, 0)
      StdUi:GlueRight(elem, UI.scrollContent, -24, 0, 0, 0)

      obj_list[obj_list.N] = elem
      obj_list.N = obj_list.N + 1

      if obj_list.N == 1 then
        StdUi:GlueTop(elem, UI.scrollContent)
      else
        glue_below_with_section_spacing(elem, obj_list[obj_list.N - 2])
      end

      if char.expanded and char.items then
        for j = 1, #char.items do
          local item = char.items[j]
          if item.type ~= "section" then
            local itemElem = UI.make_scroll_elem(UI.scrollContent, item)
            itemElem.parentSection = char
            itemElem.is_section_item = true

            StdUi:GlueLeft(itemElem, UI.scrollContent, 10, 0, 0, 0)
            StdUi:GlueRight(itemElem, UI.scrollContent, -24, 0, 0, 0)

            obj_list[obj_list.N] = itemElem
            obj_list.N = obj_list.N + 1
            glue_below_with_section_spacing(itemElem, obj_list[obj_list.N - 2])
          end
        end
      end
    else
      elem = UI.make_scroll_elem(UI.scrollContent, char)
      StdUi:GlueLeft(elem, UI.scrollContent, 2, 0, 0, 0)
      StdUi:GlueRight(elem, UI.scrollContent, -24, 0, 0, 0)

      obj_list[obj_list.N] = elem
      obj_list.N = obj_list.N + 1

      if obj_list.N == 1 then
        StdUi:GlueTop(elem, UI.scrollContent)
      else
        glue_below_with_section_spacing(elem, obj_list[obj_list.N - 2])
      end
    end
  end

  local button_add_elem = UI.make_elem_add(UI.scrollContent)
  local button_add_section = UI.make_section_add(UI.scrollContent)
  UI.buttonAddElem = button_add_elem
  UI.buttonAddSection = button_add_section

  UI.update_add_buttons_layout = function()
    if not UI.buttonAddElem or not UI.buttonAddSection or not UI.scrollContent then
      return
    end

    local addButtonsWidth = 190
    UI.buttonAddElem:SetSize(addButtonsWidth, 20)
    UI.buttonAddSection:SetSize(addButtonsWidth, 20)

    local contentWidth = UI.scrollContent:GetWidth() or addButtonsWidth
    local leftOffset = math.floor((contentWidth - addButtonsWidth) / 2)
    if leftOffset < 0 then
      leftOffset = 0
    end

    UI.buttonAddElem:ClearAllPoints()
    if obj_list.N > 0 then
      local anchor = obj_list[obj_list.N - 1]
      if anchor then
        UI.buttonAddElem:SetPoint("TOP", anchor, "BOTTOM", 0, -4)
      else
        UI.buttonAddElem:SetPoint("TOP", UI.scrollContent, "TOP", 0, -4)
      end
    else
      UI.buttonAddElem:SetPoint("TOP", UI.scrollContent, "TOP", 0, -4)
    end
    UI.buttonAddElem:SetPoint("LEFT", UI.scrollContent, "LEFT", leftOffset, 0)

    UI.buttonAddSection:ClearAllPoints()
    UI.buttonAddSection:SetPoint("TOP", UI.buttonAddElem, "BOTTOM", 0, -6)
    UI.buttonAddSection:SetPoint("LEFT", UI.scrollContent, "LEFT", leftOffset, 0)

  end

  -- Recalcule la hauteur du scrollChild d'après le nombre d'éléments
  UI.recalc_scroll_content_height = function()
    if not UI.scrollContent then
      return
    end
    local ROW_H = 24
    local count = obj_list.N or 0
    local contentH = count * ROW_H
    -- boutons "Nouveau rand" + "Nouvelle catégorie" + marges
    contentH = contentH + 4 + 20 + 6 + 20 + 4
    UI.scrollContent:SetHeight(math.max(contentH, 1))
  end

  UI.update_add_buttons_layout()
  UI.recalc_scroll_content_height()

  UI.elem_delete = function(elem)
    if elem.type ~= "section" and elem.infos and elem.infos.is_default then
      L_print("rand_delete_default_forbidden")
      return
    end

    if elem.type == "section" and elem.infos and elem.infos.is_fixed then
      L_print("section_delete_basic_forbidden")
      return
    end

    if elem.type == "section" then
      remove_entry(STATE.CHARS, elem.infos)
    elseif elem.parentSection then
      remove_entry(elem.parentSection.items, elem.infos)
    else
      remove_entry(STATE.CHARS, elem.infos)
    end

    UI.REFRESH()
  end

  UI.elem_move_up = function(elem)
    if elem.type == "section" then
      if elem.infos and elem.infos.is_fixed then
        return
      end
      move_entry(STATE.CHARS, elem.infos, -1)
    elseif elem.parentSection then
      move_entry(elem.parentSection.items, elem.infos, -1)
    else
      move_entry(STATE.CHARS, elem.infos, -1)
    end

    UI.REFRESH()
  end

  UI.elem_move_down = function(elem)
    if elem.type == "section" then
      if elem.infos and elem.infos.is_fixed then
        return
      end
      move_entry(STATE.CHARS, elem.infos, 1)
    elseif elem.parentSection then
      move_entry(elem.parentSection.items, elem.infos, 1)
    else
      move_entry(STATE.CHARS, elem.infos, 1)
    end

    UI.REFRESH()
  end

  UI.start_rand_drag = function(randElem)
    if UI.isResizing then
      return
    end
    if not randElem or not randElem.infos or randElem.infos.is_default then
      return
    end
    UI.draggedRand = randElem
    UI.dragHoverSection = nil
    randElem:SetAlpha(0.6)
    UI.scrollContent:SetScript("OnUpdate", function()
      local hovered = find_hover_section_widget()
      if hovered ~= UI.dragHoverSection then
        if UI.dragHoverSection then
          set_section_highlight(UI.dragHoverSection, false)
        end
        UI.dragHoverSection = hovered
        if UI.dragHoverSection then
          set_section_highlight(UI.dragHoverSection, true)
        end
      end
    end)
  end

  UI.stop_rand_drag = function(randElem)
    if not UI.draggedRand then
      return
    end

    if UI.dragHoverSection then
      set_section_highlight(UI.dragHoverSection, false)
    end

    UI.scrollContent:SetScript("OnUpdate", nil)
    randElem:SetAlpha(1.0)

    local moved = false
    if UI.dragHoverSection and UI.dragHoverSection.infos then
      moved = move_rand_to_section(randElem, UI.dragHoverSection.infos)
    else
      moved = move_rand_to_main_list(randElem)
    end

    UI.draggedRand = nil
    UI.dragHoverSection = nil

    if moved then
      UI.REFRESH()
    end
  end

  UI.start_section_drag = function(sectionElem)
    if UI.isResizing then
      return
    end
    if not sectionElem or not sectionElem.infos or sectionElem.infos.is_fixed then
      return
    end

    UI.draggedSection = sectionElem
    UI.dragHoverTargetSection = nil
    sectionElem:SetAlpha(0.6)

    UI.scrollContent:SetScript("OnUpdate", function()
      local hovered = find_hover_section_widget(sectionElem)
      if hovered ~= UI.dragHoverTargetSection then
        if UI.dragHoverTargetSection then
          set_section_highlight(UI.dragHoverTargetSection, false)
        end
        UI.dragHoverTargetSection = hovered
        if UI.dragHoverTargetSection then
          set_section_highlight(UI.dragHoverTargetSection, true)
        end
      end
    end)
  end

  UI.stop_section_drag = function(sectionElem)
    if not UI.draggedSection then
      return
    end

    if UI.dragHoverTargetSection then
      set_section_highlight(UI.dragHoverTargetSection, false)
    end

    UI.scrollContent:SetScript("OnUpdate", nil)
    sectionElem:SetAlpha(1.0)

    local moved = false
    if UI.dragHoverTargetSection then
      local x, y = GetCursorPosition()
      local scale = UIParent:GetEffectiveScale()
      local cursorY = y / scale
      local _, targetCenterY = UI.dragHoverTargetSection:GetCenter()
      local placeAfter = false
      if targetCenterY and cursorY < targetCenterY then
        placeAfter = true
      end
      moved = move_section_relative(sectionElem, UI.dragHoverTargetSection, placeAfter)
    end

    UI.draggedSection = nil
    UI.dragHoverTargetSection = nil

    if moved then
      UI.REFRESH()
    end
  end

  return UI.BODY
end

INTERNALS.parse_roll_message = parse_roll_message
INTERNALS.build_rand_pattern = build_rand_pattern

-- -----------------------------------------------------------------------------
-- Communication addon (demandes MJ/PJ et messages recus)
-- -----------------------------------------------------------------------------

local ADDON_CHANNEL = (Protocol and Protocol.CHANNEL) or "easysanalune"
local MJ_EXPIRY = 60

local COMBAT_SESSION = nil
if CombatSessionLogic and CombatSessionLogic.new then
  COMBAT_SESSION = CombatSessionLogic.new()
else
  COMBAT_SESSION = {
    knownMJs = {},
    rollBuffer = {},
    pendingMJRequests = {},
    pendingPlayerDefenseRequests = {},
    pendingPlayerResolutions = {},
    pendingResolutions = {},
    syncedMobState = {
      syncId = nil,
      sender = nil,
      activeMobId = nil,
      timestamp = 0,
      expectedCount = 0,
      receivedCount = 0,
      complete = false,
      mobs = {},
    },
    actionHistory = {},
    mjRequestCounter = 0,
    mjAttackRequestCounter = 0,
  }
end

COMBAT_SESSION.syncedMobState = COMBAT_SESSION.syncedMobState or {
  syncId = nil,
  sender = nil,
  activeMobId = nil,
  timestamp = 0,
  expectedCount = 0,
  receivedCount = 0,
  complete = false,
  mobs = {},
}
COMBAT_SESSION.actionHistory = COMBAT_SESSION.actionHistory or {}
COMBAT_SESSION.playerSurvivalStates = COMBAT_SESSION.playerSurvivalStates or {}
COMBAT_SESSION.playerSurvivalSupport = COMBAT_SESSION.playerSurvivalSupport or {}

UI.knownMJs = COMBAT_SESSION.knownMJs
UI.rollBuffer = COMBAT_SESSION.rollBuffer
UI.pendingMJRequests = COMBAT_SESSION.pendingMJRequests
UI.pendingPlayerDefenseRequests = COMBAT_SESSION.pendingPlayerDefenseRequests
UI.pendingPlayerResolutions = COMBAT_SESSION.pendingPlayerResolutions
UI.syncedMobState = COMBAT_SESSION.syncedMobState
UI.actionHistory = COMBAT_SESSION.actionHistory
UI.playerSurvivalStates = COMBAT_SESSION.playerSurvivalStates
UI.playerSurvivalSupport = COMBAT_SESSION.playerSurvivalSupport
UI.playerSurvivalRequestTimes = UI.playerSurvivalRequestTimes or {}

local PLAYER_SURVIVAL_CACHE_TTL = 30
local PLAYER_SURVIVAL_REQUEST_COOLDOWN = 2
local PLAYER_SURVIVAL_FADE_IN_DURATION = 0.08
local PLAYER_SURVIVAL_FADE_OUT_DELAY = 1.0
local PLAYER_SURVIVAL_FADE_OUT_DURATION = 1
local PLAYER_SURVIVAL_SCREEN_OFFSET_X = -100
local PLAYER_SURVIVAL_SCREEN_OFFSET_Y = -20

local function normalize_player_name_key(playerName)
  local raw = tostring(playerName or "")
  raw = string.gsub(raw, "^%s+", "")
  raw = string.gsub(raw, "%s+$", "")
  if raw == "" then
    return nil
  end
  if type(Ambiguate) == "function" then
    raw = Ambiguate(raw, "short")
  end
  return raw ~= "" and raw or nil
end

local function mark_player_survival_support(playerName)
  local cacheKey = normalize_player_name_key(playerName)
  if not cacheKey then
    return
  end
  UI.playerSurvivalSupport[cacheKey] = true
end

local function can_request_player_survival(playerName)
  local cacheKey = normalize_player_name_key(playerName)
  if not cacheKey then
    return false
  end
  return UI.playerSurvivalSupport[cacheKey] == true
end

local function cache_player_survival(playerName, source, timestamp)
  local cacheKey = normalize_player_name_key(playerName)
  if not cacheKey then
    return
  end
  local snapshot = get_survival_snapshot(source)
  UI.playerSurvivalStates[cacheKey] = {
    player_name = tostring(playerName or cacheKey),
    timestamp = tonumber(timestamp) or GetTime(),
    hit_points = snapshot.hit_points,
    armor_type = snapshot.armor_type,
    durability_current = snapshot.durability_current,
    durability_max = snapshot.durability_max,
    durability_infinite = snapshot.durability_infinite and true or false,
    rda = snapshot.rda,
    rda_crit = snapshot.rda_crit,
  }
end

local function get_cached_player_survival(playerName)
  local cacheKey = normalize_player_name_key(playerName)
  if not cacheKey then
    return nil
  end

  local localPlayerKey = normalize_player_name_key(UnitName("player") or "")
  if localPlayerKey and cacheKey == localPlayerKey then
    return get_survival_snapshot(STATE)
  end

  local cached = UI.playerSurvivalStates and UI.playerSurvivalStates[cacheKey]
  if not cached then
    return nil
  end
  return get_survival_snapshot(cached)
end

local function should_refresh_player_survival_cache(playerName)
  local cacheKey = normalize_player_name_key(playerName)
  if not cacheKey then
    return false
  end

  local localPlayerKey = normalize_player_name_key(UnitName("player") or "")
  if localPlayerKey and cacheKey == localPlayerKey then
    return false
  end

  local cached = UI.playerSurvivalStates and UI.playerSurvivalStates[cacheKey]
  if not cached then
    return true
  end

  return ((GetTime() - (tonumber(cached.timestamp) or 0)) > PLAYER_SURVIVAL_CACHE_TTL)
end

local function request_player_survival_sync(playerName)
  local cacheKey = normalize_player_name_key(playerName)
  if not cacheKey or not C_ChatInfo or not C_ChatInfo.SendAddonMessage then
    return false
  end

  local localPlayerKey = normalize_player_name_key(UnitName("player") or "")
  if localPlayerKey and cacheKey == localPlayerKey then
    return false
  end

  if not can_request_player_survival(playerName) then
    return false
  end

  local lastRequestAt = tonumber(UI.playerSurvivalRequestTimes[cacheKey]) or 0
  if (GetTime() - lastRequestAt) < PLAYER_SURVIVAL_REQUEST_COOLDOWN then
    return false
  end

  local msg = nil
  if Protocol and Protocol.build_player_survival_request then
    msg = Protocol.build_player_survival_request(UnitName("player") or "Unknown", GetTime())
  else
    msg = table.concat({
      "PLAYER_SURVIVAL_REQUEST",
      "1",
      tostring(UnitName("player") or "Unknown"),
      tostring(GetTime()),
    }, "|")
  end

  UI.playerSurvivalRequestTimes[cacheKey] = GetTime()
  C_ChatInfo.SendAddonMessage(ADDON_CHANNEL, msg, "WHISPER", tostring(playerName))
  return true
end

local function tooltip_is_visible(tooltip)
  return tooltip ~= nil and tooltip.IsShown ~= nil and tooltip:IsShown()
end

local function tooltip_has_player_unit(tooltip)
  if not tooltip_is_visible(tooltip) or not tooltip.GetUnit then
    return false
  end

  local _, unit = tooltip:GetUnit()
  return unit ~= nil and UnitExists(unit) and UnitIsPlayer(unit)
end

local function mouseover_has_player_unit()
  return UnitExists("mouseover") and UnitIsPlayer("mouseover")
end

local function cancel_player_survival_hover_hide(frame)
  if not frame then
    return
  end

  frame._easySanaluneHideAt = nil
  if UIFrameFadeRemoveFrame then
    UIFrameFadeRemoveFrame(frame)
  end
  frame._easySanaluneIsFadingOut = false
  if frame:IsShown() then
    frame:SetAlpha(1)
  end
end

local function get_preferred_player_survival_anchor(preferredAnchor)
  if UIParent then
    return UIParent
  end
  return preferredAnchor
end

local function anchor_player_survival_hover_frame(frame, preferredAnchor)
  if not frame or not UIParent then
    return
  end

  local anchorFrame = get_preferred_player_survival_anchor(preferredAnchor)
  frame.currentAnchorFrame = anchorFrame

  frame:ClearAllPoints()
  frame:SetPoint("RIGHT", UIParent, "RIGHT", PLAYER_SURVIVAL_SCREEN_OFFSET_X, PLAYER_SURVIVAL_SCREEN_OFFSET_Y)
  if frame.SetFrameLevel then
    frame:SetFrameLevel(240)
  end
end

local function fade_in_player_survival_hover_frame(frame)
  if not frame then
    return
  end

  cancel_player_survival_hover_hide(frame)

  if not frame:IsShown() then
    frame:SetAlpha(0)
    frame:Show()
  end

  if UIFrameFadeIn then
    UIFrameFadeIn(frame, PLAYER_SURVIVAL_FADE_IN_DURATION, tonumber(frame:GetAlpha()) or 0, 1)
  else
    frame:SetAlpha(1)
    frame:Show()
  end
end

local function fade_out_player_survival_hover_frame(frame, immediate)
  if not frame then
    return
  end

  frame._easySanaluneHideAt = nil
  frame.currentPlayerName = nil
  frame.currentAnchorFrame = nil

  if not frame:IsShown() then
    frame._easySanaluneIsFadingOut = false
    frame:SetAlpha(1)
    return
  end

  if UIFrameFadeRemoveFrame then
    UIFrameFadeRemoveFrame(frame)
  end

  if immediate or not UIFrameFadeOut then
    frame._easySanaluneIsFadingOut = false
    frame:SetAlpha(1)
    frame:Hide()
    return
  end

  local startAlpha = tonumber(frame:GetAlpha()) or 1
  if startAlpha <= 0 then
    startAlpha = 1
  end

  frame._easySanaluneIsFadingOut = true
  UIFrameFadeOut(frame, PLAYER_SURVIVAL_FADE_OUT_DURATION, startAlpha, 0)
  if frame.fadeInfo then
    frame.fadeInfo.finishedFunc = function()
      frame._easySanaluneIsFadingOut = false
      frame:SetAlpha(1)
      frame:Hide()
    end
  end
end

local function append_survival_tooltip_lines(tooltip, source)
  if not tooltip then
    return
  end

  local snapshot = get_survival_snapshot(source)
  tooltip:AddLine(" ")
  tooltip:AddLine(L_get("ui_current_status_title"), 1, 0.82, 0.25)

  if tooltip.AddDoubleLine then
    tooltip:AddDoubleLine(L_get("ui_label_hit_points"), tostring(tonumber(snapshot.hit_points) or DEFAULT_HIT_POINTS), 0.85, 0.85, 0.85, 1, 1, 1)
    tooltip:AddDoubleLine(L_get("ui_label_armor_type"), get_armor_type_label(snapshot.armor_type), 0.85, 0.85, 0.85, 1, 1, 1)
    tooltip:AddDoubleLine(L_get("ui_label_durability"), format_durability_text(snapshot), 0.85, 0.85, 0.85, 1, 1, 1)
    tooltip:AddDoubleLine(L_get("ui_label_rda"), tostring(tonumber(snapshot.rda) or 0), 0.85, 0.85, 0.85, 1, 1, 1)
    tooltip:AddDoubleLine(L_get("ui_label_rda_crit"), tostring(tonumber(snapshot.rda_crit) or 0), 0.85, 0.85, 0.85, 1, 1, 1)
  else
    tooltip:AddLine(string.format("%s : %s", L_get("ui_label_hit_points"), tostring(tonumber(snapshot.hit_points) or DEFAULT_HIT_POINTS)), 0.85, 0.85, 0.85)
    tooltip:AddLine(string.format("%s : %s", L_get("ui_label_armor_type"), get_armor_type_label(snapshot.armor_type)), 0.85, 0.85, 0.85)
    tooltip:AddLine(string.format("%s : %s", L_get("ui_label_durability"), format_durability_text(snapshot)), 0.85, 0.85, 0.85)
    tooltip:AddLine(string.format("%s : %s", L_get("ui_label_rda"), tostring(tonumber(snapshot.rda) or 0)), 0.85, 0.85, 0.85)
    tooltip:AddLine(string.format("%s : %s", L_get("ui_label_rda_crit"), tostring(tonumber(snapshot.rda_crit) or 0)), 0.85, 0.85, 0.85)
  end
end

local function ensure_player_survival_hover_frame()
  if UI.playerSurvivalHoverFrame then
    return UI.playerSurvivalHoverFrame
  end

  local frame = CreateFrame("Frame", "EasySanalunePlayerSurvivalHoverFrame", UIParent, "BackdropTemplate")
  frame:SetSize(220, 132)
  frame:SetFrameStrata("TOOLTIP")
  frame:SetFrameLevel(240)
  frame:SetClampedToScreen(true)
  frame:EnableMouse(false)
  if StdUi and StdUi.ApplyBackdrop then
    StdUi:ApplyBackdrop(frame, 'panel')
  end
  apply_panel_theme(frame, false, true)
  if frame.SetBackdropColor then
    frame:SetBackdropColor(0.05, 0.08, 0.14, 0.94)
  end
  if frame.SetBackdropBorderColor then
    frame:SetBackdropBorderColor(0.20, 0.34, 0.55, 0.95)
  end

  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
  frame.title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
  frame.title:SetJustifyH("LEFT")
  style_font_string(frame.title, true)

  frame.values = {}
  local rowKeys = {
    "ui_label_hit_points",
    "ui_label_armor_type",
    "ui_label_durability",
    "ui_label_rda",
    "ui_label_rda_crit",
  }

  local previous = frame.title
  for i = 1, #rowKeys do
    local key = rowKeys[i]
    local row = CreateFrame("Frame", nil, frame)
    row:SetSize(204, 18)
    row:SetPoint("TOPLEFT", previous, i == 1 and "BOTTOMLEFT" or "BOTTOMLEFT", 0, i == 1 and -8 or -4)

    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.label:SetWidth(92)
    row.label:SetJustifyH("LEFT")
    row.label:SetText(L_get(key))
    style_font_string(row.label)

    row.value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.value:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.value:SetWidth(104)
    row.value:SetJustifyH("RIGHT")
    style_font_string(row.value, true)

    frame.values[key] = row.value
    previous = row
  end

  frame._easySanaluneHoverCheckElapsed = 0
  frame._easySanaluneHideAt = nil
  frame._easySanaluneIsFadingOut = false
  frame:SetScript("OnUpdate", function(self, elapsed)
    if not self:IsShown() then
      return
    end

    self._easySanaluneHoverCheckElapsed = (tonumber(self._easySanaluneHoverCheckElapsed) or 0) + (tonumber(elapsed) or 0)
    if self._easySanaluneHoverCheckElapsed < 0.05 then
      return
    end
    self._easySanaluneHoverCheckElapsed = 0

    local preferredAnchor = get_preferred_player_survival_anchor(self.currentAnchorFrame)
    if preferredAnchor ~= self.currentAnchorFrame then
      anchor_player_survival_hover_frame(self, preferredAnchor)
    end

    local hasPlayerMouseover = mouseover_has_player_unit()
    local gameTooltipVisible = tooltip_has_player_unit(GameTooltip)
    local trpTooltipVisible = tooltip_is_visible(_G.TRP3_MainTooltip)

    if hasPlayerMouseover or gameTooltipVisible or trpTooltipVisible then
      if self._easySanaluneHideAt or self._easySanaluneIsFadingOut then
        cancel_player_survival_hover_hide(self)
      end
      return
    end

    if not self._easySanaluneHideAt then
      self._easySanaluneHideAt = GetTime() + PLAYER_SURVIVAL_FADE_OUT_DELAY
      return
    end

    if not self._easySanaluneIsFadingOut and GetTime() >= (tonumber(self._easySanaluneHideAt) or 0) then
      fade_out_player_survival_hover_frame(self)
    end
  end)

  frame:Hide()
  UI.playerSurvivalHoverFrame = frame
  return frame
end

local function show_player_survival_hover_frame(anchor, playerName, source)
  local frame = ensure_player_survival_hover_frame()
  local snapshot = get_survival_snapshot(source)
  frame.currentPlayerName = normalize_player_name_key(playerName)
  local displayName = tostring(playerName or "")
  if type(Ambiguate) == "function" then
    displayName = Ambiguate(displayName, "short")
  end
  if displayName == "" then
    displayName = L_get("ui_current_status_title")
  else
    displayName = displayName .. " - " .. L_get("ui_current_status_title")
  end

  frame.title:SetText(displayName)
  frame.values["ui_label_hit_points"]:SetText(tostring(tonumber(snapshot.hit_points) or DEFAULT_HIT_POINTS))
  frame.values["ui_label_armor_type"]:SetText(get_armor_type_label(snapshot.armor_type))
  frame.values["ui_label_durability"]:SetText(format_durability_text(snapshot))
  frame.values["ui_label_rda"]:SetText(tostring(tonumber(snapshot.rda) or 0))
  frame.values["ui_label_rda_crit"]:SetText(tostring(tonumber(snapshot.rda_crit) or 0))

  anchor_player_survival_hover_frame(frame, anchor)
  fade_in_player_survival_hover_frame(frame)
end

local function hide_player_survival_hover_frame(immediate)
  if not UI.playerSurvivalHoverFrame then
    return
  end

  if immediate then
    fade_out_player_survival_hover_frame(UI.playerSurvivalHoverFrame, true)
    return
  end

  if mouseover_has_player_unit() then
    cancel_player_survival_hover_hide(UI.playerSurvivalHoverFrame)
    return
  end

  if not UI.playerSurvivalHoverFrame._easySanaluneHideAt then
    UI.playerSurvivalHoverFrame._easySanaluneHideAt = GetTime() + PLAYER_SURVIVAL_FADE_OUT_DELAY
  end
end

function UI.EnsurePlayerSurvivalTooltipHook()
  if UI._playerSurvivalTooltipHooked or not GameTooltip or not GameTooltip.HookScript then
    return
  end

  GameTooltip:HookScript("OnTooltipCleared", function(tooltip)
    tooltip._easySanaluneHasSurvivalBlock = false
    hide_player_survival_hover_frame()
  end)

  GameTooltip:HookScript("OnHide", function()
    hide_player_survival_hover_frame()
  end)

  if _G.TRP3_MainTooltip and _G.TRP3_MainTooltip.HookScript and not _G.TRP3_MainTooltip._easySanaluneSurvivalHooked then
    _G.TRP3_MainTooltip:HookScript("OnHide", function()
      hide_player_survival_hover_frame()
    end)
    _G.TRP3_MainTooltip:HookScript("OnTooltipCleared", function()
      hide_player_survival_hover_frame()
    end)
    _G.TRP3_MainTooltip:HookScript("OnShow", function(tooltip)
      if not UnitExists("mouseover") or not UnitIsPlayer("mouseover") then
        return
      end
      local unitName = UnitName("mouseover")
      local snapshot = get_cached_player_survival(unitName)
      if snapshot then
        show_player_survival_hover_frame(tooltip, unitName, snapshot)
      end
    end)
    _G.TRP3_MainTooltip._easySanaluneSurvivalHooked = true
  end

  GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
    if not tooltip then
      return
    end

    local _, unit = tooltip:GetUnit()
    if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then
      hide_player_survival_hover_frame()
      return
    end

    local unitName = UnitName(unit)
    local snapshot = get_cached_player_survival(unitName)
    if not snapshot then
      request_player_survival_sync(unitName)
      hide_player_survival_hover_frame()
      return
    end

    if should_refresh_player_survival_cache(unitName) then
      request_player_survival_sync(unitName)
    end

    if not tooltip._easySanaluneHasSurvivalBlock then
      append_survival_tooltip_lines(tooltip, snapshot)
      tooltip._easySanaluneHasSurvivalBlock = true
      tooltip:Show()
    end
    show_player_survival_hover_frame(tooltip, unitName, snapshot)
  end)

  local hoverWatcher = CreateFrame("Frame")
  hoverWatcher:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
  hoverWatcher:SetScript("OnEvent", function()
    if not UnitExists("mouseover") or not UnitIsPlayer("mouseover") then
      hide_player_survival_hover_frame()
      return
    end

    local unitName = UnitName("mouseover")
    local snapshot = get_cached_player_survival(unitName)
    if not snapshot then
      request_player_survival_sync(unitName)
      hide_player_survival_hover_frame()
      return
    end

    if should_refresh_player_survival_cache(unitName) then
      request_player_survival_sync(unitName)
    end

    local anchor = GameTooltip and GameTooltip:IsShown() and GameTooltip or nil
    show_player_survival_hover_frame(anchor, unitName, snapshot)
  end)
  UI.playerSurvivalHoverWatcher = hoverWatcher

  UI._playerSurvivalTooltipHooked = true
end

local ACTION_HISTORY_MAX = 5

local function append_reason_segment(baseText, extraText)
  local base = tostring(baseText or "")
  local extra = tostring(extraText or "")
  if extra == "" then
    return base
  end
  if base == "" then
    return extra
  end
  return base .. " | " .. extra
end

local function record_action_history(entry)
  if type(UI.actionHistory) ~= "table" or type(entry) ~= "table" then
    return
  end
  entry.timestamp = tonumber(entry.timestamp) or GetTime()
  table.insert(UI.actionHistory, 1, entry)
  while #UI.actionHistory > ACTION_HISTORY_MAX do
    table.remove(UI.actionHistory)
  end
end

function UI.RecordActionHistory(entry)
  record_action_history(entry)
end

function UI.GetActionHistory()
  return UI.actionHistory or {}
end

local function reset_synced_mob_state(syncId, senderName, timestamp, activeMobId, expectedCount)
  local state = UI.syncedMobState or {}
  state.syncId = tostring(syncId or "")
  state.sender = tostring(senderName or "")
  state.activeMobId = tonumber(activeMobId)
  state.timestamp = tonumber(timestamp) or GetTime()
  state.expectedCount = tonumber(expectedCount) or 0
  state.receivedCount = 0
  state.complete = false
  state.mobs = {}
  UI.syncedMobState = state
  COMBAT_SESSION.syncedMobState = state
end

local function resolve_pending_request_selected_mob_id(state, requestedMobId, requestedMobName)
  if type(state) ~= "table" or type(state.mj_mobs) ~= "table" then
    return nil
  end

  local numericMobId = tonumber(requestedMobId)
  if numericMobId and state.mj_mobs[numericMobId] then
    return numericMobId
  end

  local targetName = tostring(requestedMobName or "")
  targetName = string.gsub(targetName, "^%s+", "")
  targetName = string.gsub(targetName, "%s+$", "")
  if targetName ~= "" then
    local lowerTargetName = string.lower(targetName)
    for mobId, mob in pairs(state.mj_mobs) do
      local mobName = tostring(mob and mob.name or "")
      mobName = string.gsub(mobName, "^%s+", "")
      mobName = string.gsub(mobName, "%s+$", "")
      if mobName ~= "" and string.lower(mobName) == lowerTargetName then
        return tonumber(mobId) or mobId
      end
    end
  end

  return state.mj_active_mob_id
end

local function add_synced_mob_entry(syncId, senderName, mobId, mobName, isSupport, isActive)
  local state = UI.syncedMobState
  if type(state) ~= "table" then
    reset_synced_mob_state(syncId, senderName, GetTime(), nil, 0)
    state = UI.syncedMobState
  end
  if tostring(state.syncId or "") ~= tostring(syncId or "") or tostring(state.sender or "") ~= tostring(senderName or "") then
    reset_synced_mob_state(syncId, senderName, GetTime(), nil, 0)
    state = UI.syncedMobState
  end

  local numericMobId = tonumber(mobId)
  if not numericMobId then
    return
  end

  state.mobs[numericMobId] = {
    id = numericMobId,
    name = tostring(mobName or "Mob"),
    isSupport = isSupport and true or false,
    isActive = isActive and true or false,
  }
  if isActive then
    state.activeMobId = numericMobId
  end
  state.receivedCount = (tonumber(state.receivedCount) or 0) + 1
end

local function finalize_synced_mob_state(syncId, senderName, timestamp, receivedCount)
  local state = UI.syncedMobState
  if type(state) ~= "table" then
    return
  end
  if tostring(state.syncId or "") ~= tostring(syncId or "") or tostring(state.sender or "") ~= tostring(senderName or "") then
    return
  end
  state.timestamp = tonumber(timestamp) or GetTime()
  state.receivedCount = tonumber(receivedCount) or state.receivedCount or 0
  state.complete = true
end

function UI.GetSyncedMobEntries()
  local state = UI.syncedMobState
  local entries = {}
  if type(state) ~= "table" or type(state.mobs) ~= "table" then
    return entries
  end
  for _, mob in pairs(state.mobs) do
    entries[#entries + 1] = mob
  end
  table.sort(entries, function(a, b)
    local aName = tostring(a and a.name or "")
    local bName = tostring(b and b.name or "")
    if aName == bName then
      return (tonumber(a and a.id) or 0) < (tonumber(b and b.id) or 0)
    end
    return aName < bName
  end)
  return entries
end

function UI.GetSyncedMobState()
  return UI.syncedMobState
end

local function get_addon_send_channel()
  if IsInRaid() then
    return "RAID"
  elseif IsInGroup() then
    return "PARTY"
  end
  return nil
end

-- Regle metier MJ: seules deux familles d'attaque sont autorisees sur le reseau.
-- Toute autre valeur est forcee en ATK_PHY pour eviter les comportements instables.
local function normalize_mj_attack_type(rawAttackType)
  local normalized = string.upper(tostring(rawAttackType or "ATK_PHY"))
  normalized = string.gsub(normalized, "|", "")
  if normalized == "ATK_MAG" then
    return "ATK_MAG"
  end
  return "ATK_PHY"
end

-- Regle metier RP: les bornes de /rand doivent rester propres, entieres et ordonnees.
-- Si elles sont invalides, on bloque la valeur au lieu de la propager.
local function normalize_network_roll_bounds(minValue, maxValue)
  local minRoll = tonumber(minValue)
  local maxRoll = tonumber(maxValue)
  if not minRoll or not maxRoll then
    return nil, nil
  end

  minRoll = math.floor(minRoll)
  maxRoll = math.floor(maxRoll)
  if minRoll > maxRoll then
    minRoll, maxRoll = maxRoll, minRoll
  end

  if minRoll < 1 then
    minRoll = 1
  end
  if maxRoll < 1 then
    return nil, nil
  end

  return minRoll, maxRoll
end

function UI.SendMJAnnounce(isEnabled)
  local channel = get_addon_send_channel()
  if not channel then return end
  local playerName = UnitName("player") or "Unknown"
  local enabledState = isEnabled
  if enabledState == nil then
    enabledState = STATE and STATE.mj_enabled and true or false
  end
  local msg = nil
  if Protocol and Protocol.build_mj_announce then
    msg = Protocol.build_mj_announce(playerName, GetTime(), enabledState)
  else
    msg = "MJ_ANNOUNCE|1|" .. playerName .. "|" .. tostring(GetTime()) .. "|" .. (enabledState and "1" or "0")
  end
  C_ChatInfo.SendAddonMessage(ADDON_CHANNEL, msg, channel)
end

function UI.SendPlayerSurvivalSync(targetPlayer)
  if not STATE then
    return false
  end

  local snapshot = get_survival_snapshot(STATE)
  local playerName = UnitName("player") or "Unknown"
  cache_player_survival(playerName, snapshot, GetTime())

  local channel = nil
  local sendTarget = nil
  if targetPlayer and tostring(targetPlayer) ~= "" then
    channel = "WHISPER"
    sendTarget = tostring(targetPlayer)
  else
    channel = get_addon_send_channel()
    if not channel then
      return false
    end
  end

  local msg = nil
  if Protocol and Protocol.build_player_survival_sync then
    msg = Protocol.build_player_survival_sync(
      playerName,
      GetTime(),
      snapshot.hit_points,
      snapshot.armor_type,
      snapshot.durability_current,
      snapshot.durability_max,
      snapshot.durability_infinite,
      snapshot.rda,
      snapshot.rda_crit
    )
  else
    msg = table.concat({
      "PLAYER_SURVIVAL_SYNC",
      "1",
      playerName,
      tostring(GetTime()),
      tostring(tonumber(snapshot.hit_points) or DEFAULT_HIT_POINTS),
      tostring(snapshot.armor_type or DEFAULT_ARMOR_TYPE),
      snapshot.durability_current == nil and "" or tostring(snapshot.durability_current),
      snapshot.durability_max == nil and "" or tostring(snapshot.durability_max),
      snapshot.durability_infinite and "1" or "0",
      tostring(tonumber(snapshot.rda) or 0),
      tostring(tonumber(snapshot.rda_crit) or 0),
    }, "|")
  end

  if channel == "WHISPER" and sendTarget then
    C_ChatInfo.SendAddonMessage(ADDON_CHANNEL, msg, channel, sendTarget)
  else
    C_ChatInfo.SendAddonMessage(ADDON_CHANNEL, msg, channel)
  end
  return true
end

function UI.SendMJMobSync()
  local channel = get_addon_send_channel()
  if not channel then
    return false
  end

  local mjName = UnitName("player") or "MJ"
  local mobs = {}
  local mobTable = STATE and STATE.mj_mobs or {}
  for mobId, mob in pairs(mobTable or {}) do
    mobs[#mobs + 1] = {
      id = tonumber(mobId),
      name = tostring(mob and mob.name or "Mob"),
      isSupport = mob and mob.is_support and true or false,
      isActive = STATE and tonumber(STATE.mj_active_mob_id) == tonumber(mobId) or false,
    }
  end
  table.sort(mobs, function(a, b)
    return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
  end)

  local syncId = string.format("%s_SYNC_%d", mjName, math.floor(GetTime() * 1000))
  local resetMsg = Protocol and Protocol.build_mj_mob_sync_reset
    and Protocol.build_mj_mob_sync_reset(syncId, mjName, GetTime(), STATE and STATE.mj_active_mob_id or "", #mobs)
    or table.concat({ "MJ_MOB_SYNC_RESET", "1", syncId, mjName, tostring(GetTime()), tostring(STATE and STATE.mj_active_mob_id or ""), tostring(#mobs) }, "|")
  C_ChatInfo.SendAddonMessage(ADDON_CHANNEL, resetMsg, channel)

  for i = 1, #mobs do
    local mob = mobs[i]
    local entryMsg = Protocol and Protocol.build_mj_mob_sync_entry
      and Protocol.build_mj_mob_sync_entry(syncId, mjName, mob.id, mob.name, mob.isSupport, mob.isActive)
      or table.concat({ "MJ_MOB_SYNC_ENTRY", "1", syncId, mjName, tostring(mob.id or ""), tostring(mob.name or "Mob"), mob.isSupport and "1" or "0", mob.isActive and "1" or "0" }, "|")
    C_ChatInfo.SendAddonMessage(ADDON_CHANNEL, entryMsg, channel)
  end

  local doneMsg = Protocol and Protocol.build_mj_mob_sync_done
    and Protocol.build_mj_mob_sync_done(syncId, mjName, GetTime(), #mobs)
    or table.concat({ "MJ_MOB_SYNC_DONE", "1", syncId, mjName, tostring(GetTime()), tostring(#mobs) }, "|")
  C_ChatInfo.SendAddonMessage(ADDON_CHANNEL, doneMsg, channel)
  return true
end

function UI.MaybeAutoRefreshMJMobSync(delaySeconds)
  if not STATE or not STATE.mj_enabled then
    return false
  end

  local mobTable = STATE.mj_mobs or {}
  if type(mobTable) ~= "table" or next(mobTable) == nil then
    return false
  end

  if not get_addon_send_channel() then
    return false
  end

  local now = GetTime()
  if UI._mjAutoSyncScheduledAt and (now - UI._mjAutoSyncScheduledAt) < 1 then
    return false
  end

  UI._mjAutoSyncScheduledAt = now
  local delay = tonumber(delaySeconds)
  if delay == nil or delay < 0 then
    delay = 0.5
  end

  C_Timer.After(delay, function()
    UI._mjAutoSyncScheduledAt = nil
    if not STATE or not STATE.mj_enabled then
      return
    end
    local refreshedMobTable = STATE.mj_mobs or {}
    if type(refreshedMobTable) ~= "table" or next(refreshedMobTable) == nil then
      return
    end
    UI.SendMJMobSync()
  end)
  return true
end

local function has_known_mj_in_current_group()
  if STATE and STATE.mj_enabled then
    return true
  end

  local knownMJs = UI.knownMJs
  if type(knownMJs) ~= "table" then
    return false
  end

  local currentPlayer = Ambiguate(UnitName("player") or "", "short")
  local currentGroup = {}

  local function add_group_member(unit)
    if not UnitExists(unit) then
      return
    end
    local name = UnitName(unit)
    if not name or name == "" then
      return
    end
    currentGroup[Ambiguate(name, "short")] = true
  end

  if IsInRaid() then
    for i = 1, (GetNumGroupMembers() or 0) do
      add_group_member("raid" .. tostring(i))
    end
  elseif IsInGroup() then
    add_group_member("player")
    for i = 1, (GetNumSubgroupMembers() or 0) do
      add_group_member("party" .. tostring(i))
    end
  else
    return false
  end

  for mjName in pairs(knownMJs) do
    local shortName = Ambiguate(tostring(mjName or ""), "short")
    if shortName ~= "" and shortName ~= currentPlayer and currentGroup[shortName] then
      return true
    end
  end

  return false
end

UI.HasKnownMJInCurrentGroup = has_known_mj_in_current_group

function UI.ShouldPromptForOffensiveRand(randName, randRole)
  local explicitRole = string.lower(tostring(randRole or ""))
  explicitRole = string.gsub(explicitRole, "^%s+", "")
  explicitRole = string.gsub(explicitRole, "%s+$", "")
  if explicitRole == "support" or explicitRole == "defensive" then
    return false
  end
  if explicitRole == "offensive" then
    return has_known_mj_in_current_group()
  end

  local rawName = string.lower(tostring(randName or ""))
  rawName = string.gsub(rawName, "[éèêë]", "e")
  rawName = string.gsub(rawName, "[àâä]", "a")
  rawName = string.gsub(rawName, "[îï]", "i")
  rawName = string.gsub(rawName, "[ôö]", "o")
  rawName = string.gsub(rawName, "[ùûü]", "u")
  rawName = string.gsub(rawName, "[^%w%s]", "")
  rawName = string.gsub(rawName, "%s+", " ")
  rawName = string.gsub(rawName, "^%s+", "")
  rawName = string.gsub(rawName, "%s+$", "")
  if rawName == "soutien" or rawName == "support" or rawName == "defense physique" or rawName == "defense magique" or rawName == "esquive" or rawName == "dodge" then
    return false
  end
  return has_known_mj_in_current_group()
end

local extract_bonus_from_label
local strip_bonus_from_rand_name
local infer_rand_role_from_name
local normalize_rand_role

local function get_adjusted_crit_threshold(kind, baseValue)
  local numericBase = tonumber(baseValue)
  if numericBase == nil then
    return nil, 0, nil
  end

  local bonus = 0
  local sourceText = nil
  if UI.Buffs and UI.Buffs.GetCritThresholdBonus then
    local totalBonus, sources = UI.Buffs.GetCritThresholdBonus(kind)
    bonus = tonumber(totalBonus) or 0
    if type(sources) == "table" and #sources > 0 then
      sourceText = table.concat(sources, ", ")
    end
  end

  local adjusted = numericBase - bonus
  if adjusted < 1 then
    adjusted = 1
  end

  return adjusted, bonus, sourceText
end

local function send_rand_request_payload(requestId, channel, sender, safeName, reqMin, reqMax, critOff, critDef, mobName, attackerReason, mobSyncId, mobId, isBehindAttack)
  local msg = nil
  if Protocol and Protocol.build_rand_request then
    msg = Protocol.build_rand_request(requestId, sender, safeName, reqMin, reqMax, GetTime(), critOff, critDef, mobName, attackerReason, mobSyncId, mobId, isBehindAttack)
  else
    msg = table.concat({
      "RAND_REQUEST", requestId, sender, safeName,
      tostring(reqMin), tostring(reqMax), tostring(GetTime()),
      tostring(critOff), tostring(critDef), tostring(mobName or ""), string.gsub(tostring(attackerReason or ""), "|", "/"),
      tostring(mobSyncId or ""), tostring(mobId or ""), isBehindAttack and "1" or "0"
    }, "|")
  end
  C_ChatInfo.SendAddonMessage(ADDON_CHANNEL, msg, channel)
end

function UI.SendRandRequest(min, max, randName, randInfo, randRole, mobName, mobId, mobSyncId, isBehindAttack, skipPrompt)
  local channel = get_addon_send_channel()
  if not channel then return end

  local reqMin, reqMax = normalize_network_roll_bounds(min, max)
  if not reqMin or not reqMax then
    return
  end

  local effectiveRole = normalize_rand_role and normalize_rand_role(randRole, randName) or "offensive"

  local requestId = nil
  local sender = UnitName("player") or "Unknown"
  if CombatSessionLogic and CombatSessionLogic.next_rand_request_id then
    requestId = CombatSessionLogic.next_rand_request_id(COMBAT_SESSION, sender)
  else
    COMBAT_SESSION.mjRequestCounter = (tonumber(COMBAT_SESSION.mjRequestCounter) or 0) + 1
    requestId = tostring(sender) .. "_" .. tostring(COMBAT_SESSION.mjRequestCounter)
  end
  local critOff = tonumber(STATE and STATE.crit_off_success) or 0
  local critDef = tonumber(STATE and STATE.crit_def_success) or 0
  critOff = select(1, get_adjusted_crit_threshold("crit_off_success", critOff)) or critOff
  critDef = select(1, get_adjusted_crit_threshold("crit_def_success", critDef)) or critDef
  -- Nettoie le nom du rand: le caractere | casse le parsing des messages reseau.
  local safeName = string.gsub(tostring(randName or ""), "|", "/")
  local attackerReason = ""
  local attackerBonus = extract_bonus_from_label(randName)
  if UI.Buffs and UI.Buffs.GetBonusSourceText and attackerBonus ~= 0 then
    local sourceText = UI.Buffs.GetBonusSourceText(strip_bonus_from_rand_name(randName))
    if sourceText and sourceText ~= "" then
      attackerReason = string.format("%s: %s", attackerBonus > 0 and "Bonus" or "Malus", sourceText)
    end
  end

  local cleanMobName = tostring(mobName or "")
  cleanMobName = string.gsub(cleanMobName, "^%s+", "")
  cleanMobName = string.gsub(cleanMobName, "%s+$", "")
  if effectiveRole == "offensive" and not skipPrompt and has_known_mj_in_current_group() and cleanMobName == "" then
    local syncedState = UI.GetSyncedMobState and UI.GetSyncedMobState() or UI.syncedMobState
    if UI.ShowOffensiveMobPrompt then
      if not syncedState or not syncedState.complete then
        L_print("mj_sync_missing")
      end
      UI.ShowOffensiveMobPrompt({
        min = reqMin,
        max = reqMax,
        randName = randName,
        randInfo = randInfo,
        randRole = randRole,
        requestId = requestId,
      })
      return requestId
    end
  end

  send_rand_request_payload(
    requestId,
    channel,
    sender,
    safeName,
    reqMin,
    reqMax,
    critOff,
    critDef,
    tostring(mobName or ""),
    attackerReason,
    mobSyncId,
    mobId,
    isBehindAttack and true or false
  )
  return requestId
end

function UI.SendMJAttackRequest(targetPlayer, attackType, min, max, mobName, attackCritOff, attackCritDef, isBehindAttack)
  local channel = get_addon_send_channel()
  if not channel then return nil end

  local reqMin, reqMax = normalize_network_roll_bounds(min, max)
  if not reqMin or not reqMax then
    return nil
  end

  local target = tostring(targetPlayer or "")
  target = string.gsub(target, "^%s+", "")
  target = string.gsub(target, "%s+$", "")
  if target == "" then return nil end

  local requestId = nil
  if CombatSessionLogic and CombatSessionLogic.next_attack_request_id then
    requestId = CombatSessionLogic.next_attack_request_id(COMBAT_SESSION, UnitName("player") or "MJ")
  else
    COMBAT_SESSION.mjAttackRequestCounter = (tonumber(COMBAT_SESSION.mjAttackRequestCounter) or 0) + 1
    requestId = (UnitName("player") or "MJ") .. "_ATK_" .. COMBAT_SESSION.mjAttackRequestCounter
  end
  local mjName = UnitName("player") or "MJ"
  local atkType = normalize_mj_attack_type(attackType)
  local safeMobName = string.gsub(tostring(mobName or ""), "|", "/")
  local critOff = tonumber(attackCritOff) or 0
  local critDef = tonumber(attackCritDef) or 0

  local msg = nil
  if Protocol and Protocol.build_mj_attack_request then
    msg = Protocol.build_mj_attack_request(requestId, mjName, target, atkType, reqMin, reqMax, GetTime(), critOff, critDef, safeMobName, isBehindAttack)
  else
    msg = table.concat({
      "MJ_ATTACK_REQUEST", requestId, mjName, target, atkType,
      tostring(reqMin), tostring(reqMax), tostring(GetTime()),
      tostring(critOff), tostring(critDef), safeMobName, isBehindAttack and "1" or "0"
    }, "|")
  end
  C_ChatInfo.SendAddonMessage(ADDON_CHANNEL, msg, channel)
  record_action_history({
    kind = "mj_attack_request",
    actor = mjName,
    target = target,
    mobName = safeMobName,
    attackType = atkType,
    min = reqMin,
    max = reqMax,
    isBehindAttack = isBehindAttack and true or false,
    replay = {
      kind = "mj_attack_request",
      target = target,
      attackType = atkType,
      min = reqMin,
      max = reqMax,
      mobName = safeMobName,
      critOff = critOff,
      critDef = critDef,
      isBehindAttack = isBehindAttack and true or false,
    },
  })
  return requestId
end

function UI.OnAddonMessage(prefix, message, channel, sender)
  if prefix ~= ADDON_CHANNEL or not message then return end

  local parsed = nil
  if Protocol and Protocol.parse_message then
    parsed = Protocol.parse_message(message)
  end
  if not parsed then
    return
  end

  local msgType = parsed.type

  if msgType == ((Protocol and Protocol.TYPES and Protocol.TYPES.MJ_ANNOUNCE) or "MJ_ANNOUNCE") then
    local mjName = parsed.playerName
    if mjName and mjName ~= "" then
      if parsed.isEnabled == false then
        if type(UI.knownMJs) == "table" then
          UI.knownMJs[mjName] = nil
        end
      elseif CombatSessionLogic and CombatSessionLogic.add_known_mj then
        CombatSessionLogic.add_known_mj(COMBAT_SESSION, mjName, GetTime())
      else
        UI.knownMJs[mjName] = GetTime()
      end
    end

  elseif msgType == ((Protocol and Protocol.TYPES and Protocol.TYPES.PLAYER_SURVIVAL_REQUEST) or "PLAYER_SURVIVAL_REQUEST") then
    mark_player_survival_support(sender)
    if sender and sender ~= "" and UI.SendPlayerSurvivalSync then
      UI.SendPlayerSurvivalSync(sender)
    end

  elseif msgType == ((Protocol and Protocol.TYPES and Protocol.TYPES.PLAYER_SURVIVAL_SYNC) or "PLAYER_SURVIVAL_SYNC") then
    local playerName = parsed.playerName or sender
    mark_player_survival_support(playerName)
    mark_player_survival_support(sender)
    if playerName and playerName ~= "" then
      cache_player_survival(playerName, {
        hit_points = parsed.hitPoints,
        armor_type = parsed.armorType,
        durability_current = parsed.durabilityCurrent,
        durability_max = parsed.durabilityMax,
        durability_infinite = parsed.durabilityInfinite and true or false,
        rda = parsed.rda,
        rda_crit = parsed.rdaCrit,
      }, parsed.timestamp)

      if UnitExists("mouseover") then
        local mouseoverName = UnitName("mouseover")
        local currentKey = normalize_player_name_key(mouseoverName)
        local cachedKey = normalize_player_name_key(playerName)
        if currentKey and cachedKey and currentKey == cachedKey then
          local anchor = GameTooltip and GameTooltip:IsShown() and GameTooltip or nil
          show_player_survival_hover_frame(anchor, mouseoverName or playerName, get_cached_player_survival(playerName))
        end
      end
    end

  elseif msgType == ((Protocol and Protocol.TYPES and Protocol.TYPES.RAND_REQUEST) or "RAND_REQUEST") then
    if not STATE or not STATE.mj_enabled then return end
    local requestId = parsed.requestId
    local reqSender = parsed.sender
    local reqName  = parsed.randName
    local reqMin   = parsed.min
    local reqMax   = parsed.max
    local reqCritOff = parsed.attackerCritOff
    local reqCritDef = parsed.attackerCritDef
    local mobName = parsed.mobName or ""
    local attackerReason = parsed.attackerReason or ""

    reqMin, reqMax = normalize_network_roll_bounds(reqMin, reqMax)
    if not requestId or not reqSender or not reqMin or not reqMax then return end

    UI.pendingMJRequests[requestId] = {
      id       = requestId,
      sender   = reqSender,
      randName = reqName,
      min      = reqMin,
      max      = reqMax,
      attackerCritOff = reqCritOff,
      attackerCritDef = reqCritDef,
      attackerReason = attackerReason,
      time     = GetTime(),
      mobName  = mobName,
      mobSyncId = parsed.mobSyncId or "",
      mobId = parsed.mobId,
      isBehindAttack = parsed.isBehindAttack and true or false,
      selectedMobId = resolve_pending_request_selected_mob_id(STATE, parsed.mobId, mobName),
    }

    record_action_history({
      kind = "rand_request",
      actor = reqSender,
      target = UnitName("player") or "MJ",
      randName = reqName,
      min = reqMin,
      max = reqMax,
      mobName = mobName,
      isBehindAttack = parsed.isBehindAttack and true or false,
      replay = {
        kind = "rand_request",
        sender = reqSender,
        randName = reqName,
        min = reqMin,
        max = reqMax,
        attackerCritOff = reqCritOff,
        attackerCritDef = reqCritDef,
        attackerReason = attackerReason,
        mobName = mobName,
        mobSyncId = parsed.mobSyncId or "",
        mobId = parsed.mobId,
        isBehindAttack = parsed.isBehindAttack and true or false,
      },
    })

    if UI.ShowMJNotification then
      UI.ShowMJNotification(requestId)
    end

  elseif msgType == ((Protocol and Protocol.TYPES and Protocol.TYPES.RAND_RESOLVE) or "RAND_RESOLVE") then
    local resultText = parsed.resultText
    if resultText and resultText ~= "" then
      print_resolution_for_local_context(resultText)
    end

  elseif msgType == ((Protocol and Protocol.TYPES and Protocol.TYPES.MJ_ATTACK_REQUEST) or "MJ_ATTACK_REQUEST") then
    local requestId = parsed.requestId
    local mjName    = parsed.mjName
    local target    = parsed.target
    local attackType = normalize_mj_attack_type(parsed.attackType)
    local reqMin    = parsed.min
    local reqMax    = parsed.max
    local reqCritOff = parsed.attackerCritOff
    local reqCritDef = parsed.attackerCritDef
    local mobName = parsed.mobName or ""

    reqMin, reqMax = normalize_network_roll_bounds(reqMin, reqMax)
    if not requestId or not mjName or not reqMin or not reqMax then return end

    local myName = UnitName("player") or ""
    local myShort = Ambiguate(myName, "short")
    local targetShort = Ambiguate(tostring(target or ""), "short")
    if targetShort ~= "" and targetShort ~= myShort then
      return
    end

    UI.pendingPlayerDefenseRequests[requestId] = {
      id = requestId,
      attacker = mjName,
      target = target,
      attackType = attackType,
      min = reqMin,
      max = reqMax,
      attackerCritOff = reqCritOff,
      attackerCritDef = reqCritDef,
      mobName = mobName,
      isBehindAttack = parsed.isBehindAttack and true or false,
      time = GetTime(),
    }

    if UI.ShowPlayerDefensePrompt then
      UI.ShowPlayerDefensePrompt(requestId)
    end

  elseif msgType == ((Protocol and Protocol.TYPES and Protocol.TYPES.MJ_MOB_SYNC_RESET) or "MJ_MOB_SYNC_RESET") then
    reset_synced_mob_state(parsed.syncId, parsed.sender, parsed.timestamp, parsed.activeMobId, parsed.expectedCount)

  elseif msgType == ((Protocol and Protocol.TYPES and Protocol.TYPES.MJ_MOB_SYNC_ENTRY) or "MJ_MOB_SYNC_ENTRY") then
    add_synced_mob_entry(parsed.syncId, parsed.sender, parsed.mobId, parsed.mobName, parsed.isSupport, parsed.isActive)

  elseif msgType == ((Protocol and Protocol.TYPES and Protocol.TYPES.MJ_MOB_SYNC_DONE) or "MJ_MOB_SYNC_DONE") then
    finalize_synced_mob_state(parsed.syncId, parsed.sender, parsed.timestamp, parsed.receivedCount)

  elseif msgType == ((Protocol and Protocol.TYPES and Protocol.TYPES.MJ_ATTACK_RESOLVE) or "MJ_ATTACK_RESOLVE") then
    local resultText = parsed.resultText
    if resultText and resultText ~= "" then
      print_resolution_for_local_context(resultText)
      record_action_history({
        kind = "mj_attack_result",
        actor = parsed.sender,
        resultText = resultText,
      })
    end
  end
end

-- -----------------------------------------------------------------------------
-- Historique des rolls et pipeline de resolution des combats
-- -----------------------------------------------------------------------------

local ROLL_BUFFER_MAX = 20
local ROLL_BUFFER_EXPIRY = 15

local function add_roll_to_buffer(roller, roll, rMin, rMax)
  if CombatSessionLogic and CombatSessionLogic.add_roll then
    CombatSessionLogic.add_roll(COMBAT_SESSION, roller, roll, rMin, rMax, GetTime(), ROLL_BUFFER_MAX)
    return
  end
  table.insert(UI.rollBuffer, 1, {
    roller = roller,
    roll = roll,
    min = rMin,
    max = rMax,
    time = GetTime(),
  })
  while #UI.rollBuffer > ROLL_BUFFER_MAX do
    table.remove(UI.rollBuffer)
  end
end

local function find_roll_in_buffer(rollerName, rMin, rMax, afterTime)
  if CombatSessionLogic and CombatSessionLogic.find_roll then
    return CombatSessionLogic.find_roll(
      COMBAT_SESSION,
      rollerName,
      rMin,
      rMax,
      afterTime,
      GetTime(),
      ROLL_BUFFER_EXPIRY,
      function(name)
        return Ambiguate(tostring(name), "short")
      end
    )
  end
  local now = GetTime()
  for i = 1, #UI.rollBuffer do
    local entry = UI.rollBuffer[i]
    if entry.roller and entry.min == rMin and entry.max == rMax
       and (now - entry.time) < ROLL_BUFFER_EXPIRY
       and entry.time >= (afterTime or 0) then
      local shortName = Ambiguate(tostring(entry.roller), "short")
      if shortName == rollerName or entry.roller == rollerName then
        return entry
      end
    end
  end
  return nil
end

UI.pendingResolutions = COMBAT_SESSION.pendingResolutions

function UI.StartResolution(requestId, defenderRandType, defMin, defMax)
  if CombatSessionLogic and CombatSessionLogic.start_mj_resolution then
    CombatSessionLogic.start_mj_resolution(
      COMBAT_SESSION,
      requestId,
      STATE,
      defenderRandType,
      defMin,
      defMax,
      GetTime(),
      UnitName("player") or "MJ",
      function(name)
        return Ambiguate(tostring(name), "short")
      end
    )
    return
  end
end

function UI.ComputeResolution(attackRoll, defendRoll, critOff, critDef)
  if ResolutionLogic and ResolutionLogic.compute then
    return ResolutionLogic.compute(attackRoll, defendRoll, critOff, critDef)
  end
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

extract_bonus_from_label = function(text)
  if ResolutionLogic and ResolutionLogic.extract_bonus_from_label then
    return ResolutionLogic.extract_bonus_from_label(text)
  end
  local raw = tostring(text or "")
  local bonus = string.match(raw, "%(([%+%-]%d+)%)")
  return tonumber(bonus) or 0
end

strip_bonus_from_rand_name = function(text)
  local raw = tostring(text or "")
  raw = string.gsub(raw, "%s*%([%+%-]%d+%)%s*$", "")
  raw = string.gsub(raw, "^%s+", "")
  raw = string.gsub(raw, "%s+$", "")
  return raw
end

infer_rand_role_from_name = function(text)
  local raw = strip_bonus_from_rand_name and strip_bonus_from_rand_name(text) or tostring(text or "")
  raw = string.lower(raw)
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

normalize_rand_role = function(value, fallbackName)
  local key = string.lower(tostring(value or ""))
  key = string.gsub(key, "^%s+", "")
  key = string.gsub(key, "%s+$", "")
  if key == "offensive" or key == "support" or key == "defensive" then
    return key
  end
  if infer_rand_role_from_name then
    return infer_rand_role_from_name(fallbackName)
  end
  return "offensive"
end

local function get_defense_rand_name(defenderRandType)
  if MJLogic and MJLogic.get_defense_rand_name then
    return MJLogic.get_defense_rand_name(defenderRandType)
  end
  return "Esquive"
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

function UI.FormatResolutionText(attacker, mobName, attackRoll, defendRoll, attackTotal, defendTotal, hit, diff, critCount, defCritCount, attackReason, defenseReason)
  if ResolutionLogic and ResolutionLogic.format_text then
    return ResolutionLogic.format_text(attacker, mobName, attackRoll, defendRoll, attackTotal, defendTotal, hit, diff, critCount, defCritCount, attackReason, defenseReason)
  end
  local result = hit and "TOUCHÉ" or "ÉCHOUÉ"
  local sign = diff > 0 and "+" or ""
  local atkSegment = format_roll_segment(attackRoll, attackTotal)
  local defSegment = format_roll_segment(defendRoll, defendTotal)

  local text = string.format("Résolution: %s attaque %s : %s vs %s => %s (diff %s%d)",
    attacker, (mobName ~= "" and mobName or "Mob"), atkSegment, defSegment, result, sign, diff)

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

function UI.AnnounceResolution(text)
  if not text or text == "" then return end
  if STATE and STATE.resolution_private_print then
    print_resolution_for_local_context(text)
    return
  end
  if STATE and STATE.raid_announce and IsInRaid() then
    ---@diagnostic disable-next-line:deprecated
    SendChatMessage(escape_chat_message(text), "RAID")
  elseif STATE and STATE.raid_announce and IsInGroup() then
    ---@diagnostic disable-next-line:deprecated
    SendChatMessage(escape_chat_message(text), "PARTY")
  else
    print_resolution_for_local_context(text)
  end
end

function UI.SendResolutionAddonMessage(requestId, text)
  local channel = get_addon_send_channel()
  if not channel then return end
  local mjName = UnitName("player") or "MJ"
  local msg = nil
  if Protocol and Protocol.build_rand_resolve then
    msg = Protocol.build_rand_resolve(requestId, mjName, text, GetTime())
  else
    msg = "RAND_RESOLVE|" .. requestId .. "|" .. mjName .. "|" .. text .. "|" .. tostring(GetTime())
  end
  C_ChatInfo.SendAddonMessage(ADDON_CHANNEL, msg, channel)
end

function UI.SendPlayerDefenseResolutionAddonMessage(requestId, text)
  local channel = get_addon_send_channel()
  if not channel then return end
  local defenderName = UnitName("player") or "Player"
  local msg = nil
  if Protocol and Protocol.build_mj_attack_resolve then
    msg = Protocol.build_mj_attack_resolve(requestId, defenderName, text, GetTime())
  else
    msg = "MJ_ATTACK_RESOLVE|" .. requestId .. "|" .. defenderName .. "|" .. text .. "|" .. tostring(GetTime())
  end
  C_ChatInfo.SendAddonMessage(ADDON_CHANNEL, msg, channel)
end

local function send_private_resolution_addon_message(msgType, requestId, senderName, text, targetA, targetB)
  local senderShort = Ambiguate(tostring(UnitName("player") or ""), "short")
  local msg = nil
  if Protocol and Protocol.build_rand_resolve and Protocol.build_mj_attack_resolve then
    if msgType == ((Protocol.TYPES and Protocol.TYPES.MJ_ATTACK_RESOLVE) or "MJ_ATTACK_RESOLVE") then
      msg = Protocol.build_mj_attack_resolve(requestId, senderName, text, GetTime())
    else
      msg = Protocol.build_rand_resolve(requestId, senderName, text, GetTime())
    end
  else
    msg = msgType .. "|" .. requestId .. "|" .. tostring(senderName or "") .. "|" .. tostring(text or "") .. "|" .. tostring(GetTime())
  end
  local sent = {}

  local function send_to(target)
    local raw = tostring(target or "")
    raw = string.gsub(raw, "^%s+", "")
    raw = string.gsub(raw, "%s+$", "")
    if raw == "" then
      return
    end

    local short = Ambiguate(raw, "short")
    if short == "" then
      return
    end
    if short == senderShort then
      return
    end
    if sent[short] then
      return
    end

    sent[short] = true
    C_ChatInfo.SendAddonMessage(ADDON_CHANNEL, msg, "WHISPER", raw)
  end

  send_to(targetA)
  send_to(targetB)
end

function UI.TryResolve(requestId)
  local res = UI.pendingResolutions[requestId]
  if not res then return end
  if not res.attackerRoll or not res.defenderRoll then return end

  local requestData = UI.pendingMJRequests[requestId]

  local critOff = res.attackerCritOff
  if critOff == nil then
    critOff = STATE and STATE.crit_off_success or nil
  end
  local critDef = res.defenderCritDef
  local critDefReason = nil
  local attackRandName = (requestData and requestData.randName) or ""
  local attackerBonus = extract_bonus_from_label(attackRandName)
  local attackerReason = requestData and requestData.attackerReason or nil
  if (not attackerReason or attackerReason == "") and UI.Buffs and UI.Buffs.GetBonusSourceText and attackerBonus ~= 0 then
    local sourceText = UI.Buffs.GetBonusSourceText(strip_bonus_from_rand_name(attackRandName))
    if sourceText and sourceText ~= "" then
      attackerReason = string.format("%s: %s", attackerBonus > 0 and "Bonus" or "Malus", sourceText)
    end
  end
  if requestData and requestData.isBehindAttack and res.defenderRandType == "DODGE" then
    attackerReason = append_reason_segment(attackerReason, L_get("mj_attack_back"))
  end
  local defenderBonus = 0
  local attackTotal = (res.attackerRoll.roll or 0) + attackerBonus
  local defendTotal = (res.defenderRoll.roll or 0) + defenderBonus

  if res.defenderRandType == "DODGE" and requestData and requestData.isBehindAttack then
    local dodgeBackPercent = clamp_percent(res.defenderDodgeBackPercent, 50)
    defendTotal = math.floor(defendTotal * dodgeBackPercent / 100)
  end

  local hit, diff, critCount, defCritCount = UI.ComputeResolution(
    attackTotal, defendTotal, critOff, critDef)
  local text = UI.FormatResolutionText(
    res.attacker, res.mobName,
    res.attackerRoll.roll, res.defenderRoll.roll,
    attackTotal, defendTotal,
    hit, diff, critCount, defCritCount,
    attackerReason, critDefReason)

  UI.AnnounceResolution(text)
  if STATE and STATE.resolution_private_print then
    local mjName = UnitName("player") or "MJ"
    send_private_resolution_addon_message("RAND_RESOLVE", requestId, mjName, text, res.attacker, res.defender)
  else
    UI.SendResolutionAddonMessage(requestId, text)
  end

  record_action_history({
    kind = "mj_resolution",
    actor = res.attacker,
    target = res.defender,
    mobName = res.mobName,
    randName = attackRandName,
    attackRoll = res.attackerRoll.roll,
    defendRoll = res.defenderRoll.roll,
    attackTotal = attackTotal,
    defendTotal = defendTotal,
    resultText = text,
    isBehindAttack = requestData and requestData.isBehindAttack and true or false,
    replay = requestData and {
      kind = "rand_request",
      sender = requestData.sender,
      randName = requestData.randName,
      min = requestData.min,
      max = requestData.max,
      attackerCritOff = requestData.attackerCritOff,
      attackerCritDef = requestData.attackerCritDef,
      attackerReason = requestData.attackerReason,
      mobName = requestData.mobName,
      mobSyncId = requestData.mobSyncId,
      mobId = requestData.mobId,
      isBehindAttack = requestData.isBehindAttack,
    } or nil,
  })

  UI.pendingResolutions[requestId] = nil
  UI.pendingMJRequests[requestId] = nil
end

function UI.GetPlayerDefenseRange(defenderRandType)
  local lookup = get_defense_rand_name(defenderRandType)
  local _, eMin, eMax = UI.FindDefaultRandByName(lookup)
  if not eMin or not eMax then
    return 1, 100
  end
  return eMin, eMax
end

function UI.StartPlayerDefenseResolution(requestId, defenderRandType, defMin, defMax)
  if CombatSessionLogic and CombatSessionLogic.start_player_defense_resolution then
    CombatSessionLogic.start_player_defense_resolution(
      COMBAT_SESSION,
      requestId,
      STATE,
      defenderRandType,
      defMin,
      defMax,
      GetTime(),
      UnitName("player") or "Player",
      function(name)
        return Ambiguate(tostring(name), "short")
      end
    )
    return
  end
end

function UI.TryResolvePlayerDefense(requestId)
  local res = UI.pendingPlayerResolutions[requestId]
  if not res then return end
  if not res.attackerRoll or not res.defenderRoll then return end

  local critOff = res.attackerCritOff
  local critDef = res.defenderCritDef
  critDef = select(1, get_adjusted_crit_threshold("crit_def_success", critDef)) or critDef
  local attackerBonus = 0
  local defenderBonus = 0
  local defenderReason = nil
  if UI.Buffs and UI.Buffs.GetTotalBonusForRand then
    local defenseRandName = get_defense_rand_name(res.defenderRandType)
    local totalBonus = UI.Buffs.GetTotalBonusForRand(defenseRandName)
    defenderBonus = tonumber(totalBonus) or 0
    if UI.Buffs.GetBonusSourceText then
      local sourceText = UI.Buffs.GetBonusSourceText(defenseRandName)
      if sourceText and sourceText ~= "" and defenderBonus ~= 0 then
        defenderReason = string.format("%s: %s", defenderBonus > 0 and "Bonus" or "Malus", sourceText)
      end
    end
  end

  local attackTotal = (res.attackerRoll.roll or 0) + attackerBonus
  local defendTotal = (res.defenderRoll.roll or 0) + defenderBonus

  if res.defenderRandType == "DODGE" and res.isBehindAttack then
    local dodgeBackPercent = clamp_percent(STATE and STATE.dodge_back_percent, 50)
    defendTotal = math.floor(defendTotal * dodgeBackPercent / 100)
    defenderReason = append_reason_segment(defenderReason, string.format("Esquive de dos %d%%", dodgeBackPercent))
  end

  local hit, diff, critCount, defCritCount = UI.ComputeResolution(
    attackTotal, defendTotal, critOff, critDef)

  local attackerName = (res.mobName and res.mobName ~= "") and res.mobName or (res.attacker or "Mob")
  local text = UI.FormatResolutionText(
    attackerName, res.defender,
    res.attackerRoll.roll, res.defenderRoll.roll,
    attackTotal, defendTotal,
    hit, diff, critCount, defCritCount,
    nil, defenderReason)

  UI.AnnounceResolution(text)
  if STATE and STATE.resolution_private_print then
    local defenderName = UnitName("player") or "Player"
    send_private_resolution_addon_message("MJ_ATTACK_RESOLVE", requestId, defenderName, text, res.attacker, res.defender)
  else
    UI.SendPlayerDefenseResolutionAddonMessage(requestId, text)
  end

  UI.pendingPlayerResolutions[requestId] = nil
  UI.pendingPlayerDefenseRequests[requestId] = nil
end

function UI.ReplayActionHistoryEntry(entry)
  local replay = entry and entry.replay
  if type(replay) ~= "table" then
    return false
  end

  if replay.kind == "rand_request" then
    local sender = tostring(replay.sender or "Player")
    local requestId = nil
    if CombatSessionLogic and CombatSessionLogic.next_rand_request_id then
      requestId = CombatSessionLogic.next_rand_request_id(COMBAT_SESSION, sender)
    else
      COMBAT_SESSION.mjRequestCounter = (tonumber(COMBAT_SESSION.mjRequestCounter) or 0) + 1
      requestId = tostring(sender) .. "_" .. tostring(COMBAT_SESSION.mjRequestCounter)
    end

    UI.pendingMJRequests[requestId] = {
      id = requestId,
      sender = sender,
      randName = replay.randName,
      min = replay.min,
      max = replay.max,
      attackerCritOff = replay.attackerCritOff,
      attackerCritDef = replay.attackerCritDef,
      attackerReason = replay.attackerReason,
      mobName = replay.mobName,
      mobSyncId = replay.mobSyncId,
      mobId = replay.mobId,
      isBehindAttack = replay.isBehindAttack and true or false,
      time = GetTime(),
      selectedMobId = resolve_pending_request_selected_mob_id(STATE, replay.mobId, replay.mobName),
    }
    if UI.ShowMJNotification then
      UI.ShowMJNotification(requestId)
    end
    return true
  end

  if replay.kind == "mj_attack_request" then
    local requestId = UI.SendMJAttackRequest(
      replay.target,
      replay.attackType,
      replay.min,
      replay.max,
      replay.mobName,
      replay.critOff,
      replay.critDef,
      replay.isBehindAttack
    )
    if requestId then
      RandomRoll(replay.min, replay.max)
      return true
    end
  end

  return false
end

-- -----------------------------------------------------------------------------
-- Ecoute et traitement des rolls en temps reel
-- -----------------------------------------------------------------------------
local mjRollListenerFrame = CreateFrame("Frame")
mjRollListenerFrame:RegisterEvent("CHAT_MSG_SYSTEM")
mjRollListenerFrame:SetScript("OnEvent", function(_, _, message)
  local roller, roll, rMin, rMax = parse_roll_message(message)
  if not roller then return end

  add_roll_to_buffer(roller, roll, rMin, rMax)

  local shortRoller = Ambiguate(tostring(roller), "short")
  local myName = Ambiguate(UnitName("player") or "", "short")

  if STATE and STATE.mj_enabled then
    for requestId, res in pairs(UI.pendingResolutions) do
      if not res.attackerRoll then
        local attackerShort = Ambiguate(tostring(res.attacker or ""), "short")
        if shortRoller == attackerShort and rMin == res.attackerMin and rMax == res.attackerMax then
          res.attackerRoll = { roller = roller, roll = roll, min = rMin, max = rMax }
          UI.TryResolve(requestId)
        end
      end
      if not res.defenderRoll then
        if shortRoller == myName and rMin == res.defenderMin and rMax == res.defenderMax then
          res.defenderRoll = { roller = roller, roll = roll, min = rMin, max = rMax }
          UI.TryResolve(requestId)
        end
      end
    end
  end

  for requestId, res in pairs(UI.pendingPlayerResolutions) do
    if not res.attackerRoll then
      local attackerShort = Ambiguate(tostring(res.attacker or ""), "short")
      if shortRoller == attackerShort and rMin == res.attackerMin and rMax == res.attackerMax then
        res.attackerRoll = { roller = roller, roll = roll, min = rMin, max = rMax }
        UI.TryResolvePlayerDefense(requestId)
      end
    end
    if not res.defenderRoll then
      if shortRoller == myName and rMin == res.defenderMin and rMax == res.defenderMax then
        res.defenderRoll = { roller = roller, roll = roll, min = rMin, max = rMax }
        UI.TryResolvePlayerDefense(requestId)
      end
    end
  end
end)

-- -----------------------------------------------------------------------------
-- Modale contextuelle de defense joueur
-- -----------------------------------------------------------------------------
function UI.ShowPlayerDefensePrompt(requestId)
  local req = UI.pendingPlayerDefenseRequests[requestId]
  if not req then return end
  local StdUi = INTERNALS.get_std_ui and INTERNALS.get_std_ui() or nil
  if not StdUi then return end

  if not UI.PLAYER_DEFENSE_MODAL then
    -- Modale de reaction defensive cote joueur lorsqu'une attaque MJ est recue.
    -- Priorite: affichage immediat et lecture claire pour une reponse rapide.
    local modal = create_themed_draggable_modal(
      "EasySanalunePlayerDefenseModal",
      390,
      180,
      220,
      "player_defense_modal",
      true
    )

    local title = modal:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", modal, "TOP", 0, -12)
    title:SetText(L_get("ui_player_defense_modal_title"))
    style_font_string(title, true)
    modal.title = title

    local info = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    info:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -40)
    info:SetWidth(360)
    info:SetJustifyH("LEFT")
    info:SetJustifyV("TOP")
    info:SetText("")
    style_font_string(info)
    modal.info = info

    local btnDefPhys = StdUi:Button(modal, 112, 22, L_get("ui_player_defense_btn_def_phy"))
    btnDefPhys:SetPoint("BOTTOMLEFT", modal, "BOTTOMLEFT", 14, 16)
    apply_button_theme(btnDefPhys, true)

    local btnDefMag = StdUi:Button(modal, 112, 22, L_get("ui_player_defense_btn_def_mag"))
    btnDefMag:SetPoint("LEFT", btnDefPhys, "RIGHT", 6, 0)
    apply_button_theme(btnDefMag)

    local btnDodge = StdUi:Button(modal, 112, 22, L_get("ui_player_defense_btn_dodge"))
    btnDodge:SetPoint("LEFT", btnDefMag, "RIGHT", 6, 0)
    apply_button_theme(btnDodge)

    local function answer(defType)
      local reqId = modal.currentRequestId
      if not reqId then return end
      local minV, maxV = UI.GetPlayerDefenseRange(defType)
      UI.StartPlayerDefenseResolution(reqId, defType, minV, maxV)
      RandomRoll(minV, maxV)
      modal:Hide()
    end

    btnDefPhys:SetScript("OnClick", function() answer("PHY_DEF") end)
    btnDefMag:SetScript("OnClick", function() answer("MAG_DEF") end)
    btnDodge:SetScript("OnClick", function() answer("DODGE") end)

    UI.PLAYER_DEFENSE_MODAL = modal
  end

  local attackerName = (req.mobName and req.mobName ~= "") and req.mobName or (req.attacker or "Mob")
  UI.PLAYER_DEFENSE_MODAL.currentRequestId = requestId
  UI.PLAYER_DEFENSE_MODAL.info:SetText(L_get(
    "ui_player_defense_modal_info",
    attackerName,
    req.min or 1,
    req.max or 100,
    req.isBehindAttack and (" - " .. L_get("mj_attack_back")) or ""
  ))
  apply_modal_position(UI.PLAYER_DEFENSE_MODAL, "player_defense_modal")
  UI.PLAYER_DEFENSE_MODAL:Show()
end

function UI.ShowOffensiveMobPrompt(payload)
  local StdUi = INTERNALS.get_std_ui and INTERNALS.get_std_ui() or nil
  if not StdUi or type(payload) ~= "table" then return end

  if not UI.OFFENSIVE_MOB_MODAL then
    local modal = create_themed_draggable_modal(
      "EasySanaluneOffensiveMobModal",
      390,
      320,
      220,
      "offensive_mob_modal",
      true
    )

    local title = modal:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", modal, "TOP", 0, -12)
    title:SetText(L_get("mj_player_prompt_title"))
    style_font_string(title, true)

    local sourceText = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sourceText:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -38)
    sourceText:SetWidth(360)
    sourceText:SetJustifyH("LEFT")
    style_font_string(sourceText)
    modal.sourceText = sourceText

    local mobLabel = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    mobLabel:SetPoint("TOPLEFT", sourceText, "BOTTOMLEFT", 0, -8)
    mobLabel:SetText(L_get("mj_player_prompt_mob"))
    style_font_string(mobLabel, true)

    local scroll = StdUi:ScrollFrame(modal, 360, 160)
    scroll:SetPoint("TOPLEFT", mobLabel, "BOTTOMLEFT", 0, -4)
    apply_scrollbar_theme(scroll)
    modal.mobScroll = scroll
    modal.mobRows = {}

    local backCheck = StdUi:Checkbox(modal, L_get("mj_attack_back"))
    backCheck:SetPoint("TOPLEFT", scroll, "BOTTOMLEFT", 0, -10)
    if INTERNALS.apply_checkbox_theme then
      INTERNALS.apply_checkbox_theme(backCheck)
    end
    modal.backCheck = backCheck

    local btnCancel = StdUi:Button(modal, 110, 22, L_get("common_cancel"))
    btnCancel:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -14, 14)
    apply_button_theme(btnCancel)
    btnCancel:SetScript("OnClick", function()
      modal:Hide()
    end)

    local btnConfirm = StdUi:Button(modal, 110, 22, L_get("mj_player_prompt_confirm"))
    btnConfirm:SetPoint("RIGHT", btnCancel, "LEFT", -8, 0)
    apply_button_theme(btnConfirm, true)
    btnConfirm:SetScript("OnClick", function()
      local selectedMob = modal.selectedMobData
      local currentPayload = modal.payload
      local syncedState = UI.GetSyncedMobState and UI.GetSyncedMobState() or UI.syncedMobState
      if not currentPayload or not selectedMob then
        L_print("mj_player_prompt_no_mobs")
        return
      end

      local requestId = UI.SendRandRequest(
        currentPayload.min,
        currentPayload.max,
        currentPayload.randName,
        currentPayload.randInfo,
        currentPayload.randRole,
        selectedMob.name,
        selectedMob.id,
        syncedState and syncedState.syncId or "",
        modal.backCheck and modal.backCheck:GetChecked() and true or false,
        true
      )
      if requestId then
        RandomRoll(currentPayload.min, currentPayload.max)
        modal:Hide()
      end
    end)

    UI.OFFENSIVE_MOB_MODAL = modal
  end

  local modal = UI.OFFENSIVE_MOB_MODAL
  modal.payload = payload
  modal.selectedMobData = nil

  local syncedState = UI.GetSyncedMobState and UI.GetSyncedMobState() or UI.syncedMobState
  if modal.sourceText then
    local senderName = syncedState and tostring(syncedState.sender or "") or ""
    if senderName ~= "" then
      modal.sourceText:SetText(L_get("mj_player_prompt_source", senderName))
    else
      modal.sourceText:SetText("")
    end
  end

  local entries = UI.GetSyncedMobEntries and UI.GetSyncedMobEntries() or {}
  local content = modal.mobScroll and modal.mobScroll.scrollChild
  if not content then return end

  local children = { content:GetChildren() }
  for i = 1, #children do
    children[i]:Hide()
    children[i]:SetParent(nil)
  end
  modal.mobRows = {}

  local yOffset = 0
  for i = 1, #entries do
    local mob = entries[i]
    local row = CreateFrame("Button", nil, content, "BackdropTemplate")
    row:SetSize(340, 26)
    row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
    row:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Buttons\\WHITE8X8",
      edgeSize = 1,
      insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    row:SetBackdropColor(0.08, 0.13, 0.23, 0.92)
    row:SetBackdropBorderColor(0.86, 0.80, 0.62, 0.7)

    local nameFs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameFs:SetPoint("LEFT", row, "LEFT", 8, 0)
    nameFs:SetText(mob.isSupport and (tostring(mob.name or "Mob") .. " |cff8ad7ff[" .. L_get("mj_support_tag") .. "]|r") or tostring(mob.name or "Mob"))
    nameFs:SetTextColor(0.95, 0.95, 0.95)

    row:SetScript("OnClick", function(self)
      modal.selectedMobData = mob
      for j = 1, #modal.mobRows do
        local other = modal.mobRows[j]
        other:SetBackdropColor(0.08, 0.13, 0.23, 0.92)
      end
      self:SetBackdropColor(0.12, 0.20, 0.34, 0.95)
    end)

    modal.mobRows[#modal.mobRows + 1] = row
    yOffset = yOffset - 28
  end

  if not modal.selectedMobData and entries[1] and modal.mobRows[1] then
    modal.selectedMobData = entries[1]
    modal.mobRows[1]:SetBackdropColor(0.12, 0.20, 0.34, 0.95)
  end

  if #entries == 0 then
    local emptyFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    emptyFs:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -8)
    emptyFs:SetText(L_get("mj_player_prompt_no_mobs"))
    style_font_string(emptyFs)
    yOffset = -28
  end

  content:SetHeight(math.max(40, -yOffset + 8))
  if modal.backCheck then
    modal.backCheck:SetChecked(false)
  end
  apply_modal_position(modal, "offensive_mob_modal")
  modal:Show()
end

-- -----------------------------------------------------------------------------
-- Outils divers (recherche / export de profil)
-- -----------------------------------------------------------------------------
-- Retrouve un rand par defaut a partir de son nom dans CHARS.
function UI.FindDefaultRandByName(name)
  if not STATE or not STATE.CHARS then return nil end
  local lowerName = string.lower(tostring(name or ""))
  for i = 1, #STATE.CHARS do
    local entry = STATE.CHARS[i]
    if entry and entry.type == "section" and entry.items then
      for j = 1, #entry.items do
        local item = entry.items[j]
        if item and string.lower(tostring(item.name or "")) == lowerName then
          local eMin, eMax = parse_command(item.command)
          return item, eMin, eMax
        end
      end
    elseif entry and string.lower(tostring(entry.name or "")) == lowerName then
      local eMin, eMax = parse_command(entry.command)
      return entry, eMin, eMax
    end
  end
  return nil
end

-- -----------------------------------------------------------------------------
-- Export et serialisation de profil
-- -----------------------------------------------------------------------------
function UI.SerializeProfile()
  if MJLogic and MJLogic.serialize_profile then
    return MJLogic.serialize_profile(STATE)
  end
  return ""
end

function UI.DeserializeProfile(text)
  if MJLogic and MJLogic.deserialize_profile then
    return MJLogic.deserialize_profile(text)
  end
  return nil
end

local function trim_profile_import_text(value)
  local raw = tostring(value or "")
  raw = string.gsub(raw, "^%s+", "")
  raw = string.gsub(raw, "%s+$", "")
  return raw
end

local function normalize_profile_import_name(value)
  local raw = trim_profile_import_text(value)
  if Core and Core.Text and Core.Text.normalize_name then
    return Core.Text.normalize_name(raw)
  end
  raw = string.lower(raw)
  raw = string.gsub(raw, "[éèêë]", "e")
  raw = string.gsub(raw, "[àâä]", "a")
  raw = string.gsub(raw, "[îï]", "i")
  raw = string.gsub(raw, "[ôö]", "o")
  raw = string.gsub(raw, "[ùûü]", "u")
  raw = string.gsub(raw, "[^%w%s]", "")
  raw = string.gsub(raw, "%s+", " ")
  raw = string.gsub(raw, "^%s+", "")
  raw = string.gsub(raw, "%s+$", "")
  return raw
end

local function make_unique_import_profile_name(baseName)
  local candidate = trim_profile_import_text(baseName)
  if candidate == "" then
    candidate = L_get("ui_import_default_name")
  end

  local normalizedCandidate = normalize_profile_import_name(candidate)
  local profiles = STATE and STATE.profiles or {}
  local exists = false
  for i = 1, #profiles do
    if normalize_profile_import_name(profiles[i]) == normalizedCandidate then
      exists = true
      break
    end
  end
  if not exists then
    return candidate
  end

  local suffix = 2
  while true do
    local nextCandidate = string.format("%s (%d)", candidate, suffix)
    local found = false
    for i = 1, #profiles do
      if normalize_profile_import_name(profiles[i]) == normalize_profile_import_name(nextCandidate) then
        found = true
        break
      end
    end
    if not found then
      return nextCandidate
    end
    suffix = suffix + 1
  end
end

local function build_imported_profile_chars(parsed)
  if type(parsed and parsed.chars) == "table" and #parsed.chars > 0 then
    local structuredChars = deep_clone_chars(parsed.chars)
    if type(structuredChars) ~= "table" then
      structuredChars = {}
    end
    normalize_chars(structuredChars)
    return structuredChars
  end

  local chars = deep_clone_chars(StateLib and StateLib.DEF_STATE and StateLib.DEF_STATE.CHARS or {})
  if type(chars) ~= "table" then
    chars = {}
  end

  local basicSection = nil
  for i = 1, #chars do
    local entry = chars[i]
    if entry and entry.type == "section" and entry.is_fixed then
      basicSection = entry
      break
    end
  end
  if not basicSection then
    basicSection = {
      type = "section",
      name = "Fiche basique",
      is_fixed = true,
      expanded = true,
      items = {},
    }
    table.insert(chars, 1, basicSection)
  end
  if type(basicSection.items) ~= "table" then
    basicSection.items = {}
  end

  local basicByName = {}
  for i = 1, #basicSection.items do
    local item = basicSection.items[i]
    if item then
      basicByName[normalize_profile_import_name(item.name)] = item
    end
  end

  for i = 1, #(parsed and parsed.rands or {}) do
    local imported = parsed.rands[i]
    local randName = trim_profile_import_text(imported and imported.name or "")
    local randCommand = trim_profile_import_text(imported and imported.command or "")
    if randName ~= "" then
      if randCommand == "" then
        randCommand = "1-100"
      end

      local existing = basicByName[normalize_profile_import_name(randName)]
      if existing then
        existing.name = randName
        existing.info = randCommand
        existing.command = randCommand
      else
        chars[#chars + 1] = {
          type = "rand",
          name = randName,
          info = randCommand,
          command = randCommand,
          is_default = false,
        }
      end
    end
  end

  normalize_chars(chars)
  return chars
end

local function build_imported_profile_buffs(parsed)
  local importedBuffs = parsed and parsed.buffs or nil
  if type(importedBuffs) ~= "table" then
    return {}
  end

  local result = {}
  for i = 1, #importedBuffs do
    local section = importedBuffs[i]
    if type(section) == "table" and section.type == "section" then
      local clonedSection = {
        type = "section",
        name = trim_profile_import_text(section.name),
        is_fixed = section.is_fixed and true or false,
        expanded = section.expanded ~= false,
        items = {},
      }
      if clonedSection.name == "" then
        clonedSection.name = clonedSection.is_fixed and "Buffs" or ("Categorie " .. tostring(i))
      end

      local items = type(section.items) == "table" and section.items or {}
      for j = 1, #items do
        local entry = items[j]
        if type(entry) == "table" and entry.type ~= "section" then
          local clonedEntry = {
            title = trim_profile_import_text(entry.title),
            stat = trim_profile_import_text(entry.stat),
            value = tonumber(entry.value) or 0,
            active = entry.active ~= false,
          }

          if type(entry.stats) == "table" and #entry.stats > 0 then
            clonedEntry.stats = {}
            for k = 1, #entry.stats do
              local statKey = trim_profile_import_text(entry.stats[k])
              if statKey ~= "" then
                clonedEntry.stats[#clonedEntry.stats + 1] = statKey
              end
            end
          end

          if type(entry.values) == "table" then
            clonedEntry.values = {}
            for key, value in pairs(entry.values) do
              local statKey = trim_profile_import_text(key)
              if statKey ~= "" then
                clonedEntry.values[statKey] = tonumber(value) or 0
              end
            end
            if next(clonedEntry.values) == nil then
              clonedEntry.values = nil
            end
          end

          clonedSection.items[#clonedSection.items + 1] = clonedEntry
        end
      end

      result[#result + 1] = clonedSection
    end
  end

  return result
end

function UI.ImportProfileFromSerializedText(text)
  local parsed = UI.DeserializeProfile(text)
  if not parsed then
    L_print("ui_import_invalid")
    return false
  end

  if type(STATE.profiles) ~= "table" or #STATE.profiles == 0 then
    STATE.profiles = { UnitName("player") or L_get("ui_profile_default_name") }
  end
  if type(STATE.profile_chars) ~= "table" then
    STATE.profile_chars = {}
  end
  if type(STATE.profile_buffs) ~= "table" then
    STATE.profile_buffs = {}
  end
  if type(STATE.profile_crit_off_success) ~= "table" then
    STATE.profile_crit_off_success = {}
  end
  if type(STATE.profile_crit_def_success) ~= "table" then
    STATE.profile_crit_def_success = {}
  end
  if type(STATE.profile_crit_off_failure_visual) ~= "table" then
    STATE.profile_crit_off_failure_visual = {}
  end
  if type(STATE.profile_crit_def_failure_visual) ~= "table" then
    STATE.profile_crit_def_failure_visual = {}
  end
  if type(STATE.profile_dodge_back_percent) ~= "table" then
    STATE.profile_dodge_back_percent = {}
  end
  if type(STATE.profile_hit_points) ~= "table" then
    STATE.profile_hit_points = {}
  end
  if type(STATE.profile_armor_type) ~= "table" then
    STATE.profile_armor_type = {}
  end
  if type(STATE.profile_durability_current) ~= "table" then
    STATE.profile_durability_current = {}
  end
  if type(STATE.profile_durability_max) ~= "table" then
    STATE.profile_durability_max = {}
  end
  if type(STATE.profile_durability_infinite) ~= "table" then
    STATE.profile_durability_infinite = {}
  end
  if type(STATE.profile_rda) ~= "table" then
    STATE.profile_rda = {}
  end
  if type(STATE.profile_rda_crit) ~= "table" then
    STATE.profile_rda_crit = {}
  end

  local profileName = make_unique_import_profile_name(parsed.profileName)
  local newIndex = #STATE.profiles + 1
  STATE.profiles[newIndex] = profileName
  STATE.profile_chars[newIndex] = build_imported_profile_chars(parsed)
  STATE.profile_buffs[newIndex] = build_imported_profile_buffs(parsed)
  STATE.profile_crit_off_success[newIndex] = tonumber(parsed.critOff) or DEFAULT_CRIT_THRESHOLD
  STATE.profile_crit_def_success[newIndex] = tonumber(parsed.critDef) or DEFAULT_CRIT_THRESHOLD
  STATE.profile_crit_off_failure_visual[newIndex] = tonumber(parsed.critOffFailureVisual) or 0
  STATE.profile_crit_def_failure_visual[newIndex] = tonumber(parsed.critDefFailureVisual) or 0
  STATE.profile_dodge_back_percent[newIndex] = clamp_percent(parsed.dodgeBackPercent, DEFAULT_DODGE_BACK_PERCENT)
  STATE.profile_hit_points[newIndex] = tonumber(parsed.hitPoints) or DEFAULT_HIT_POINTS
  STATE.profile_armor_type[newIndex] = normalize_armor_type(parsed.armorType)
  STATE.profile_durability_current[newIndex] = tonumber(parsed.durabilityCurrent) or DEFAULT_DURABILITY_MAX
  STATE.profile_durability_max[newIndex] = tonumber(parsed.durabilityMax) or DEFAULT_DURABILITY_MAX
  STATE.profile_durability_infinite[newIndex] = parsed.durabilityInfinite and true or false
  STATE.profile_rda[newIndex] = tonumber(parsed.rda) or 0
  STATE.profile_rda_crit[newIndex] = tonumber(parsed.rdaCrit) or 0

  _G.EASY_SANALUNE_SAVED_STATE = STATE
  if UI.switch_profile then
    UI.switch_profile(newIndex)
  else
    STATE.profile_index = newIndex
    STATE.CHARS = STATE.profile_chars[newIndex]
    STATE.buffs = STATE.profile_buffs[newIndex]
    STATE.crit_off_success = STATE.profile_crit_off_success[newIndex]
    STATE.crit_def_success = STATE.profile_crit_def_success[newIndex]
    STATE.crit_off_failure_visual = STATE.profile_crit_off_failure_visual[newIndex]
    STATE.crit_def_failure_visual = STATE.profile_crit_def_failure_visual[newIndex]
    STATE.dodge_back_percent = STATE.profile_dodge_back_percent[newIndex]
    STATE.hit_points = STATE.profile_hit_points[newIndex]
    STATE.armor_type = STATE.profile_armor_type[newIndex]
    STATE.durability_current = STATE.profile_durability_current[newIndex]
    STATE.durability_max = STATE.profile_durability_max[newIndex]
    STATE.durability_infinite = STATE.profile_durability_infinite[newIndex] and true or false
    STATE.rda = STATE.profile_rda[newIndex]
    STATE.rda_crit = STATE.profile_rda_crit[newIndex]
    normalize_survival_data(STATE)
    normalize_chars(STATE.CHARS)
    if UI.update_profile_label then
      UI.update_profile_label()
    end
    if UI.REFRESH then
      UI.REFRESH()
    end
  end

  L_print("ui_import_success", profileName)
  return true
end

function UI.OpenImportModal()
  local StdUi = INTERNALS.get_std_ui and INTERNALS.get_std_ui() or nil
  if not StdUi then return end
  if not UI.IMPORT_MODAL then
    local modal = create_themed_draggable_modal(
      "EasySanaluneImportModal",
      420,
      280,
      200,
      "import_modal",
      true
    )

    local title = modal:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", modal, "TOP", 0, -12)
    title:SetText(L_get("ui_import_modal_title"))
    style_font_string(title, true)

    local hint = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -36)
    hint:SetText(L_get("ui_import_modal_hint"))
    style_font_string(hint)

    local scroll = StdUi:ScrollFrame(modal, 390, 178)
    scroll:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -56)
    apply_scrollbar_theme(scroll)

    local eb = StdUi:SimpleEditBox(scroll.scrollChild, 380, 500, "")
    eb:SetPoint("TOPLEFT", scroll.scrollChild, "TOPLEFT", 0, 0)
    eb:SetMultiLine(true)
    if eb.SetWordWrap then eb:SetWordWrap(true) end
    apply_editbox_theme(eb)
    modal.importEditBox = eb

    local btnClose = StdUi:Button(modal, 80, 22, L_get("common_close"))
    btnClose:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -14, 14)
    apply_button_theme(btnClose)
    btnClose:SetScript("OnClick", function() modal:Hide() end)

    local btnImport = StdUi:Button(modal, 90, 22, L_get("common_import"))
    btnImport:SetPoint("RIGHT", btnClose, "LEFT", -8, 0)
    apply_button_theme(btnImport, true)
    btnImport:SetScript("OnClick", function()
      if UI.ImportProfileFromSerializedText(modal.importEditBox and modal.importEditBox:GetText() or "") then
        modal:Hide()
      end
    end)

    UI.IMPORT_MODAL = modal
  end
  if UI.IMPORT_MODAL.importEditBox then
    UI.IMPORT_MODAL.importEditBox:SetText("")
  end
  apply_modal_position(UI.IMPORT_MODAL, "import_modal")
  UI.IMPORT_MODAL:Show()
end

function UI.OpenExportModal()
  local StdUi = INTERNALS.get_std_ui and INTERNALS.get_std_ui() or nil
  if not StdUi then return end
  if not UI.EXPORT_MODAL then
    local modal = create_themed_draggable_modal(
      "EasySanaluneExportModal",
      420,
      280,
      200,
      "export_modal",
      true
    )

    local title = modal:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", modal, "TOP", 0, -12)
    title:SetText(L_get("ui_export_modal_title"))
    style_font_string(title, true)

    local hint = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -36)
    hint:SetText(L_get("ui_export_modal_hint"))
    style_font_string(hint)

    local scroll = StdUi:ScrollFrame(modal, 390, 178)
    scroll:SetPoint("TOPLEFT", modal, "TOPLEFT", 14, -56)
    apply_scrollbar_theme(scroll)

    local eb = StdUi:SimpleEditBox(scroll.scrollChild, 380, 500, "")
    eb:SetPoint("TOPLEFT", scroll.scrollChild, "TOPLEFT", 0, 0)
    eb:SetMultiLine(true)
    if eb.SetWordWrap then eb:SetWordWrap(true) end
    apply_editbox_theme(eb)
    modal.exportEditBox = eb

    local btnClose = StdUi:Button(modal, 80, 22, L_get("common_close"))
    btnClose:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -14, 14)
    apply_button_theme(btnClose)
    btnClose:SetScript("OnClick", function() modal:Hide() end)

    UI.EXPORT_MODAL = modal
  end
  UI.EXPORT_MODAL.exportEditBox:SetText(UI.SerializeProfile())
  apply_modal_position(UI.EXPORT_MODAL, "export_modal")
  UI.EXPORT_MODAL:Show()
end

-- Les implementations des modales et du rendu de liste sont deplacees dans:
-- ui/modals.lua
-- ui/list.lua
