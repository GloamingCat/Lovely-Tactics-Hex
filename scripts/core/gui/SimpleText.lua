
--[[===============================================================================================

SimpleText
---------------------------------------------------------------------------------------------------
A simple content element for GUI window containing just a text.
It's a type of window content.

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')
local Text = require('core/graphics/Text')

local SimpleText = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(text : string) the text content (not rich text)
-- @param(relativePosition : Vector) position relative to its window (optional)
-- @param(width : number) the max width for texto box (optional)
-- @param(align : string) alignment inside the box (optional, left by default)
-- @param(font : Font) font of the text (optional)
-- @param(color : table) color of the text (optional)
function SimpleText:init(text, relativePosition, width, align, font, color)
  local resources = {
    c = color or Color.gui_text_default, 
    f = font or Font.gui_default
  }
  local p = {width, align or 'left'}
  assert(text, 'nil text')
  if text ~= '' then
    text = '{c}{f}' .. text
  end
  self.resources = resources
  self.sprite = Text(text, resources, p, GUIManager.renderer)
  self.text = text
  self.relativePosition = relativePosition or Vector(0, 0, 0)
end
-- Changes text content.
-- @param(text : string) the new text content
function SimpleText:setText(text)
  if text ~= '' then
    text = '{c}{f}' .. text
  end
  self.text = text
end
-- Changes text color. 
function SimpleText:setFont(font)
  self.resources.f = font
end
-- Changes text font.
function SimpleText:setColor(color)
  self.resources.c = color
end
-- Redraws text.
function SimpleText:redraw()
  self.sprite:setText(self.text, self.resources)
end

---------------------------------------------------------------------------------------------------
-- Window Content methods
---------------------------------------------------------------------------------------------------

-- Hides text.
function SimpleText:show()
  self.sprite:setVisible(true)
end
-- Shows text.
function SimpleText:hide()
  self.sprite:setVisible(false)
end
-- Sets position relative to its parent window.
-- @param(pos : Vector) window position
function SimpleText:updatePosition(pos)
  local rpos = self.relativePosition
  self.sprite:setXYZ(pos.x + rpos.x, pos.y + rpos.y, pos.z + rpos.z)
end
-- Removes text.
function SimpleText:destroy()
  self.sprite:destroy()
end

return SimpleText
