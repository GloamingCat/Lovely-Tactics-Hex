
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')
local Text = require('core/graphics/Text')
local Font = require('custom/Font')

--[[===========================================================================

A simple content element for GUI window containing just a text.

=============================================================================]]

local SimpleText = require('core/class'):new()

function SimpleText:init(text, relativePosition, width, font, align)
  font = font or Font.gui_default
  self.sprite = Text({'{font}' .. text, width, align or 'left', font = font}, GUIManager.renderer)
  self.text = text
  self.width = width
  self.align = align
  self.font = font
  self.relativePosition = relativePosition or Vector(0, 0, 0)
end

function SimpleText:setText(text)
  self.sprite:setText({'{font}' .. text, self.width, self.align or 'left', font = self.font})
end

function SimpleText:update()
end

function SimpleText:show()
  self.sprite:setVisible(true)
end

function SimpleText:hide()
  self.sprite:setVisible(false)
end

function SimpleText:updatePosition(pos)
  self.sprite:setPosition(pos + self.relativePosition)
end

function SimpleText:destroy()
  self.sprite:removeSelf()
end

return SimpleText
