
--[[===========================================================================

SimpleText
-------------------------------------------------------------------------------
A simple content element for GUI window containing just a text.
It's a type of window content.

=============================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')
local Text = require('core/graphics/Text')

local SimpleText = require('core/class'):new()

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------

function SimpleText:init(text, relativePosition, width, font, align)
  font = font or Font.gui_default
  align = align or 'left'
  self.sprite = Text(text, nil, {width, align, nil, font}, GUIManager.renderer)
  self.text = text
  self.relativePosition = relativePosition or Vector(0, 0, 0)
end

function SimpleText:setText(text)
  self.sprite:setText(text)
end

-------------------------------------------------------------------------------
-- Window Content methods
-------------------------------------------------------------------------------

function SimpleText:show()
  self.sprite:setVisible(true)
end

function SimpleText:hide()
  self.sprite:setVisible(false)
end

function SimpleText:updatePosition(pos)
  local rpos = self.relativePosition
  self.sprite:setXYZ(pos.x + rpos.x, pos.y + rpos.y, pos.z + rpos.z)
end

function SimpleText:destroy()
  self.sprite:removeSelf()
end

return SimpleText
