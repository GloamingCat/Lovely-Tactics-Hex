
--[[===============================================================================================

Spinner
---------------------------------------------------------------------------------------------------
A spinner for choosing a numeric value.

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')
local SimpleText = require('core/gui/SimpleText')
local SimpleImage = require('core/gui/SimpleImage')
local GridWidget = require('core/gui/GridWidget')

-- Alias
local Image = love.graphics.newImage

local Spinner = class(GridWidget)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(window  : GridWindow) the window this spinner belongs to.
function Spinner:init(window, initValue, minValue, maxValue)
  GridWidget.init(self, window)
  self.minValue = minValue or -math.huge
  self.maxValue = maxValue or math.huge
  self:initializeContent(initValue or 0)
end
-- Creates arrows and value test.
function Spinner:initializeContent(initValue)
  local dx = self.window:buttonWidth()
  local dy = self.window:buttonHeight() / 2
  -- Left arrow icon
  local leftArrow = Image('images/GUI/Spinner/leftArrow.png')
  local leftArrowSprite = Sprite(GUIManager.renderer, leftArrow)
  leftArrowSprite:setQuad()
  self.leftArrow = SimpleImage(leftArrowSprite, 0, dy)
  -- Right arrow icon
  local rightArrow = Image('images/GUI/Spinner/rightArrow.png')
  local rightArrowSprite = Sprite(GUIManager.renderer, rightArrow)
  rightArrowSprite:setQuad()
  self.rightArrow = SimpleImage(rightArrowSprite, dx, dy)
  -- Value text in the middle
  self.value = initValue
  local textPos = Vector(leftArrow:getWidth(), 0)
  local textWidth = self.window:buttonWidth() - leftArrow:getWidth() - rightArrow:getWidth() 
  self.valueText = SimpleText('' .. initValue, textPos, textWidth, 'center', Font.gui_button)
  -- Add to content list
  self.content:add(self.leftArrow)
  self.content:add(self.rightArrow)
  self.content:add(self.valueText)
end

---------------------------------------------------------------------------------------------------
-- Input Handlers
---------------------------------------------------------------------------------------------------

-- Called when player presses arrows on this spinner.
function Spinner.onMove(window, spinner, dx, dy)
  if dy == 0 then
    if dx < 0 then
      if spinner.value > spinner.minValue then
        spinner:onDecrease()
      end
    else
      if spinner.value < spinner.maxValue then
        spinner:onIncrease()
      end
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Value
---------------------------------------------------------------------------------------------------

-- When presses left arrow on this spinner.
function Spinner:onDecrease()
  self:setValue(self.value - 1)
end
-- When presses right arrow on this spinner.
function Spinner:onIncrease()
  self:setValue(self.value + 1)
end
-- Changes the current value.
-- @param(value : number) new value, assuming it is inside limit bounds
function Spinner:setValue(value)
  if self.value ~= value then
    self.value = value
    self.valueText:setText(value)
    self.valueText:redraw()
  end
end

return Spinner
