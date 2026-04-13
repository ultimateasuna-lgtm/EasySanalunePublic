local Locale = {}
_G.EasySanaluneLocale = Locale

local COLOR_RESET = "|r"
local COLOR_PREFIX_BLUE = "|cff8cc8ff"
local COLOR_SUCCESS_GREEN = "|cff3fd46b"
local COLOR_FAIL_RED = "|cffe35b5b"

local STRINGS = {
  addon_loaded = "EasySanalune chargé.",
  addon_reset_detected = "EasySanalune a été reset",
  addon_not_loaded = "addon pas encore chargé.",
  profile_mode_enabled = "Mode profils activé.",
  profile_mode_disabled = "Mode profils désactivé.",
  profiles_help = "/easy profils pour les options profils, /easy pj pour ouvrir la fenêtre joueur, /easy mj pour ouvrir la fenêtre MJ",

  outcome_invalid = "Résultat invalide (ex: 0 ou 0-30)",
  outcome_text_required = "Le texte d'action est requis",
  outcome_remove_prompt = "Indique la valeur ou plage à supprimer (ex: 0 ou 0-30)",
  outcome_not_found_single = "Aucune issue enregistrée pour %s",
  outcome_not_found_range = "Aucune issue enregistrée pour %s-%s",
  rand_reader_text = "%s",

  crit_threshold_invalid = "%s doit être un entier >= 0",
  hit_points_invalid = "%s doit être un entier >= -2",
  durability_invalid = "%s doit être `∞` ou au format X / Y",
  profile_delete_base_forbidden = "Impossible de supprimer le profil de base",
  rand_delete_default_forbidden = "Impossible de supprimer un rand par defaut",
  section_delete_basic_forbidden = "Impossible de supprimer la categorie Fiche basique",

  rand_name_required = "Le nom est requis",
  rand_format_invalid = "Format rand invalide (ex: 0-100 ou 100-200)",
  section_name_required = "Le nom de catégorie est requis",

  mj_target_required = "Cible joueur requise.",
  mj_target_added = "Cible ajoutée : %s",
  mj_target_removed = "Cible retirée : %s",
  mj_target_remove_missing = "Aucune cible sélectionnée à retirer.",
  mj_group_required = "Tu dois être en groupe/raid pour envoyer la demande.",
  mj_attack_send_failed = "Impossible d'envoyer la demande d'attaque.",
  mj_attack_sent = "%s attaque %s (%d-%d).",
  mj_mob_name_required = "Le nom du mob est requis.",
  mj_no_mob_selected = "Aucun mob sélectionné.",
  mj_import_invalid = "Format invalide — colle un texte exporté par EasySanalune.",
  mj_import_success = "Mob importé : %s",
  mj_import_error = "Erreur lors de l'import.",
  mj_resolution_text = "%s",
  resolution_print_text = "%s",

  common_save = "Enregistrer",
  common_cancel = "Annuler",
  common_delete = "Supprimer",
  common_edit = "Editer",
  common_new = "Nouveau",
  common_confirm = "Confirmer",
  common_close = "Fermer",
  common_import = "Importer",

  buff_stat_all_stats = "Toutes les stats",
  buff_stat_all_offensive = "Ttes les stats offensives",
  buff_stat_all_defensive = "Ttes les stats defensives",
  buff_stat_all_crit_success = "Ttes les réussites crits",
  buff_stat_crit_off_success = "Réussite crit off",
  buff_stat_crit_def_success = "Réussite crit def",
  buff_stat_atk_phy = "Attaque physique",
  buff_stat_atk_mag = "Attaque magique",
  buff_stat_support = "Soutien",
  buff_stat_def_phy = "Defense physique",
  buff_stat_def_mag = "Defense magique",
  buff_stat_dodge = "Esquive",
  buff_modal_title_new = "Nouveau buff/debuff",
  buff_modal_title_edit = "Editer buff/debuff",
  buff_label_title = "Titre:",
  buff_label_value = "Valeur:",
  buff_label_stat = "Stat / rand:",
  buff_label_stats = "Stats / rands:",
  buff_multi_stats_toggle = "Appliquer a plusieurs stats",
  buff_multi_select_count = "%d sélections",
  buff_multi_stats_default_title = "Buff multi-stats",
  buff_tooltip_affected_stats = "Stats touchees :",
  buff_tooltip_status = "Etat :",
  buff_tooltip_status_active = "Actif",
  buff_tooltip_status_inactive = "Inactif",
  buff_empty = "Aucun buff/debuff",
  buff_window_title = "Buffs / Debuffs",
  buff_new_button = "Nouveau buff",
  buff_new_section_button = "Nouvelle categorie",
  buff_section_default_name = "Buffs",
  buff_section_modal_title_new = "Nouvelle categorie de buffs",
  buff_section_modal_title_edit = "Modifier categorie de buffs",

  ui_title = "EasySanalune",
  ui_toggle_raid = "Message raid",
  ui_toggle_rand_reader = "Lire résultat rand",
  ui_current_status_title = "Actuellement",
  ui_label_crit_off_success = "Crit off réussite :",
  ui_label_crit_def_success = "Crit def réussite :",
  ui_label_crit_off_failure_visual = "Crit off échec :",
  ui_label_crit_def_failure_visual = "Crit def échec :",
  ui_label_dodge_back_percent = "Esquive de dos (%) :",
  ui_label_hit_points = "PDV :",
  ui_label_armor_type = "Armure :",
  ui_label_durability = "Durabilité :",
  ui_label_rda = "RDA :",
  ui_label_rda_crit = "RDA critique :",
  ui_armor_type_nue = "Nue",
  ui_armor_type_light = "Légère",
  ui_armor_type_medium = "Intermédiaire",
  ui_armor_type_heavy = "Lourde",
  ui_armor_type_special = "Spéciale",
  ui_reset = "Reset",
  ui_mj = "MJ",
  ui_resolution_private = "Résolution privée",
  ui_mj_window_button = "Fenêtre MJ",
  ui_buffs_button = "Buffs",
  ui_info_button = "Infos",
  ui_info_window_title = "Guide EasySanalune",
  ui_profile_label = "Profil :",
  ui_profile_default_name = "Profil 1",
  ui_profile_rename = "Renommer",
  ui_profile_export = "Exporter",
  ui_import_modal_title = "Importer un profil",
  ui_import_modal_hint = "Colle ici un export EasySanalune (Ctrl+V)",
  ui_import_default_name = "Profil importé",
  ui_import_success = "Profil importé : %s",
  ui_import_invalid = "Format invalide — colle un texte exporté par EasySanalune.",
  ui_profile_modal_new_title = "Nouveau profil",
  ui_profile_modal_rename_title = "Renommer le profil",
  ui_player_defense_modal_title = "Attaque du MJ",
  ui_player_defense_btn_def_phy = "Déf physique",
  ui_player_defense_btn_def_mag = "Déf magique",
  ui_player_defense_btn_dodge = "Esquive",
  ui_player_defense_modal_info = "%s attaque (%d-%d)%s. Choisis ta défense.",
  ui_export_modal_title = "Exporter le profil",
  ui_export_modal_hint = "Sélectionne tout (Ctrl+A) puis copie (Ctrl+C)",
  ui_reset_profile_popup_text = "Réinitialiser ce profil ?\n\n- Supprime les nouvelles catégories\n- Supprime les nouveaux rands\n- Réinitialise Fiche basique (1-100)",
  ui_reset_profile_popup_confirm = "Réinitialiser",
  ui_reset_nothing = "Il n'y a rien à reset sur ce profil.",
  buff_reset_nothing = "Il n'y a aucun buff/debuff à reset.",

  mj_active_badge = "ACTIF",
  mj_active_mob_with_name = "Mob actif : %s",
  mj_active_mob_none = "Mob actif : aucun",
  mj_window_title = "Fenêtre MJ",
  mj_separator_edit = "— Modifier / Créer un mob —",
  mj_label_name = "Nom :",
  mj_label_hit_points = "PDV :",
  mj_label_armor_type = "Armure :",
  mj_label_durability = "Durabilité :",
  mj_label_rda = "RDA :",
  mj_label_rda_crit = "RDA crit :",
  mj_label_notes = "Notes :",
  mj_label_mob_rands = "Rands du mob :",
  mj_label_def_phy = "Déf phys :",
  mj_label_def_mag = "Déf mag :",
  mj_label_dodge = "Esquive :",
  mj_label_dodge_back = "Dos (%) :",
  mj_label_atk_phy = "Atk phys :",
  mj_label_atk_mag = "Atk mag :",
  mj_label_support = "Soutien :",
  mj_label_crit_off = "RCrit off :",
  mj_label_crit_def = "RCrit def :",
  mj_label_ecrit_off = "ECrit off :",
  mj_label_ecrit_def = "ECrit def :",
  mj_import_profile_button = "Importer un profil...",
  mj_attack_section = "Attaque du mob vers joueur :",
  mj_attack_target_none = "Aucun joueur",
  mj_attack_target_add = "Ajouter",
  mj_attack_target_remove = "Retirer",
  mj_attack_target_group_fill = "Ajouter groupe/raid",
  mj_attack_back = "Attaque de dos",
  mj_attack_mob_required = "Sélectionne un mob actif ou renseigne le formulaire du mob avant d'envoyer l'attaque.",
  mj_attack_target_placeholder = "Nom du joueur",
  mj_attack_btn_phy = "Atk phys",
  mj_attack_btn_mag = "Atk mag",
  mj_refresh_mobs_button = "Rafraîchir",
  mj_mobs_sync_sent = "Liste des mobs synchronisée.",
  mj_mobs_sync_failed = "Impossible de synchroniser la liste des mobs.",
  mj_reset_mobs_button = "Reset mobs",
  mj_reset_targets_button = "Reset joueurs",
  mj_reset_mobs_confirm_text = "Réinitialiser tous les mobs MJ actifs ?",
  mj_reset_targets_confirm_text = "Réinitialiser la liste des joueurs cibles ?",
  mj_reset_mobs_nothing = "Il n'y a aucun mob actif à reset.",
  mj_reset_targets_nothing = "Il n'y a aucune cible joueur à reset.",
  mj_new_mob_name = "Nouveau mob",
  mj_pending_requests = "Demandes en attente :",
  mj_history_button = "Historique",
  mj_history_title = "Historique MJ",
  mj_history_empty = "Aucune action récente.",
  mj_history_replay = "Relancer",
  mj_history_replay_failed = "Impossible de relancer cette action.",
  mj_history_replay_success = "Action relancée.",
  mj_sync_missing = "Aucune liste de mobs synchronisée. Demande un rafraîchissement MJ.",
  mj_player_prompt_title = "Choisir le mob attaqué",
  mj_player_prompt_confirm = "Envoyer",
  mj_player_prompt_mob = "Mob :",
  mj_player_prompt_no_mobs = "Aucun mob synchronisé.",
  mj_player_prompt_source = "Source MJ : %s",
  mj_support_tag = "SOUTIEN",
  mj_import_modal_title = "Importer un profil",
  mj_import_modal_hint = "Colle ici le texte exporte par un joueur (Ctrl+V)",
  mj_imported_mob_name = "Mob importé",
  mj_imported_mob_notes = "Importé",

  modal_issues_title = "Issues:",
  modal_issues_none = "Issues: aucune",
  modal_icon_picker_title = "Choisir une icône",
  modal_icon_use = "Utiliser",
  modal_icon_none = "Aucune",
  modal_search = "Recherche :",
  modal_selection = "Sélection :",
  modal_new_rand_title = "Nouveau rand",
  modal_edit_rand_title = "Modifier rand",
  modal_label_name = "Nom :",
  modal_label_info = "Info :",
  modal_label_rand = "Rand :",
  modal_label_rand_role = "Type :",
  rand_role_offensive = "Offensif",
  rand_role_support = "Soutien",
  rand_role_defensive = "Defensif",
  modal_label_icon = "Icône :",
  modal_label_result = "Résultat :",
  modal_label_action = "Action :",
  modal_add_outcome = "Ajouter issue",
  modal_remove_outcome = "Suppr. issue",
  modal_choose = "Choisir",
  modal_create = "Créer",
  modal_new_section_title = "Nouvelle catégorie",
  modal_edit_section_title = "Modifier catégorie",
}

