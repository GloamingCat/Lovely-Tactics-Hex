
Font = {}

local default_font = love.graphics.newFont('fonts/FogSans.otf', 44)
local small_font = love.graphics.newFont('fonts/FogSans.otf', 33)

Font.gui_default = default_font
Font.gui_button = default_font
Font.gui_dialogue = default_font
Font.gui_small = small_font
Font.popup_dmgHP = default_font
Font.popup_dmgEP = default_font
Font.popup_healHP = default_font
Font.popup_healEP = default_font
Font.popup_miss = default_font
Font.fps = love.graphics.newFont('fonts/FogSans.otf', 12)

Font.scale = 4
Font.outlineSize = 4
