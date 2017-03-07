
local Font = {}

local default_font = love.graphics.newFont('fonts/fogsans.otf', 22)

Font.gui_default = default_font
Font.gui_button = default_font
Font.gui_dialogue = default_font
Font.popup_dmgHP = default_font
Font.popup_dmgEP = default_font
Font.popup_healHP = default_font
Font.popup_healEP = default_font
Font.fps = love.graphics.newFont(12)

Font.size = 2

return Font