local function color_wrap(color, text)
  return tostring(color or "") .. tostring(text or "") .. COLOR_RESET
end

local function is_mj_key(key)
  return string.match(tostring(key or ""), "^mj_") ~= nil
end

local function resolve_context_is_mj(key, explicitIsMj)
  if type(explicitIsMj) == "boolean" then
    return explicitIsMj
  end
  return is_mj_key(key)
end

local function strip_addon_prefix(text)
  local value = tostring(text or "")
  value = string.gsub(value, "^%s*EasySanalune%s+MJ%s*:%s*", "")
  value = string.gsub(value, "^%s*EasySanalune%s*:%s*", "")
  return value
end

local function colorize_resolution_value(text)
  local value = strip_addon_prefix(text)
  value = string.gsub(value, "TOUCHÉ", color_wrap(COLOR_SUCCESS_GREEN, "TOUCHÉ"))
  value = string.gsub(value, "ÉCHOUÉ", color_wrap(COLOR_FAIL_RED, "ÉCHOUÉ"))
  return value
end

local function build_addon_prefix(isMj)
  local title = isMj and "EasySanalune MJ" or "EasySanalune"
  return color_wrap(COLOR_PREFIX_BLUE, title) .. ": "
end

function Locale.format_resolution_print(text, isMj)
  return build_addon_prefix(isMj) .. colorize_resolution_value(text)
end

function Locale.format_addon_print(key, text, explicitIsMj)
  local mjContext = resolve_context_is_mj(key, explicitIsMj)
  local value = strip_addon_prefix(text)
  if key == "resolution_print_text" or key == "mj_resolution_text" then
    value = colorize_resolution_value(value)
  end
  return build_addon_prefix(mjContext) .. value
end

function Locale.get(key, ...)
  local template = STRINGS[key] or tostring(key)
  if select("#", ...) > 0 then
    return string.format(template, ...)
  end
  return template
end

function Locale.print(key, ...)
  print(Locale.format_addon_print(key, Locale.get(key, ...)))
end

function Locale.print_with_context(key, isMj, ...)
  print(Locale.format_addon_print(key, Locale.get(key, ...), isMj))
end

function Locale.print_text(text)
  print(build_addon_prefix(false) .. strip_addon_prefix(text))
end
