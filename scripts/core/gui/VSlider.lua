
--[[===============================================================================================

VSlider
---------------------------------------------------------------------------------------------------
A side bar to scroll through windows.
It's a type of window content.

=================================================================================================]]

-- Imports
local Sprite = require('core/graphics/Sprite')

-- Alias
local Image = love.graphics.newImage

local VSlider = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

function VSlider:init(window, relativePosition, length)
  window.content:add(self)
  self.window = window
  self.relativePosition = relativePosition
  self.length = length
  local bar = Image('images/GUI/VSlider/bar.png')
  self.bar = Sprite(GUIManager.renderer, bar)
  self.bar:setQuad(nil, nil, nil, length)
  self.bar:setCenterOffset(-2)
  local upArrow = Image('images/GUI/VSlider/upArrow.png')
  self.upArrow = Sprite(GUIManager.renderer, upArrow)
  self.upArrow:setQuad()
  self.upArrow:setCenterOffset(-2)
  local downArrow = Image('images/GUI/VSlider/downArrow.png')
  self.downArrow = Sprite(GUIManager.renderer, downArrow)
  self.downArrow:setQuad()
  self.downArrow:setCenterOffset(-2)
  local cursor = Image('images/GUI/VSlider/cursor.png')
  self.cursor = Sprite(GUIManager.renderer, cursor)
  self.cursor:setQuad()
  self.cursor:setCenterOffset(-2)
end

---------------------------------------------------------------------------------------------------
-- Position
---------------------------------------------------------------------------------------------------

function VSlider:updatePosition(pos)
  pos = pos + self.relativePosition
  self.bar:setXYZ(pos.x, pos.y)
  self.upArrow:setXYZ(pos.x, pos.y - self.length / 2)
  self.downArrow:setXYZ(pos.x, pos.y + self.length / 2)
  self:updateCursorPosition(pos)
end

function VSlider:updateCursorPosition(pos)
  local length = self.length - self.upArrow.offsetY - self.downArrow.offsetY
  local t = self.window.offsetRow / (self.window:actualRowCount() - self.window:rowCount())
  self.cursor:setXYZ(pos.x, pos.y + length * (t - 0.5))
end

---------------------------------------------------------------------------------------------------
-- Content methods
---------------------------------------------------------------------------------------------------

function VSlider:show()
  self.bar:setVisible(true)
  self.upArrow:setVisible(true)
  self.downArrow:setVisible(true)
  self.cursor:setVisible(true)
end

function VSlider:hide()
  self.bar:setVisible(false)
  self.upArrow:setVisible(false)
  self.downArrow:setVisible(false)
  self.cursor:setVisible(false)
end

function VSlider:destroy()
  self.bar:removeSelf()
  self.upArrow:removeSelf()
  self.downArrow:removeSelf()
  self.cursor:removeSelf()
end

return VSlider
