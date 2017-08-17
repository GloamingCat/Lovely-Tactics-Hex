
return {
  -- Common colors
  white = {red = 100, green = 100, blue = 100, alpha = 100},
  red = {red = 100, green = 0, blue = 0, alpha = 100},
  green = {red = 0, green = 100, blue = 0, alpha = 100},
  blue = {red = 0, green = 0, blue = 100, alpha = 100},

  -- Tile skill colors (selectable)
  tile_general = {red = 85, green = 50, blue = 85, alpha = 85},
  tile_move = {red = 40, green = 40, blue = 100, alpha = 85},
  tile_support = {red = 40, green = 100, blue = 40, alpha = 85},
  tile_attack = {red = 100, green = 40, blue = 40, alpha = 85},
  tile_nothing = {red = 70, green = 70, blue = 70, alpha = 75},

  -- Tile skill colors (non-selectable)
  tile_general_off = {red = 85, green = 35, blue = 85, alpha = 40},
  tile_move_off = {red = 30, green = 30, blue = 100, alpha = 40},
  tile_support_off = {red = 30, green = 100, blue = 30, alpha = 40},
  tile_attack_off = {red = 100, green = 30, blue = 30, alpha = 40},
  tile_nothing_off = {red = 60, green = 60, blue = 60, alpha = 20},

  -- GUI text colors
  gui_text_default = {red = 100, green = 100, blue = 100, alpha = 100},
  gui_text_disabled = {red = 40, green = 40, blue = 40, alpha = 60},
  gui_text_highlight = {red = 95, green = 50, blue = 100, alpha = 100},

  -- GUI icon colors
  gui_icon_default = {red = 90, green = 90, blue = 90, alpha = 90},
  gui_icon_disabled = {red = 50, green = 50, blue = 50, alpha = 50},
  gui_icon_highlight = {red = 100, green = 100, blue = 100, alpha = 100},

  -- Battle heal/damagge pop-ups
  popup_dmgHP = {red = 100, green = 100, blue = 50, alpha = 100},
  popup_dmgSP = {red = 100, green = 20, blue = 20, alpha = 100},
  popup_healHP = {red = 20, green = 100, blue = 20, alpha = 100},
  popup_healSP = {red = 20, green = 20, blue = 100, alpha = 100},
  popup_miss = {red = 80, green = 80, blue = 80, alpha = 100},
  popup_status = {red = 100, green = 100, blue = 100, alpha = 100},

  -- Convertion from percentage to byte value
  factor = 255 / 100
}
