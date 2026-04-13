# ui/ui.lua

## Resume

Construction des widgets, orchestration des popups et liaison avec l'etat addon.

## Fonctions

### normalize_armor_type(value)

- Portee: local
- Ligne source: 44
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### get_armor_type_label(value)

- Portee: local
- Ligne source: 74
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### fallback_copy_outcomes(value)

- Portee: local
- Ligne source: 94
- Commentaire source: Fonctions de secours (utilisees si les helpers du Core sont absents)

### fallback_copy_outcome_ranges(value)

- Portee: local
- Ligne source: 105
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### fallback_parse_outcome_selector(input)

- Portee: local
- Ligne source: 123
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### fallback_parse_command(input)

- Portee: local
- Ligne source: 146
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### fallback_normalize_chars(_)

- Portee: local
- Ligne source: 177
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### fallback_deep_clone_chars(list)

- Portee: local
- Ligne source: 181
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### L_get(key, ...)

- Portee: local
- Ligne source: 243
- Commentaire source: Aide pour les textes localises et l'affichage en chat

### L_print(key, ...)

- Portee: local
- Ligne source: 250
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### print_resolution_for_local_context(text)

- Portee: local
- Ligne source: 262
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### escape_chat_message(text)

- Portee: local
- Ligne source: 272
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### warn_missing_core()

- Portee: local
- Ligne source: 277
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### clamp_percent(value, defaultValue)

- Portee: local
- Ligne source: 289
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### apply_panel_theme(frame, soft, noShading)

- Portee: local
- Ligne source: 601
- Commentaire source: Aide de style visuel (panneaux, boutons, couleurs)

### style_font_string(fs, accent)

- Portee: local
- Ligne source: 647
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### apply_button_theme(button, isPrimary)

- Portee: local
- Ligne source: 655
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### create_header_button(parent, width, text, isPrimary)

- Portee: local
- Ligne source: 702
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### set_profile_surface_colors(frame, highlighted)

- Portee: local
- Ligne source: 711
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### apply_profile_surface(frame, highlighted)

- Portee: local
- Ligne source: 727
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### apply_icon_arrow_button_theme(button)

- Portee: local
- Ligne source: 737
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### set_arrow_hover_state(self, hovered)

- Portee: local
- Ligne source: 779
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### apply_editbox_theme(editBox)

- Portee: local
- Ligne source: 829
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### apply_checkbox_theme(checkbox)

- Portee: local
- Ligne source: 866
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### update_checkbox_state(self)

- Portee: local
- Ligne source: 940
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### apply_scrollbar_theme(scrollWidget)

- Portee: local
- Ligne source: 1011
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### suppress_native_arrow_button(button)

- Portee: local
- Ligne source: 1054
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### strip_all_textures(btn)

- Portee: local
- Ligne source: 1059
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### clear_visuals(btn)

- Portee: local
- Ligne source: 1071
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### ensure_proxy_arrow(direction)

- Portee: local
- Ligne source: 1094
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### set_proxy_arrow_visual(button, hover)

- Portee: local
- Ligne source: 1127
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### sync_proxy_arrows_state()

- Portee: local
- Ligne source: 1189
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### INTERNALS.is_any_menu_open()

- Portee: global
- Ligne source: 1242
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### INTERNALS.register_menu_open(menuKey)

- Portee: global
- Ligne source: 1246
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### INTERNALS.register_menu_close(menuKey)

- Portee: global
- Ligne source: 1249
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### add_outcome_to_modal(modal, ebOutcomeValue, ebOutcomeText, update_outcomes_label)

- Portee: local
- Ligne source: 1254
- Commentaire source: @param modal EasySanaluneOutcomeModal

### remove_outcome_from_modal(modal, ebOutcomeValue, ebOutcomeText, update_outcomes_label)

- Portee: local
- Ligne source: 1298
- Commentaire source: @param modal EasySanaluneOutcomeModal

### build_rand_pattern()

- Portee: local
- Ligne source: 1337
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### parse_roll_message(message)

- Portee: local
- Ligne source: 1354
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### is_local_player_roll(roller)

- Portee: local
- Ligne source: 1375
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### setup_rand_listener()

- Portee: local
- Ligne source: 1380
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### release_body()

- Portee: local
- Ligne source: 1449
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### toggle_widgets(widgets, visible)

