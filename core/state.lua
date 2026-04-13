---@class EasySanaluneOutcomeRange
---@field min integer?
---@field max integer?
---@field text string?

---@class EasySanaluneRandEntry
---@field type string?
---@field name string?
---@field info string?
---@field command string?
---@field rand_role string?
---@field is_default boolean?
---@field icon string|number|nil
---@field outcomes table<integer, string>?
---@field outcome_ranges EasySanaluneOutcomeRange[]?

---@class EasySanaluneSectionEntry
---@field type string
---@field name string
---@field is_fixed boolean?
---@field expanded boolean?
---@field items EasySanaluneCharEntry[]

---@alias EasySanaluneCharEntry EasySanaluneRandEntry|EasySanaluneSectionEntry

---@class EasySanaluneModalPosition
---@field x number
---@field y number

---@class EasySanaluneMJMob
---@field id integer?
---@field name string?
---@field notes string?
---@field rands table<string, string>?
---@field crit_off_success integer|nil
---@field crit_def_success integer|nil
---@field crit_off_failure_visual integer|nil
---@field crit_def_failure_visual integer|nil
---@field dodge_back_percent integer|nil
---@field hit_points integer|nil
---@field armor_type string|nil
---@field durability_current integer|nil
---@field durability_max integer|nil
---@field durability_infinite boolean|nil
---@field rda integer|nil
---@field rda_crit integer|nil
---@field is_support boolean?
---@field support_text string?

---@class EasySanaluneState
---@field pos_x number
---@field pos_y number
---@field dim_show_w number
---@field dim_show_h number
---@field dim_hide_w number
---@field dim_hide_h number
---@field minimap_button_pos number
---@field shown boolean
---@field raid_announce boolean
---@field mj_enabled boolean
---@field resolution_private_print boolean
---@field rand_result_reader boolean
---@field profile_mode boolean
---@field mj_mobs table<integer, EasySanaluneMJMob>
---@field mj_active_mob_id integer|nil
---@field mj_player_targets string[]
---@field mj_selected_target string|nil
---@field modal_positions table<string, EasySanaluneModalPosition>
---@field profiles string[]
---@field profile_index integer
---@field profile_chars table<integer, EasySanaluneCharEntry[]>
---@field profile_buffs table<integer, table>
---@field profile_crit_off_success table<integer, number>
---@field profile_crit_def_success table<integer, number>
---@field profile_crit_off_failure_visual table<integer, number>
---@field profile_crit_def_failure_visual table<integer, number>
---@field profile_dodge_back_percent table<integer, number>
---@field profile_hit_points table<integer, number>
---@field profile_armor_type table<integer, string>
---@field profile_durability_current table<integer, number>
---@field profile_durability_max table<integer, number>
---@field profile_durability_infinite table<integer, boolean>
---@field profile_rda table<integer, number>
---@field profile_rda_crit table<integer, number>
---@field buffs table
---@field buffs_visible boolean
---@field buff_dim_w number
---@field buff_dim_h number
---@field crit_off_success number
---@field crit_def_success number
---@field crit_off_failure_visual number
---@field crit_def_failure_visual number
---@field dodge_back_percent number
---@field hit_points number
---@field armor_type string
---@field durability_current number
---@field durability_max number
---@field durability_infinite boolean
---@field rda number
---@field rda_crit number
---@field CHARS EasySanaluneCharEntry[]

local StateLib = {}
_G.EasySanaluneStateLib = StateLib

---@type EasySanaluneState
StateLib.DEF_STATE = {
  pos_x = 500,
  pos_y = 500,
  dim_show_w = 325,
  dim_show_h = 400,
  dim_hide_w = 200,
  dim_hide_h = 50,
  minimap_button_pos = 25,
  shown = false,
  raid_announce = false,
  mj_enabled = false,
  resolution_private_print = true,
  rand_result_reader = false,
  profile_mode = false,
  mj_mobs = {},
  mj_active_mob_id = nil,
  mj_player_targets = {},
  mj_selected_target = nil,
  modal_positions = {},
  profiles = { "Profil 1" },
  profile_index = 1,
  profile_chars = {},
  profile_buffs = { {} },
  profile_crit_off_success = { 70 },
  profile_crit_def_success = { 70 },
  profile_crit_off_failure_visual = { 0 },
  profile_crit_def_failure_visual = { 0 },
  profile_dodge_back_percent = { 50 },
  profile_hit_points = { 5 },
  profile_armor_type = { "nue" },
  profile_durability_current = { 5 },
  profile_durability_max = { 5 },
  profile_durability_infinite = { false },
  profile_rda = { 0 },
  profile_rda_crit = { 0 },
  buffs = {},
  buffs_visible = true,
  buff_dim_w = 280,
  buff_dim_h = 320,
  crit_off_success = 70,
  crit_def_success = 70,
  crit_off_failure_visual = 0,
  crit_def_failure_visual = 0,
  dodge_back_percent = 50,
  hit_points = 5,
  armor_type = "nue",
  durability_current = 5,
  durability_max = 5,
  durability_infinite = false,
  rda = 0,
  rda_crit = 0,
  CHARS = {
    {
      type = "section",
      name = "Fiche basique",
      is_fixed = true,
      expanded = true,
      items = {
        { type = "rand", name = "Attaque physique", info = "1-100", command = "1-100", rand_role = "offensive", is_default = true },
        { type = "rand", name = "Attaque magique", info = "1-100", command = "1-100", rand_role = "offensive", is_default = true },
        { type = "rand", name = "Soutien", info = "1-100", command = "1-100", rand_role = "support", is_default = true },
        { type = "rand", name = "Défense physique", info = "1-100", command = "1-100", rand_role = "defensive", is_default = true },
        { type = "rand", name = "Défense magique", info = "1-100", command = "1-100", rand_role = "defensive", is_default = true },
        { type = "rand", name = "Esquive", info = "1-100", command = "1-100", rand_role = "defensive", is_default = true },
      }
    },
  }
}
