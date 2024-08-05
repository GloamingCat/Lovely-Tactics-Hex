
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

local babyPink = {r = 1, g = 0.55, b = 0.95, a = 1}
local babyBlue = {r = 0.65, g = 0.7, b = 1, a = 1}
local lightPurple = {r = 0.8, g = 0.5, b = 0.9, a = 0.85}
local lightBlue = {r = 0.4, g = 0.4, b = 1, a = 0.85}
local lightGreen = {r = 0.4, g = 1, b = 0.4, a = 0.85}
local lightRed = {r = 1, g = 0.4, b = 0.4, a = 0.85}
local lightGray = {r = 0.75, g = 0.75, b = 0.75, a = 0.75}

local clearPurple = {r = 0.8, g = 0.45, b = 0.8, a = 0.4}
local clearBlue = {r = 0.3, g = 0.3, b = 1, a = 0.4}
local clearGreen = {r = 0.3, g = 1, b = 0.3, a = 0.4}
local clearRed = {r = 1, g = 0.3, b = 0.3, a = 0.4}
local clearGray = {r = 0.65, g = 0.65, b = 0.65, a = 0.2}

local opaqueYellow = {r = 1, g = 1, b = 0.5, a = 1}
local opaqueCyan = {r = 0.5, g = 1, b = 1, a = 1}
local opaquePink = {r = 1, g = 0.5, b = 1, a = 1}
local opaqueRed = {r = 1, g = 0.3, b = 0.3, a = 1}
local opaqueGreen = {r = 0.25, g = 1, b = 0.35, a = 1}
local opaqueBlue = {r = 0.35, g = 0.25, b = 1, a = 1}
local opaqueGray = {r = 0.8, g = 0.8, b = 0.8, a = 1}

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
  babyPink = babyPink,
  babyBlue = babyBlue,

  -- Tile skill colors (selectable)
  tile_general = lightPurple,
  tile_move = lightBlue,
  tile_support = lightGreen,
  tile_attack = lightRed,
  tile_nothing = lightGray,

  -- Tile skill colors (non-selectable)
  tile_general_off = clearPurple,
  tile_move_off = clearBlue,
  tile_support_off = clearGreen,
  tile_attack_off = clearRed,
  tile_nothing_off = clearGray,

  -- Battle heal/damagge pop-ups
  popup_dmghp = opaqueYellow,
  popup_dmgsp = opaquePink,
  popup_healhp = opaqueGreen,
  popup_healsp = opaqueCyan,
  popup_miss = opaqueGray,
  popup_status_add = white,
  popup_status_remove = white,
  popup_levelup = yellow,
  popup_exp = white,
  
  -- Menu
  menu_text_enabled = white,
  menu_text_disabled = lightGray,
  menu_icon_enabled = white,
  menu_icon_disabled = lightGray,
  barHP = opaqueGreen,
  barSP = opaqueBlue,
  barEXP = opaqueYellow,
  barTC = opaqueRed,
  positive_bonus = green,
  negative_bonus = red,
  element_weak = green,
  element_strong = red,
  element_neutral = white
  
}
