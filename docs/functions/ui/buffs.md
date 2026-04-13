# ui/buffs.lua

## Resume

Construction des widgets, orchestration des popups et liaison avec l'etat addon.

## Fonctions

### L_get(key, ...)

- Portee: local
- Ligne source: 39
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### L_print(key, ...)

- Portee: local
- Ligne source: 44
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### L_get_fallback(key, fallback)

- Portee: local
- Ligne source: 50
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### get_state()

- Portee: local
- Ligne source: 65
- Commentaire source: @return EasySanaluneState|nil

### get_stdui()

- Portee: local
- Ligne source: 67
- Commentaire source: @return any

### apply_panel_theme(w, s, n)

- Portee: local
- Ligne source: 68
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### apply_button_theme(w, p)

- Portee: local
- Ligne source: 69
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### apply_checkbox_theme(w)

- Portee: local
- Ligne source: 70
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### apply_editbox_theme(w)

- Portee: local
- Ligne source: 71
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### style_font_string(w, a)

- Portee: local
- Ligne source: 72
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### make_modal_draggable(m, k)

- Portee: local
- Ligne source: 73
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### apply_modal_position(m, k)

- Portee: local
- Ligne source: 74
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### parse_command(v)

- Portee: local
- Ligne source: 75
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### trim(text)

- Portee: local
- Ligne source: 81
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### sanitize_line(text)

- Portee: local
- Ligne source: 91
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### apply_font_size(fs, size)

- Portee: local
- Ligne source: 100
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### apply_centered_symbol_label(button, symbol)

- Portee: local
- Ligne source: 119
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### normalize_name(value)

- Portee: local
- Ligne source: 190
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### find_stat_option(value, optionList)

- Portee: local
- Ligne source: 205
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### get_current_rand_target_options()

- Portee: local
- Ligne source: 230
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### add_target(sectionName, entry)

- Portee: local
- Ligne source: 235
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### walk_entries(list, currentSectionName)

- Portee: local
- Ligne source: 264
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### build_single_target_options()

- Portee: local
- Ligne source: 290
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### build_multi_target_options()

- Portee: local
- Ligne source: 304
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### resolve_target_key(value)

- Portee: local
- Ligne source: 318
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### get_stat_option_index(statKey)

- Portee: local
- Ligne source: 328
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### get_stat_option_by_rand_name(randName)

- Portee: local
- Ligne source: 333
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### format_range(minVal, maxVal)

- Portee: local
- Ligne source: 338
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### get_entry_stat_keys(entry)

- Portee: local
- Ligne source: 365
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### format_entry_stats_label(entry)

- Portee: local
- Ligne source: 379
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### get_entry_value_text(entry)

- Portee: local
- Ligne source: 400
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### get_option_label_by_key(key)

- Portee: local
- Ligne source: 435
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### get_exact_entry_stat_labels(entry)

- Portee: local
- Ligne source: 440
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### add_key(key)

- Portee: local
- Ligne source: 445
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### constrain_button_label(button, leftInset, rightInset)

- Portee: local
- Ligne source: 475
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### constrain_checkbox_label(checkbox, owner, rightInset)

- Portee: local
- Ligne source: 496
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### create_stat_dropdown(parent, initialValue, onSelect, optionsProvider)

- Portee: local
- Ligne source: 520
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### get_options()

- Portee: local
- Ligne source: 526
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### get_selected_option()

- Portee: local
- Ligne source: 561
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### refresh_trigger_text()

- Portee: local
- Ligne source: 570
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### hide_dropdown()

- Portee: local
- Ligne source: 575
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### rebuild_dropdown()

- Portee: local
- Ligne source: 579
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### create_multi_target_dropdown(parent, optionsProvider, selectedMap)

- Portee: local
- Ligne source: 636
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### get_options()

- Portee: local
- Ligne source: 642
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### get_selected_keys()

- Portee: local
- Ligne source: 679
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### refresh_trigger_text()

- Portee: local
- Ligne source: 693
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### hide_dropdown()

- Portee: local
- Ligne source: 712
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### rebuild_dropdown()

- Portee: local
- Ligne source: 716
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### is_buff_section(entry)

- Portee: local
- Ligne source: 782
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### sanitize_buff_values(values)

- Portee: local
- Ligne source: 786
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### sanitize_buff_payload(entry)

- Portee: local
- Ligne source: 804
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### sanitize_buff_section(section)

- Portee: local
- Ligne source: 821
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### normalize_buff_sections(buffs)

- Portee: local
- Ligne source: 844
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### ensure_default_section()

- Portee: local
- Ligne source: 945
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### for_each_buff_item(buffs, fn)

- Portee: local
- Ligne source: 999
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### ensure_profile_buffs(index)

