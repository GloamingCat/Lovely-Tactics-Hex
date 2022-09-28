
--[[===============================================================================================

HSpinner
---------------------------------------------------------------------------------------------------
A horizontal spinner for choosing a numeric value.

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')
local SimpleText = require('core/gui/widget/SimpleText')
local SimpleImage = require('core/gui/widget/SimpleImage')
local GridWidget = require('core/gui/widget/control/GridWidget')

-- Alias
local Image = love.graphics.newImage

local HSpinner = class(GridWidget)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(window  : GridWindow) the window this spinner belongs to.
-- @param(minValue : number) Minimum value.
-- @param(maxValue : number) Maximum value.
-- @param(initValue : number) Initial value.
function HSpinner:init(window, minValue, maxValue, initValue)
  self.enabled = true
  GridWidget.init(self, window)
  self.clickSound = nil
  self.onConfirm = self.onConfirm or window.onSpinnerConfirm
  self.onCancel = self.onCancel or window.onSpinnerCancel
  self.onChange = self.onChange or window.onSpinnerChange
  self.minValue = minValue or -math.huge
  self.maxValue = maxValue or math.huge
  self:initContent(initValue or 0, self.window:cellWidth(), self.window:cellHeight())
end
-- Creates arrows and value test.
function HSpinner:initContent(initValue, w, h, x, y)
  x, y = x or 0, y or 0
  local animID = Config.animations.arrow
  -- Left arrow
  local leftArrowSprite = ResourceManager:loadIcon({id = animID, col = 1, row = 1}, GUIManager.renderer)
  local lw, lh = leftArrowSprite:quadBounds()
  self.leftArrow = SimpleImage(leftArrowSprite, x, y + (h - lh) / 2)
  -- Right arrow
  local rightArrowSprite = ResourceManager:loadIcon({id = animID, col = 0, row = 0}, GUIManager.renderer)
  local rw, rh = rightArrowSprite:quadBounds()
  self.rightArrow = SimpleImage(rightArrowSprite, x + w - rw, y + (h - rh) / 2)
  -- Value text in the middle
  self.value = initValue
  local textPos = Vector(x, y)
  self.valueText = SimpleText(tostring(initValue), textPos, w, 'center', Fonts.gui_button)
  self.valueText.sprite.maxHeight = h
  self.valueText.sprite.alignY = 'center'
  -- Add to content list
  self.content:add(self.leftArrow)
  self.content:add(self.rightArrow)
  self.content:add(self.valueText)
  -- Bounds
  self.width = w
  self.height = h
  self.x = x
  self.y = y
end

---------------------------------------------------------------------------------------------------
-- Input Handlers
---------------------------------------------------------------------------------------------------

-- Called when player presses arrows on this spinner.
function HSpinner.onMove(window, self, dx, dy)
  if dx ~= 0 then
    self:changeValue(dx, dy)
  end
end
-- Called when player presses a mouse button.
function HSpinner.onClick(window, self, x, y)
  local pos = self:relativePosition()
  x, y = x - pos.x, y - pos.y
  if x < self.x or y < self.y or x > self.x + self.width or y > self.y + self.height then
    return
  end
  if x <= self.x + self.width / 4 then
    self:changeValue(-1, 0)
  elseif x >= self.width * 3 / 4 + self.x then
    self:changeValue(1, 0)
  else
    return
  end
end

---------------------------------------------------------------------------------------------------
-- Value
---------------------------------------------------------------------------------------------------

-- Changes the current value according to input.
-- @param(dx : number) Input axis X.
-- @param(dy : number) Input axis Y.
function HSpinner:changeValue(dx, dy, click)
  local bigIncrement = InputManager.keys['dash']:isPressing()
    or InputManager.keys['mouse1']:isDoubleTriggered()
    or InputManager.keys['touch']:isDoubleTriggered()
  if self.bigIncrement and bigIncrement then
    dx = dx * self.bigIncrement
  end
  local value = math.min(self.maxValue, math.max(self.minValue, self.value + dx))
  if self.enabled then
    self:setValue(value)
    if self.onChange then
      self.onChange(self.window, self)
    end
    if self.selectSound then
      AudioManager:playSFX(self.selectSound)
    end
  end
end
-- Changes the current value.
-- @param(value : number) new value, assuming it is inside limit bounds
function HSpinner:setValue(value)
  if self.value ~= value then
    self.value = value
    self.valueText:setText(value .. '')
    self.valueText:redraw()
  end
end

return HSpinner
