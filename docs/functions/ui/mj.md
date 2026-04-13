# ui/mj.lua

## Resume

Construction des widgets, orchestration des popups et liaison avec l'etat addon.

## Fonctions

### L_get(key, ...)

- Portee: local
- Ligne source: 15
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### L_print(key, ...)

- Portee: local
- Ligne source: 19
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### get_state()

- Portee: local
- Ligne source: 22
- Commentaire source: @return EasySanaluneState|nil

### get_stdui()

- Portee: local
- Ligne source: 24
- Commentaire source: @return any

### apply_panel_theme(w, s, n)

- Portee: local
- Ligne source: 25
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### apply_button_theme(w, p)

- Portee: local
- Ligne source: 26
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### apply_checkbox_theme(w)

- Portee: local
- Ligne source: 27
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### apply_editbox_theme(w)

- Portee: local
- Ligne source: 28
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### apply_scrollbar_theme(w)

- Portee: local
- Ligne source: 29
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### style_font_string(w, a)

- Portee: local
- Ligne source: 30
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### make_modal_draggable(modal, k)

- Portee: local
- Ligne source: 31
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### apply_modal_position(modal, k)

- Portee: local
- Ligne source: 32
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### parse_command(v)

- Portee: local
- Ligne source: 33
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### get_addon_send_channel()

- Portee: local
- Ligne source: 40
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### next_mob_id(state)

- Portee: local
- Ligne source: 52
- Commentaire source: Helpers

### trim(s)

- Portee: local
- Ligne source: 68
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### normalize_armor_type(value)

- Portee: local
- Ligne source: 75
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### fold_accents(s)

- Portee: local
- Ligne source: 82
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### player_name_key(name)

- Portee: local
- Ligne source: 104
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### player_names_equal(a, b)

- Portee: local
- Ligne source: 117
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### collect_group_player_names()

- Portee: local
- Ligne source: 126
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### add_name(n)

- Portee: local
- Ligne source: 130
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### resolve_player_name(inputName, state)

- Portee: local
- Ligne source: 165
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### clear_widget_rows(rows)

- Portee: local
- Ligne source: 192
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### format_session_time(secondsValue)

- Portee: local
- Ligne source: 205
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### build_history_entry_text(entry)

- Portee: local
- Ligne source: 213
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### sanitize_mj_player_targets(state)

- Portee: local
- Ligne source: 264
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### sanitize_mj_selected_target(state, cleanTargets)

- Portee: local
- Ligne source: 289
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### deserialize_profile(text)

- Portee: local
- Ligne source: 360
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### import_as_mob(parsed)

- Portee: local
- Ligne source: 367
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### get_current_mj_form_values()

- Portee: local
- Ligne source: 391
- Commentaire source: doMJRoll: rolls defense using mob.rands, starts resolution

### get_mj_rand_edit_box(randType)

- Portee: local
- Ligne source: 422
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### get_current_mj_form_rand_bounds(randType)

- Portee: local
- Ligne source: 433
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### doMJRoll(randType, reqId, mobId, overrideMin, overrideMax)

- Portee: local
- Ligne source: 457
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### doMJAttack(targetName, attackType, isBehindAttack, overrideMin, overrideMax)

- Portee: local
- Ligne source: 499
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### has_mj_mobs_to_reset(state)

- Portee: local
- Ligne source: 585
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### has_mj_targets_to_reset(state)

- Portee: local
- Ligne source: 601
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### RefreshMobList()

- Portee: local
- Ligne source: 627
- Commentaire source: Mob list refresh (right-click = edit, left-click = toggle active)

### CreateMJFrame()

- Portee: local
- Ligne source: 744
- Commentaire source: MJ Frame creation

### set_close_btn_color(r, g, b, a)

- Portee: local
- Ligne source: 783
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### set_editbox_interactive(editBox, enabled)

- Portee: local
- Ligne source: 1024
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### get_armor_label(armorType)

- Portee: local
- Ligne source: 1045
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### refresh_survival_fields(source)

- Portee: local
- Ligne source: 1056
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### read_rand_fields()

- Portee: local
- Ligne source: 1173
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### safe(v)

- Portee: local
- Ligne source: 1174
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### get_click_bounds(randType)

- Portee: local
- Ligne source: 1184
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### read_crit_value(box)

- Portee: local
- Ligne source: 1199
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### read_failure_crit_value(box)

- Portee: local
- Ligne source: 1207
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### read_support_text()

- Portee: local
- Ligne source: 1219
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### read_dodge_back_percent()

- Portee: local
- Ligne source: 1224
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### read_hit_points()

- Portee: local
- Ligne source: 1239
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### read_survival_values()

- Portee: local
- Ligne source: 1251
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### read_support_flag()

- Portee: local
- Ligne source: 1277
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### ensure_attack_targets_state()

- Portee: local
- Ligne source: 1348
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### close_attack_target_dropdown()

- Portee: local
- Ligne source: 1382
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### refresh_attack_target_dropdown_label()

- Portee: local
- Ligne source: 1390
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### open_attack_target_dropdown()

- Portee: local
- Ligne source: 1402
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### get_selected_attack_target_name()

- Portee: local
- Ligne source: 1575
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### show_reset_confirm(dialogKey, text, onAccept)

- Portee: local
- Ligne source: 1583
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### ensure_mj_frame_fits()

- Portee: local
- Ligne source: 1899
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### open_history_modal()

- Portee: local
- Ligne source: 1921
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### CloseMobDropdown()

- Portee: local
- Ligne source: 2105
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### OpenMobDropdown(anchorBtn, requestId)

- Portee: local
- Ligne source: 2110
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### makeBtn(parent, label, w)

- Portee: local
- Ligne source: 2222
- Commentaire source: Small button helper

### UI.ShowMJNotification(requestId)

- Portee: global
- Ligne source: 2353
- Commentaire source: Public API

### UI.ToggleMJFrame()

- Portee: global
- Ligne source: 2365
- Role: fonction referencee automatiquement depuis ui/mj.lua.

### UI.OpenMJFrame()

- Portee: global
- Ligne source: 2380
- Role: fonction referencee automatiquement depuis ui/mj.lua.