- Portee: local
- Ligne source: 1018
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### reset_current_profile_buffs()

- Portee: local
- Ligne source: 1037
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### has_current_profile_buffs_to_reset()

- Portee: local
- Ligne source: 1065
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### ensure_reset_popup_dialog()

- Portee: local
- Ligne source: 1097
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### prompt_reset_all_buffs()

- Portee: local
- Ligne source: 1122
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### update_buffs_reset_button_visibility()

- Portee: local
- Ligne source: 1134
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### UI.Buffs.SwitchProfile(index)

- Portee: global
- Ligne source: 1146
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### collect_bonus_details(randName, randRole)

- Portee: local
- Ligne source: 1155
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### collect_crit_bonus_details(kind)

- Portee: local
- Ligne source: 1275
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### UI.Buffs.GetTotalBonusForRand(randName, randRole)

- Portee: global
- Ligne source: 1329
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### UI.Buffs.GetCritThresholdBonus(kind)

- Portee: global
- Ligne source: 1333
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### UI.Buffs.GetBonusSourceText(randName, randRole)

- Portee: global
- Ligne source: 1337
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### UI.Buffs.ApplyBonusToRange(randName, minVal, maxVal, randRole)

- Portee: global
- Ligne source: 1345
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### UI.Buffs.GetDisplayName(randData)

- Portee: global
- Ligne source: 1365
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### UI.Buffs.GetDisplayInfo(randData)

- Portee: global
- Ligne source: 1383
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### get_default_section(buffs)

- Portee: local
- Ligne source: 1405
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### make_buff_modal(entry, parentSection, itemIndex)

- Portee: local
- Ligne source: 1425
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### set_multi_mode_enabled(enabled)

- Portee: local
- Ligne source: 1513
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### make_section_modal(section, sectionIndex)

- Portee: local
- Ligne source: 1650
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### UI.Buffs.RefreshList()

- Portee: global
- Ligne source: 1725
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### move_entry(list, entry, delta)

- Portee: local
- Ligne source: 1749
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### remove_entry(list, entry)

- Portee: local
- Ligne source: 1771
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### set_section_highlight(sectionWidget, enabled)

- Portee: local
- Ligne source: 1784
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### find_hover_section_widget(excludedWidget)

- Portee: local
- Ligne source: 1791
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### move_section_relative(sectionElem, targetSectionWidget, placeAfter)

- Portee: local
- Ligne source: 1804
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### move_buff_to_section(buffElem, targetSection)

- Portee: local
- Ligne source: 1843
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### move_buff_to_default_section(buffElem)

- Portee: local
- Ligne source: 1863
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### glue_row(row)

- Portee: local
- Ligne source: 1969
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### set_widgets_visible(widgets, visible)

- Portee: local
- Ligne source: 1980
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### is_hovered_any(widgets)

- Portee: local
- Ligne source: 1993
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### bind_hover_refresh(widgets, refreshFn)

- Portee: local
- Ligne source: 2003
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### save_and_refresh(includeMainRefresh)

- Portee: local
- Ligne source: 2013
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### move_entry_and_refresh(list, entry, delta)

- Portee: local
- Ligne source: 2021
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### remove_entry_and_refresh(list, entry, includeMainRefresh)

- Portee: local
- Ligne source: 2027
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### create_action_button(parent, width, height, text, point, relativeTo, relativePoint, x, y, isPrimary, onClick)

- Portee: local
- Ligne source: 2033
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### set_section_actions_visible(visible)

- Portee: local
- Ligne source: 2137
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### refresh_section_actions_visibility()

- Portee: local
- Ligne source: 2145
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### show_row_tooltip()

- Portee: local
- Ligne source: 2233
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### hide_row_tooltip()

- Portee: local
- Ligne source: 2262
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### set_value_anchor(showActions)

- Portee: local
- Ligne source: 2268
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### set_text_anchor(showActions)

- Portee: local
- Ligne source: 2277
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### set_actions_visible(visible)

- Portee: local
- Ligne source: 2289
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### refresh_actions_visibility()

- Portee: local
- Ligne source: 2295
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### UI.Buffs.SyncToMainFrame()

- Portee: global
- Ligne source: 2327
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### UI.Buffs.EnsureWindow()

- Portee: global
- Ligne source: 2336
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### buff_scroll_guard()

- Portee: local
- Ligne source: 2390
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### orient_to_bottom_left(tex)

- Portee: local
- Ligne source: 2443
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### UI.Buffs.Toggle()

- Portee: global
- Ligne source: 2491
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### UI.Buffs.OnMainShow()

- Portee: global
- Ligne source: 2515
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

### UI.Buffs.OnMainHide()

- Portee: global
- Ligne source: 2541
- Role: fonction referencee automatiquement depuis ui/buffs.lua.

