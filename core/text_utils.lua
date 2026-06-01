local Core = _G.EasySanaluneCore or {}
_G.EasySanaluneCore = Core

Core.Text = Core.Text or {}
local Text = Core.Text

local ACCENT_MAP = {
  ["à"] = "a", ["á"] = "a", ["â"] = "a", ["ã"] = "a", ["ä"] = "a", ["å"] = "a",
  ["ç"] = "c",
  ["è"] = "e", ["é"] = "e", ["ê"] = "e", ["ë"] = "e",
  ["ì"] = "i", ["í"] = "i", ["î"] = "i", ["ï"] = "i",
  ["ñ"] = "n",
  ["ò"] = "o", ["ó"] = "o", ["ô"] = "o", ["õ"] = "o", ["ö"] = "o", ["ø"] = "o",
  ["ù"] = "u", ["ú"] = "u", ["û"] = "u", ["ü"] = "u",
  ["ý"] = "y", ["ÿ"] = "y",
  ["œ"] = "oe", ["æ"] = "ae",
}

function Text.trim(value)
  local raw = tostring(value or "")
  raw = string.gsub(raw, "^%s+", "")
  raw = string.gsub(raw, "%s+$", "")
  return raw
end

function Text.sanitize_single_line(value)
  local raw = tostring(value or "")
  return string.gsub(raw, "[\r\n]", " ")
end

function Text.sanitize_pipe(value)
  return string.gsub(tostring(value or ""), "|", "/")
end

function Text.fold_accents(value)
  local out = string.lower(tostring(value or ""))
  for from, to in pairs(ACCENT_MAP) do
    out = string.gsub(out, from, to)
  end
  return out
end

function Text.normalize_name(value)
  local raw = Text.fold_accents(Text.trim(value))
  raw = string.gsub(raw, "[^%w%s]", "")
  raw = string.gsub(raw, "%s+", " ")
  return Text.trim(raw)
end

function Text.player_name_key(value)
  local raw = Text.trim(value)
  if raw == "" then
    return ""
  end
  local short = string.match(raw, "^([^%-]+)") or raw
  short = string.gsub(short, "%s+", "")
  return Text.fold_accents(short)
end

function Text.player_names_equal(a, b)
  local ka = Text.player_name_key(a)
  local kb = Text.player_name_key(b)
  return ka ~= "" and kb ~= "" and ka == kb
end
