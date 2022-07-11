
--[[===============================================================================================

SwitchButton
---------------------------------------------------------------------------------------------------
A button two options.

=================================================================================================]]

-- Imports
local Button = require('core/gui/widget/control/Button')

local SwitchButton = class(Button)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(window  : GridWindow) The window this spinner belongs to.
-- @param(initValue : boolean) Initial value.
-- @param(x : number) Position x of the switch text relative to the button width (from 0 to 1).
function SwitchButton:init(window, initValue, x)
  Button.init(self, window)
  x = x or 0.3
  local w = self.window:cellWidth()
  self:initContent(initValue or false, w * x, self.window:cellHeight() / 2, w * (1 - x))
end
-- Creates a button for the action represented by the given key.
-- @param(window : GridWindow) The window that this button is component of.
-- @param(key : string) Action's key.
-- @ret(SwitchButton)
function SwitchButton:fromKey(window, key, initValue)
  local button = self(window, initValue)
  local icon = Config.icons[key]
  if icon then
    button:createIcon(icon)
  end
  local text = Vocab[key]
  if text then
    button:createText(text)
  end
  button.onConfirm = window[key .. 'Confirm'] or button.onConfirm
  button.onChange = window[key .. 'Change'] or button.onChange
  button.enableCondition = window[key .. 'Enabled'] or button.enableCondition
  button.key = key
  return button
end
-- Creates on/off text.
-- @param(initValue : boolean) Initial value.
function SwitchButton:initContent(initValue)
  self.value = initValue
  local text = self.value and Vocab.on or Vocab.off
  self:createInfoText(text)
end

---------------------------------------------------------------------------------------------------
-- Input
---------------------------------------------------------------------------------------------------

-- Switches value.
function SwitchButton.onConfirm(window, self)
  self:changeValue(not self.value)
end
-- Sets value by arrows.
function SwitchButton.onMove(window, self, dx, dy)
  if dx ~= 0 then
    self:changeValue(dx > 0)
  end
end
-- Changes current value.
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

---------------------------------------------------------------------------------------------------
-- Value
---------------------------------------------------------------------------------------------------

-- Changes the current value.
-- @param(value : boolean) New value.
function SwitchButton:setValue(value)
  self.value = value
  self.infoText:setText(self.value and Vocab.on or Vocab.off)
  self.infoText:redraw()
end

return SwitchButton
