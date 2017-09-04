
local default_font = love.graphics.newFont('fonts/FogSans.otf', 44)
local small_font = love.graphics.newFont('fonts/FogSans.otf', 33)

return  {
  
  -- Fonts
  gui_default = default_font,
  gui_button = default_font,
  gui_dialogue = default_font,
  gui_small = small_font,
  popup_dmghp = default_font,
  popup_dmgsp = default_font,
  popup_healhp = default_font,
  popup_healsp = default_font,
  popup_miss = default_font,
  popup_status = default_font,
  fps = love.graphics.newFont('fonts/FogSans.otf', 12),
  
  -- Settings
  scale = 4,
  outlineSize = 4
  
}
