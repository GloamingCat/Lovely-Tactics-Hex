
-- ================================================================================================

--- A button with two or more options.
---------------------------------------------------------------------------------------------------
-- @uimod SwitchButton
-- @extend Button

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')

-- Class table.
local SwitchButton = class(Button)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam GridWindow window The window this spinner belongs to.
-- @tparam boolean initValue Initial value.
-- @tparam number x Position x of the switch text relative to the button width (from 0 to 1).
-- @tparam[opt] table values List of possible values. If nil, then the button works as ON/OFF.
function SwitchButton:init(window, initValue, x, values)
  Button.init(self, window)
  self.clickSound = nil
  self.values = values
  x = x or 0.3
  local w = self.window:cellWidth()
  self:initContent(initValue or false, w * x, self.window:cellHeight() / 2, w * (1 - x))
end
--- Creates a button for the action represented by the given key.
-- @tparam GridWindow window The window this spinner belongs to.
-- @tparam string key Action's key.
-- @treturn SwitchButton
function SwitchButton:fromKey(window, key, ...)
  local button = self(window, ...)
  button:setIcon(Config.icons[key])
  if key and Vocab[key] then
    button:createText(key, key, window.buttonFont, 'left')
    if Vocab.manual[key] then
      button.tooltipTerm = key
    end
  end
  button.onConfirm = window[key .. 'Confirm'] or button.onConfirm
  button.onChange = window[key .. 'Change'] or button.onChange
  button.enableCondition = window[key .. 'Enabled'] or button.enableCondition
  button.key = key
  return button
end
--- Creates on/off text.
-- @tparam boolean|number initValue Initial value.
function SwitchButton:initContent(initValue)
  self.value = initValue
  if self.values then
    self:createInfoText(self.values[self.value], '')
  else
    self:createInfoText(self.value and 'on' or 'off', '')
  end
end

-- ------------------------------------------------------------------------------------------------
-- Input
-- ------------------------------------------------------------------------------------------------

--- Implements `Button:onConfirm`. Switches value.
-- @implement
function SwitchButton.onConfirm(window, self)
  if self.values then
    self:changeValue(math.mod1(self.value + 1, #self.values))
  else
    self:changeValue(not self.value)
  end
end
--- Implements `Button:onMove`. Sets value by arrows.
-- @implement
function SwitchButton.onMove(window, self, dx, dy)
  if dx == 0 then
    return
  end
  if self.values then
    self:changeValue(math.mod1(self.value + dx, #self.values))
  else
    self:changeValue(dx > 0)
  end
end
--- Changes current value.
-- @tparam boolean|number value The position of the new value or a boolean if it's an ON/OFF button.
function SwitchButton:changeValue(value)
  if self.enabled and self.value ~= value then
    self:setValue(value)
    if self.onChange then
      self.onChange(self.window, self)
    end
    if self.selectSound then
      AudioManager:playSFX(self.selectSound)
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Value
-- ------------------------------------------------------------------------------------------------

--- Changes the current value.
-- @tparam boolean value New value.
function SwitchButton:setValue(value)
  self.value = value
  if self.values then
    self.infoText:setTerm(self.values[self.value], tostring(self.value))
  else
    self.infoText:setTerm(self.value and 'on' or 'off', tostring(self.value))
  end
  self.infoText:redraw()
end

return SwitchButton
