
-- ================================================================================================

--- A side bar to scroll through windows.
-- It's a type of window content.
-- ------------------------------------------------------------------------------------------------
-- @classmod VSlider

-- ================================================================================================

-- Imports
local Component = require('core/gui/Component')
local Sprite = require('core/graphics/Sprite')

-- Alias
local Image = love.graphics.newImage

-- Class table.
local VSlider = class(Component)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Window window Parent window.
-- @tparam Vector position Position relative to its parent window's position.
-- @tparam number length Length of slider.
function VSlider:init(window, position, length)
  Component.init(self, position, length)
  self.window = window
  window.content:add(self)
end
--- Overrides Component:createContent.
function VSlider:createContent(length)
  self.length = length
  local bar = Image(Project.imagePath .. 'GUI/VSlider/bar.png')
  self.bar = Sprite(GUIManager.renderer, bar)
  self.bar:setQuad(nil, nil, nil, length)
  self.bar:setCenterOffset(-2)
  self.content:add(self.bar)
  local upArrow = Image(Project.imagePath .. 'GUI/VSlider/upArrow.png')
  self.upArrow = Sprite(GUIManager.renderer, upArrow)
  self.upArrow:setQuad()
  self.upArrow:setCenterOffset(-2)
  self.content:add(self.upArrow)
  local downArrow = Image(Project.imagePath .. 'GUI/VSlider/downArrow.png')
  self.downArrow = Sprite(GUIManager.renderer, downArrow)
  self.downArrow:setQuad()
  self.downArrow:setCenterOffset(-2)
  self.content:add(self.downArrow)
  local cursor = Image(Project.imagePath .. 'GUI/VSlider/cursor.png')
  self.cursor = Sprite(GUIManager.renderer, cursor)
  self.cursor:setQuad()
  self.cursor:setCenterOffset(-2)
  self.content:add(self.cursor)
end

-- ------------------------------------------------------------------------------------------------
-- Position
-- ------------------------------------------------------------------------------------------------

--- Overrides Component:updatePosition.
function VSlider:updatePosition(pos)
  pos = pos + self.position
  self.bar:setXYZ(pos.x, pos.y)
  self.upArrow:setXYZ(pos.x, pos.y - self.length / 2)
  self.downArrow:setXYZ(pos.x, pos.y + self.length / 2)
  self:updateCursorPosition(pos)
end
-- @tparam Vector pos Center position.
function VSlider:updateCursorPosition(pos)
  local length = self.length - self.upArrow.offsetY - self.downArrow.offsetY
  local t = self.window.offsetRow / (self.window:actualRowCount() - self.window:rowCount())
  self.cursor:setXYZ(pos.x, pos.y + length * (t - 0.5))
end

return VSlider