- Portee: local
- Ligne source: 1457
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### remove_entry(list, entry)

- Portee: local
- Ligne source: 1471
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### move_entry(list, entry, direction)

- Portee: local
- Ligne source: 1484
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### snap_to_pixel(value)

- Portee: local
- Ligne source: 1504
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### apply_main_frame_position()

- Portee: local
- Ligne source: 1512
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### get_min_main_frame_right(frameWidth)

- Portee: local
- Ligne source: 1513
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### sync_main_frame_during_drag(frame)

- Portee: local
- Ligne source: 1534
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### clamp_main_frame_state_position(frameWidth, frameHeight)

- Portee: local
- Ligne source: 1563
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### refresh_main_frame_texture()

- Portee: local
- Ligne source: 1575
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### set_resize_visual_state(isActive)

- Portee: local
- Ligne source: 1585
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### ensure_modal_positions()

- Portee: local
- Ligne source: 1589
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### apply_modal_position(modal, positionKey)

- Portee: local
- Ligne source: 1598
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### save_modal_position(modal, positionKey)

- Portee: local
- Ligne source: 1615
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### make_modal_draggable(modal, positionKey)

- Portee: local
- Ligne source: 1640
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### create_themed_draggable_modal(frameName, width, height, frameLevel, positionKey, startHidden)

- Portee: local
- Ligne source: 1665
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### get_infos_help_text()

- Portee: local
- Ligne source: 1686
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### open_infos_guide_window()

- Portee: local
- Ligne source: 1690
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### get_min_frame_size()

- Portee: local
- Ligne source: 1937
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### stop_resize()

- Portee: local
- Ligne source: 2071
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### parse_crit_threshold(text)

- Portee: local
- Ligne source: 2227
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### parse_hit_points_value(text)

- Portee: local
- Ligne source: 2243
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### ensure_profile_survival_tables()

- Portee: local
- Ligne source: 2262
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### persist_survival_profile_state(index)

- Portee: local
- Ligne source: 2272
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### close_text_fields_modal()

- Portee: local
- Ligne source: 2292
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### update_text_field_select_row(row)

- Portee: local
- Ligne source: 2300
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### collect_text_fields_modal_values()

- Portee: local
- Ligne source: 2324
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### set_text_fields_modal_value(key, value)

- Portee: local
- Ligne source: 2344
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### set_text_fields_modal_field_enabled(key, enabled)

- Portee: local
- Ligne source: 2369
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### run_text_fields_modal_live_change(changedKey)

- Portee: local
- Ligne source: 2413
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### open_text_fields_modal(config)

- Portee: local
- Ligne source: 2426
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### update_fiche_btn_anchor()

- Portee: local
- Ligne source: 2875
- Commentaire source: Position de depart du bouton Fiche selon l'etat MJ

### ensure_profile_menu_click_guard()

- Portee: local
- Ligne source: 2951
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### CloseProfileDropdown()

- Portee: local
- Ligne source: 2990
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### OpenProfileDropdown()

- Portee: local
- Ligne source: 2999
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### OpenProfileActionMenu()

- Portee: local
- Ligne source: 3089
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### clone_chars(list)

- Portee: local
- Ligne source: 3234
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### default_chars()

- Portee: local
- Ligne source: 3238
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### ensure_profile_chars(index)

- Portee: local
- Ligne source: 3245
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### ensure_profile_buffs(index)

- Portee: local
- Ligne source: 3254
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### ensure_profile_crit(index)

- Portee: local
- Ligne source: 3263
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### reset_current_profile()

- Portee: local
- Ligne source: 3347
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### tables_equal(a, b)

- Portee: local
- Ligne source: 3403
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### has_current_profile_data_to_reset()

- Portee: local
- Ligne source: 3427
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### has_current_profile_buffs()

- Portee: local
- Ligne source: 3487
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### update_main_reset_button_visibility()

- Portee: local
- Ligne source: 3500
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### update_scroll_guard()

- Portee: local
- Ligne source: 3653
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### set_section_highlight(sectionWidget, enabled)

- Portee: local
- Ligne source: 3722
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### find_hover_section_widget(excludedWidget)

- Portee: local
- Ligne source: 3733
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### move_section_relative(sectionElem, targetSectionWidget, placeAfter)

- Portee: local
- Ligne source: 3750
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### move_rand_to_section(randElem, targetSection)

