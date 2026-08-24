local Core = _G.EasySanaluneCore or {}
_G.EasySanaluneCore = Core

Core.Movement = Core.Movement or {}
local Movement = Core.Movement

-- Distance (en yards WoW) qui correspond a 100% du budget de deplacement d'un tour.
-- Convention RP alignee sur ~30m/tour. Constante unique et volontairement facile a ajuster.
Movement.FULL_MOVE_YARDS = 30

-- Marge de tolerance avant de declencher l'alerte MJ, pour absorber le bruit
-- d'integration de la vitesse et les micro-deplacements de camera/tour sur place.
Movement.EXCEED_GRACE_YARDS = 1

-- Valeur de vitesse de deplacement par defaut de la fiche (en pourcentage de budget).
Movement.DEFAULT_MOVEMENT_SPEED = 100

-- Bornes de securite pour la valeur de fiche.
Movement.MIN_MOVEMENT_SPEED = 0
Movement.MAX_MOVEMENT_SPEED = 999

local function to_number(value, fallback)
  local n = tonumber(value)
  if n == nil then
    return fallback
  end
  return n
end

-- Normalise/borne la vitesse de deplacement saisie dans la fiche.
function Movement.clamp_speed(value, defaultValue)
  local fallback = to_number(defaultValue, Movement.DEFAULT_MOVEMENT_SPEED)
  local n = to_number(value, fallback)
  n = math.floor(n + 0.5)
  if n < Movement.MIN_MOVEMENT_SPEED then
    n = Movement.MIN_MOVEMENT_SPEED
  elseif n > Movement.MAX_MOVEMENT_SPEED then
    n = Movement.MAX_MOVEMENT_SPEED
  end
  return n
end

-- Convertit une distance parcourue (yards) en pourcentage de budget consomme.
function Movement.yards_to_percent(yards)
  local full = Movement.FULL_MOVE_YARDS
  if full <= 0 then
    return 0
  end
  return (to_number(yards, 0) / full) * 100
end

-- Distance (yards) autorisee pour un budget donne (en pourcentage).
function Movement.allowed_yards(budgetPercent)
  local budget = Movement.clamp_speed(budgetPercent, Movement.DEFAULT_MOVEMENT_SPEED)
  return (budget / 100) * Movement.FULL_MOVE_YARDS
end

-- Calcule l'etat de deplacement d'un tour a partir du budget, de la distance
-- parcourue et du fait que le joueur ait deja lance son rand.
-- Retourne un tableau: remainingPercent, usedPercent, exceeded, allowedYards.
function Movement.compute(budgetPercent, movedYards, rolled)
  local budget = Movement.clamp_speed(budgetPercent, Movement.DEFAULT_MOVEMENT_SPEED)
  local moved = math.max(0, to_number(movedYards, 0))
  local usedPercent = Movement.yards_to_percent(moved)
  local capYards = Movement.allowed_yards(budget)

  local remainingPercent
  if rolled then
    -- Des que le joueur a lance son rand, le deplacement affiche tombe a 0%.
    remainingPercent = 0
  else
    remainingPercent = budget - usedPercent
    if remainingPercent < 0 then
      remainingPercent = 0
    end
  end

  local exceeded = moved > (capYards + Movement.EXCEED_GRACE_YARDS)

  return {
    remainingPercent = math.floor(remainingPercent + 0.5),
    usedPercent = math.floor(usedPercent + 0.5),
    exceeded = exceeded,
    allowedYards = capYards,
    budgetPercent = budget,
  }
end
