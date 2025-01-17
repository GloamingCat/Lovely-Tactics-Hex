
-- ================================================================================================

--- A horizontal spinner for choosing a numeric value.
---------------------------------------------------------------------------------------------------
-- @uimod HSpinner
-- @extend GridWidget

-- ================================================================================================

-- Imports
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')
local TextComponent = require('core/gui/widget/TextComponent')
local ImageComponent = require('core/gui/widget/ImageComponent')
local GridWidget = require('core/gui/widget/control/GridWidget')

-- Class table.
local HSpinner = class(GridWidget)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam GridWindow window The window this spinner belongs to.
-- @tparam number minValue Minimum value.
-- @tparam number maxValue Maximum value.
-- @tparam number initValue Initial value.
function HSpinner:init(window, minValue, maxValue, initValue)
  self.enabled = true
  self.margin = 2
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
function HSpinner:initContent(initValue, w, h, x, y)
  x, y = x or 0, y or 0
  x = x + self.margin
  w = w - self.margin * 2
  local animID = Config.animations.arrow
  -- Left arrow
  local leftArrowSprite = ResourceManager:loadIcon({id = animID, col = 1, row = 1}, MenuManager.renderer)
  self.leftArrow = ImageComponent(leftArrowSprite, Vector(x, y + h / 2))
  -- Right arrow
  local rightArrowSprite = ResourceManager:loadIcon({id = animID, col = 0, row = 0}, MenuManager.renderer)
  self.rightArrow = ImageComponent(rightArrowSprite, Vector(x + w, y + h / 2))
  -- Value text in the middle
  self.value = initValue
  self.valueText = TextComponent(tostring(initValue), Vector(x, y), w, 'center', Fonts.menu_button)
  self.valueText.sprite.maxHeight = h
  self.valueText.sprite.alignY = 'center'
  -- Add to content list
  self.content:add(self.leftArrow)
  self.content:add(self.rightArrow)
  self.content:add(self.valueText)
  -- Bounds
  self.width = w + self.margin * 2
  self.height = h
  self.x = x - self.margin
  self.y = y 
end

-- ------------------------------------------------------------------------------------------------
-- Input Handlers
-- ------------------------------------------------------------------------------------------------

--- Called when player presses arrows on this spinner.
function HSpinner.onMove(window, self, dx, dy)
  if dx ~= 0 then
    self:changeValue(dx, dy)
  end
end
--- Called when player presses a mouse button.
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

-- ------------------------------------------------------------------------------------------------
-- Value
-- ------------------------------------------------------------------------------------------------

--- Changes the current value according to input.
-- @tparam number dx Input axis X.
-- @tparam number dy Input axis Y.
function HSpinner:changeValue(dx, dy)
  dx = dx * self:multiplier()
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
--- Changes the current value.
-- @tparam number value New value, assuming it is inside limit bounds.
function HSpinner:setValue(value)
  if self.value ~= value then
    self.value = value
    self.valueText:setText(value .. '')
    self.valueText:redraw()
  end
end
--- The values the multiplies the change input.
-- @treturn number
function HSpinner:multiplier()
  return InputManager.keys['dash']:isPressing()
      and self.bigIncrement or 1
end

return HSpinner