- Portee: local
- Ligne source: 3798
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### move_rand_to_main_list(randElem)

- Portee: local
- Ligne source: 3837
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### glue_below_with_section_spacing(widget, previousWidget)

- Portee: local
- Ligne source: 3862
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### normalize_player_name_key(playerName)

- Portee: local
- Ligne source: 4211
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### cache_player_survival(playerName, source, timestamp)

- Portee: local
- Ligne source: 4224
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### get_cached_player_survival(playerName)

- Portee: local
- Ligne source: 4243
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### should_refresh_player_survival_cache(playerName)

- Portee: local
- Ligne source: 4261
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### request_player_survival_sync(playerName)

- Portee: local
- Ligne source: 4280
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### tooltip_is_visible(tooltip)

- Portee: local
- Ligne source: 4313
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### tooltip_has_player_unit(tooltip)

- Portee: local
- Ligne source: 4317
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### mouseover_has_player_unit()

- Portee: local
- Ligne source: 4326
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### cancel_player_survival_hover_hide(frame)

- Portee: local
- Ligne source: 4330
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### get_preferred_player_survival_anchor(preferredAnchor)

- Portee: local
- Ligne source: 4345
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### anchor_player_survival_hover_frame(frame, preferredAnchor)

- Portee: local
- Ligne source: 4352
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### fade_in_player_survival_hover_frame(frame)

- Portee: local
- Ligne source: 4367
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### fade_out_player_survival_hover_frame(frame, immediate)

- Portee: local
- Ligne source: 4387
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### append_survival_tooltip_lines(tooltip, source)

- Portee: local
- Ligne source: 4429
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### ensure_player_survival_hover_frame()

- Portee: local
- Ligne source: 4453
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### show_player_survival_hover_frame(anchor, playerName, source)

- Portee: local
- Ligne source: 4559
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### hide_player_survival_hover_frame(immediate)

- Portee: local
- Ligne source: 4584
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.EnsurePlayerSurvivalTooltipHook()

- Portee: global
- Ligne source: 4604
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### append_reason_segment(baseText, extraText)

- Portee: local
- Ligne source: 4699
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### record_action_history(entry)

- Portee: local
- Ligne source: 4711
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.RecordActionHistory(entry)

- Portee: global
- Ligne source: 4722
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.GetActionHistory()

- Portee: global
- Ligne source: 4726
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### reset_synced_mob_state(syncId, senderName, timestamp, activeMobId, expectedCount)

- Portee: local
- Ligne source: 4730
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### resolve_pending_request_selected_mob_id(state, requestedMobId, requestedMobName)

- Portee: local
- Ligne source: 4744
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### add_synced_mob_entry(syncId, senderName, mobId, mobName, isSupport, isActive)

- Portee: local
- Ligne source: 4772
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### finalize_synced_mob_state(syncId, senderName, timestamp, receivedCount)

- Portee: local
- Ligne source: 4800
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.GetSyncedMobEntries()

- Portee: global
- Ligne source: 4813
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.GetSyncedMobState()

- Portee: global
- Ligne source: 4833
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### get_addon_send_channel()

- Portee: local
- Ligne source: 4837
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### normalize_mj_attack_type(rawAttackType)

- Portee: local
- Ligne source: 4848
- Commentaire source: Regle metier MJ: seules deux familles d'attaque sont autorisees sur le reseau. Toute autre valeur est forcee en ATK_PHY pour eviter les comportements instables.

### normalize_network_roll_bounds(minValue, maxValue)

- Portee: local
- Ligne source: 4859
- Commentaire source: Regle metier RP: les bornes de /rand doivent rester propres, entieres et ordonnees. Si elles sont invalides, on bloque la valeur au lieu de la propager.

### UI.SendMJAnnounce(isEnabled)

- Portee: global
- Ligne source: 4882
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.SendPlayerSurvivalSync(targetPlayer)

- Portee: global
- Ligne source: 4899
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.SendMJMobSync()

- Portee: global
- Ligne source: 4957
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.MaybeAutoRefreshMJMobSync(delaySeconds)

- Portee: global
- Ligne source: 4999
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### has_known_mj_in_current_group()

- Portee: local
- Ligne source: 5038
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### add_group_member(unit)

- Portee: local
- Ligne source: 5051
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.ShouldPromptForOffensiveRand(randName, randRole)

