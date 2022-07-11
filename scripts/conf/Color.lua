
local black = {red = 0, green = 0, blue = 0, alpha = 1}
local red = {red = 1, green = 0, blue = 0, alpha = 1}
local green = {red = 0, green = 1, blue = 0, alpha = 1}
local blue = {red = 0, green = 0, blue = 1, alpha = 1}
local yellow = {red = 1, green = 1, blue = 0, alpha = 1}
local magenta = {red = 1, green = 0, blue = 1, alpha = 1}
local cyan = {red = 0, green = 1, blue = 1, alpha = 1}
local white = {red = 1, green = 1, blue = 1, alpha = 1}

local babypink = {red = 1, green = 0.55, blue = 0.95, alpha = 1}
local babyblue = {red = 0.65, green = 0.7, blue = 1, alpha = 1}
local lightgray = {red = 0.8, green = 0.8, blue = 0.8, alpha = 0.8}

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
  babyblue = babyblue,

  -- Tile skill colors (selectable)
  tile_general = {red = 0.85, green = 0.5, blue = 0.85, alpha = 0.85},
  tile_move = {red = 0.4, green = 0.4, blue = 1, alpha = 0.85},
  tile_support = {red = 0.4, green = 1, blue = 0.4, alpha = 0.85},
  tile_attack = {red = 1, green = 0.4, blue = 0.4, alpha = 0.85},
  tile_nothing = {red = 0.7, green = 0.7, blue = 0.7, alpha = 0.75},

  -- Tile skill colors (non-selectable)
  tile_general_off = {red = 0.8, green = 0.45, blue = 0.8, alpha = 0.4},
  tile_move_off = {red = 0.3, green = 0.3, blue = 1, alpha = 0.4},
  tile_support_off = {red = 0.3, green = 1, blue = 0.3, alpha = 0.4},
  tile_attack_off = {red = 1, green = 0.3, blue = 0.3, alpha = 0.4},
  tile_nothing_off = {red = 0.6, green = 0.6, blue = 0.6, alpha = 0.2},

  -- Battle heal/damagge pop-ups
  popup_dmghp = {red = 1, green = 1, blue = 0.5, alpha = 1},
  popup_dmgsp = {red = 1, green = 0.3, blue = 0.3, alpha = 1},
  popup_healhp = {red = 0.3, green = 1, blue = 0.3, alpha = 1},
  popup_healsp = {red = 0.3, green = 0.3, blue = 1, alpha = 1},
  popup_miss = {red = 0.8, green = 0.8, blue = 0.8, alpha = 1},
  popup_status_add = white,
  popup_status_remove = white,
  popup_levelup = yellow,
  
  -- GUI
  gui_text_enabled = white,
  gui_text_disabled = lightgray,
  gui_icon_enabled = white,
  gui_icon_disabled = lightgray,
  barHP = {red = 0.2, green = 1, blue = 0.4, alpha = 1},
  barSP = {red = 0.2, green = 0.4, blue = 1, alpha = 1},
  barEXP = {red = 1, green = 1, blue = 0.4, alpha = 1},
  barTC = {red = 1, green = 0.8, blue = 0.4, alpha = 1},
  element_weak = green,
  element_strong = red,
  element_neutral = white
  
}
