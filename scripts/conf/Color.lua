
-- ================================================================================================

--- Color configuration.
---------------------------------------------------------------------------------------------------
-- @conf Color

-- ================================================================================================

--- Color RGBA format.
-- @table RGBA
-- @tfield number r Red color component (from 0 to 1).
-- @tfield number g Green color component (from 0 to 1).
-- @tfield number b Blue color component (from 0 to 1).
-- @tfield number a Alpha color component (from 0 to 1).

--- Color HSV format.
-- @table HSV
-- @tfield number h Hue component (from 0 to 360).
-- @tfield number s Saturation component (from 0 to 1).
-- @tfield number v Value/brightness component (from 0 to 1).

--- An `RGBA` color representing white.
-- @table white
-- @tfield number r 1.
-- @tfield number g 1.
-- @tfield number b 1.
-- @tfield number a 1.

local black = {r = 0, g = 0, b = 0, a = 1}
local red = {r = 1, g = 0, b = 0, a = 1}
local green = {r = 0, g = 1, b = 0, a = 1}
local blue = {r = 0, g = 0, b = 1, a = 1}
local yellow = {r = 1, g = 1, b = 0, a = 1}
local magenta = {r = 1, g = 0, b = 1, a = 1}
local cyan = {r = 0, g = 1, b = 1, a = 1}
local white = {r = 1, g = 1, b = 1, a = 1}

local babypink = {r = 1, g = 0.55, b = 0.95, a = 1}
local babyb = {r = 0.65, g = 0.7, b = 1, a = 1}
local lightgray = {r = 0.8, g = 0.8, b = 0.8, a = 0.8}

return {
  -- Common colors
  black = black,
  red = red,
  green = green,
  blue = blue,
  yellow = yellow,
  magenta = magenta,
  cyan = cyan,
  white = white,
  babypink = babypink,
  babyb = babyb,

  -- Tile skill colors (selectable)
  tile_general = {r = 0.85, g = 0.5, b = 0.85, a = 0.85},
  tile_move = {r = 0.4, g = 0.4, b = 1, a = 0.85},
  tile_support = {r = 0.4, g = 1, b = 0.4, a = 0.85},
  tile_attack = {r = 1, g = 0.4, b = 0.4, a = 0.85},
  tile_nothing = {r = 0.7, g = 0.7, b = 0.7, a = 0.75},

  -- Tile skill colors (non-selectable)
  tile_general_off = {r = 0.8, g = 0.45, b = 0.8, a = 0.4},
  tile_move_off = {r = 0.3, g = 0.3, b = 1, a = 0.4},
  tile_support_off = {r = 0.3, g = 1, b = 0.3, a = 0.4},
  tile_attack_off = {r = 1, g = 0.3, b = 0.3, a = 0.4},
  tile_nothing_off = {r = 0.6, g = 0.6, b = 0.6, a = 0.2},

  -- Battle heal/damagge pop-ups
  popup_dmghp = {r = 1, g = 1, b = 0.5, a = 1},
  popup_dmgsp = {r = 1, g = 0.3, b = 0.3, a = 1},
  popup_healhp = {r = 0.3, g = 1, b = 0.3, a = 1},
  popup_healsp = {r = 0.3, g = 0.3, b = 1, a = 1},
  popup_miss = {r = 0.8, g = 0.8, b = 0.8, a = 1},
  popup_status_add = white,
  popup_status_remove = white,
  popup_levelup = yellow,
  popup_exp = white,
  
  -- Menu
  menu_text_enabled = white,
  menu_text_disabled = lightgray,
  menu_icon_enabled = white,
  menu_icon_disabled = lightgray,
  barHP = {r = 0.2, g = 1, b = 0.4, a = 1},
  barSP = {r = 0.2, g = 0.4, b = 1, a = 1},
  barEXP = {r = 1, g = 1, b = 0.4, a = 1},
  barTC = {r = 1, g = 0.8, b = 0.4, a = 1},
  positive_bonus = green,
  negative_bonus = red,
  element_weak = green,
  element_strong = red,
  element_neutral = white
  
}
