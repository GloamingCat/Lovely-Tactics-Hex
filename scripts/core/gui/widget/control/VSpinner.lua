
-- ================================================================================================

--- A spinner for choosing a numeric value.
-- ------------------------------------------------------------------------------------------------
-- @classmod VSpinner

-- ================================================================================================

-- Imports
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')
local SimpleText = require('core/gui/widget/SimpleText')
local SimpleImage = require('core/gui/widget/SimpleImage')
local GridWidget = require('core/gui/widget/control/GridWidget')

-- Alias
local Image = love.graphics.newImage

-- Class table.
local VSpinner = class(GridWidget)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam GridWindow window The window this spinner belongs to.
-- @tparam number minValue Minimum value.
-- @tparam number maxValue Maximum value.
-- @tparam number initValue Initial value.
function VSpinner:init(window, minValue, maxValue, initValue)
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
--- Creates arrows and value test.
function VSpinner:initContent(initValue, w, h, x, y)
  x, y = x or 0, y or 0
  local animID = Config.animations.arrow
  -- Left arrow
  local downArrowSprite = ResourceManager:loadIcon({id = animID, col = 1, row = 0}, GUIManager.renderer)
  local dw, dh = downArrowSprite:quadBounds()
  self.downArrow = SimpleImage(downArrowSprite, x + (w - dw) / 2, y + h - dh)
  -- Right arrow
  local upArrowSprite = ResourceManager:loadIcon({id = animID, col = 0, row = 1}, GUIManager.renderer)
  local uw, uh = upArrowSprite:quadBounds()
  self.upArrow = SimpleImage(upArrowSprite, x + (w - uw) / 2, y)
  -- Value text in the middle
  self.value = initValue
  local textPos = Vector(x, y)
  self.valueText = SimpleText(tostring(initValue), textPos, w, 'center', Fonts.gui_button)
  self.valueText.sprite.maxHeight = h
  self.valueText.sprite.alignY = 'center'
  -- Add to content list
  self.content:add(self.downArrow)
  self.content:add(self.upArrow)
  self.content:add(self.valueText)
  -- Bounds
  self.width = w
  self.height = h
  self.x = x
  self.y = y
end

-- ------------------------------------------------------------------------------------------------
-- Input Handlers
-- ------------------------------------------------------------------------------------------------

--- Called when player presses arrows on this spinner.
function VSpinner.onMove(window, self, dx, dy)
  if dy ~= 0 then
    self:changeValue(dx, -dy)
  end
end
--- Called when player presses a mouse button.
function VSpinner.onClick(window, self, x, y)
  local pos = self:relativePosition()
  x, y = x - pos.x, y - pos.y
  if x < self.x or y < self.y or x > self.x + self.width or y > self.y + self.height then
    return
  end
  if y <= self.y + self.height / 4 then
    self:changeValue(0, 1)
  elseif y >= self.height * 3 / 4 + self.y then
    self:changeValue(0, -1)
  else
    return
  end
end

-- ------------------------------------------------------------------------------------------------
-- Value
-- ------------------------------------------------------------------------------------------------

--- Changes the current value according to input.
-- @tparam number dx Input axis X.
-- @tparam number dy Input axis Y.
function VSpinner:changeValue(dx, dy)
  dy = dy * self:multiplier()
  local value = math.min(self.maxValue, math.max(self.minValue, self.value + dy))
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
--- Changes the current value.
-- @tparam number value New value, assuming it is inside limit bounds.
function VSpinner:setValue(value)
  if self.value ~= value then
    self.value = value
    self.valueText:setText(value .. '')
    self.valueText:redraw()
  end
end
--- The values the multiplies the change input.
-- @treturn number
function VSpinner:multiplier()
  return InputManager.keys['dash']:isPressing()
      and self.bigIncrement or 1
end

return VSpinner