- Portee: global
- Ligne source: 5087
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### get_adjusted_crit_threshold(kind, baseValue)

- Portee: local
- Ligne source: 5119
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### send_rand_request_payload(requestId, channel, sender, safeName, reqMin, reqMax, critOff, critDef, mobName, attackerReason, mobSyncId, mobId, isBehindAttack)

- Portee: local
- Ligne source: 5143
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.SendRandRequest(min, max, randName, randInfo, randRole, mobName, mobId, mobSyncId, isBehindAttack, skipPrompt)

- Portee: global
- Ligne source: 5158
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.SendMJAttackRequest(targetPlayer, attackType, min, max, mobName, attackCritOff, attackCritDef, isBehindAttack)

- Portee: global
- Ligne source: 5231
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.OnAddonMessage(prefix, message, channel, sender)

- Portee: global
- Ligne source: 5293
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### add_roll_to_buffer(roller, roll, rMin, rMax)

- Portee: local
- Ligne source: 5484
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### find_roll_in_buffer(rollerName, rMin, rMax, afterTime)

- Portee: local
- Ligne source: 5501
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.StartResolution(requestId, defenderRandType, defMin, defMax)

- Portee: global
- Ligne source: 5533
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.ComputeResolution(attackRoll, defendRoll, critOff, critDef)

- Portee: global
- Ligne source: 5552
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### get_defense_rand_name(defenderRandType)

- Portee: local
- Ligne source: 5628
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### format_roll_segment(baseRoll, totalRoll)

- Portee: local
- Ligne source: 5635
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.FormatResolutionText(attacker, mobName, attackRoll, defendRoll, attackTotal, defendTotal, hit, diff, critCount, defCritCount, attackReason, defenseReason)

- Portee: global
- Ligne source: 5646
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.AnnounceResolution(text)

- Portee: global
- Ligne source: 5696
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.SendResolutionAddonMessage(requestId, text)

- Portee: global
- Ligne source: 5713
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.SendPlayerDefenseResolutionAddonMessage(requestId, text)

- Portee: global
- Ligne source: 5726
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### send_private_resolution_addon_message(msgType, requestId, senderName, text, targetA, targetB)

- Portee: local
- Ligne source: 5739
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### send_to(target)

- Portee: local
- Ligne source: 5753
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.TryResolve(requestId)

- Portee: global
- Ligne source: 5780
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.GetPlayerDefenseRange(defenderRandType)

- Portee: global
- Ligne source: 5863
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.StartPlayerDefenseResolution(requestId, defenderRandType, defMin, defMax)

- Portee: global
- Ligne source: 5872
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.TryResolvePlayerDefense(requestId)

- Portee: global
- Ligne source: 5891
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.ReplayActionHistoryEntry(entry)

- Portee: global
- Ligne source: 5946
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.ShowPlayerDefensePrompt(requestId)

- Portee: global
- Ligne source: 6056
- Commentaire source: Modale contextuelle de defense joueur

### answer(defType)

- Portee: local
- Ligne source: 6101
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.ShowOffensiveMobPrompt(payload)

- Portee: global
- Ligne source: 6130
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.FindDefaultRandByName(name)

- Portee: global
- Ligne source: 6297
- Commentaire source: Outils divers (recherche / export de profil) Retrouve un rand par defaut a partir de son nom dans CHARS.

### UI.SerializeProfile()

- Portee: global
- Ligne source: 6321
- Commentaire source: Export et serialisation de profil

### UI.DeserializeProfile(text)

- Portee: global
- Ligne source: 6328
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### trim_profile_import_text(value)

- Portee: local
- Ligne source: 6335
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### normalize_profile_import_name(value)

- Portee: local
- Ligne source: 6342
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### make_unique_import_profile_name(baseName)

- Portee: local
- Ligne source: 6360
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### build_imported_profile_chars(parsed)

- Portee: local
- Ligne source: 6396
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### build_imported_profile_buffs(parsed)

- Portee: local
- Ligne source: 6471
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.ImportProfileFromSerializedText(text)

- Portee: global
- Ligne source: 6537
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.OpenImportModal()

- Portee: global
- Ligne source: 6641
- Role: fonction referencee automatiquement depuis ui/ui.lua.

### UI.OpenExportModal()

- Portee: global
- Ligne source: 6698
- Role: fonction referencee automatiquement depuis ui/ui.lua.

