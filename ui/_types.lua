---@meta

---@class EasySanaluneCoreText
---@field trim fun(value:any):string
---@field sanitize_single_line fun(value:any):string
---@field sanitize_pipe fun(value:any):string
---@field fold_accents fun(value:any):string
---@field normalize_name fun(value:any):string
---@field player_name_key fun(value:any):string
---@field player_names_equal fun(a:any, b:any):boolean

---@class EasySanaluneMJLogic
---@field next_mob_id fun(state:EasySanaluneState):integer
---@field deserialize_profile fun(text:string):table|nil
---@field import_parsed_profile_as_mob fun(state:EasySanaluneState, parsed:table, fallbackName:string, fallbackNotes:string):integer|nil
---@field serialize_profile fun(state:EasySanaluneState):string
---@field get_defense_rand_name fun(defenderRandType:string):string

---@class EasySanaluneResolutionLogic
---@field compute fun(attackRoll:number, defendRoll:number, critOff:number?, critDef:number?):boolean, integer, integer, integer
---@field extract_bonus_from_label fun(text:string):integer
---@field format_text fun(attacker:string, mobName:string, attackRoll:number, defendRoll:number, attackTotal:number?, defendTotal:number?, hit:boolean, diff:number, critCount:integer, defCritCount:integer, attackReason:string?, defenseReason:string?):string

---@class EasySanaluneCombatSessionLogic
---@field new fun():table
---@field next_rand_request_id fun(session:table, playerName:string):string
---@field next_attack_request_id fun(session:table, playerName:string):string
---@field add_known_mj fun(session:table, mjName:string, now:number)
---@field add_roll fun(session:table, roller:string, roll:number, rMin:number, rMax:number, now:number, maxSize:number)
---@field find_roll fun(session:table, rollerName:string, rMin:number, rMax:number, afterTime:number?, now:number, expiry:number, shorten:fun(name:string):string):table|nil
---@field start_mj_resolution fun(session:table, requestId:string, state:EasySanaluneState, defenderRandType:string, defMin:number, defMax:number, now:number, mjName:string, shorten:fun(name:string):string):table|nil
---@field start_player_defense_resolution fun(session:table, requestId:string, state:EasySanaluneState, defenderRandType:string, defMin:number, defMax:number, now:number, defenderName:string, shorten:fun(name:string):string):table|nil

---@class EasySanaluneCore
---@field copy_outcomes fun(outcomes:table|nil):table
---@field copy_outcome_ranges fun(ranges:table|nil):EasySanaluneOutcomeRange[]
---@field parse_outcome_selector fun(input:string):integer?, integer?
---@field parse_command fun(input:string):(integer|nil), (integer|nil), (string|nil)
---@field normalize_chars fun(chars:EasySanaluneCharEntry[]|nil):EasySanaluneCharEntry[]
---@field deep_clone_chars fun(list:EasySanaluneCharEntry[]|nil):EasySanaluneCharEntry[]
---@field prepare_state fun(savedState:table|nil, defaultState:EasySanaluneState):EasySanaluneState
---@field Text EasySanaluneCoreText?
---@field MJ EasySanaluneMJLogic?
---@field Resolution EasySanaluneResolutionLogic?
---@field CombatSession EasySanaluneCombatSessionLogic?
---@field Protocol table?

---@class EasySanaluneStateLib
---@field DEF_STATE EasySanaluneState
