
--[[===============================================================================================

TextInputWindow
---------------------------------------------------------------------------------------------------
Window to choose a number given a max limit.

=================================================================================================]]

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')
local TextBox = require('core/gui/widget/TextBox')
local Vector = require('core/math/Vector')

local TextInputWindow = class(GridWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides Window:init.
function TextInputWindow:init(gui, emptyAllowed, cancelAllowed, ...)
  self.emptyAllowed = emptyAllowed
  self.cancelAllowed = cancelAllowed
  self.maxLength = math.huge
  GridWindow.init(self, gui, ...)
end
-- Implements GridWindow:createWidgets.
-- Create confirm and cancel buttons.
function TextInputWindow:createWidgets()
  self.confirmButton = Button:fromKey(self, 'confirm')
  self.cancelButton = Button:fromKey(self, 'cancel')
  self.cancelButton.confirmSound = Config.sounds.buttonCancel
  self.cancelButton.clickSound = Config.sounds.buttonCancel
end
-- Overrides GridWindow:createContent.
-- Creates text box.
function TextInputWindow:createContent(width, height, ...)
  GridWindow.createContent(self, width, height, ...)
  local pos = Vector(-self.width / 2 + self:paddingX(), -self.height / 2 + self:paddingY(), -1)
  local textBox = TextBox(self, '', pos)
  self.textBox = textBox
  self.content:add(textBox)
end

---------------------------------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------------------------------

-- Sets current text.
function TextInputWindow:setText(text)
  self.textBox:setText(text)
  self.textBox.cursorPoint = #text + 1
  self.textBox:refreshCursor()
end
-- Sets text's maximum length.
function TextInputWindow:setMaxLength(maxLength)
  self.maxLength = maxLength
end

---------------------------------------------------------------------------------------------------
-- Buttons
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:onConfirm.
-- If no button is selected, then choose confirm button.
function TextInputWindow:onConfirm()
  local widget = self:currentWidget() or self.confirmButton
  GridWindow.onConfirm(self, widget)
end
-- Overrides GridWindow:onCancel.
-- If no button is selected, then choose cancel button.
function TextInputWindow:onCancel()
  if self.cancelAllowed then
    local widget = self:currentWidget() or self.cancelButton
    GridWindow.onCancel(self, widget)
  end
end
-- Returns current input.
function TextInputWindow:confirmConfirm(button)
  self.result = self.textBox.input
  InputManager:endTextInput()
end
-- Cancels and returns invalid input.
function TextInputWindow:cancelConfirm(button)
  self.result = 0
  InputManager:endTextInput()
end
-- Confirm button enabled only if text input is valid.
function TextInputWindow:confirmEnabled(button)
  return self.emptyAllowed or self.textBox.input ~= ''
end
-- Cancel button enabled only if text input is optional.
function TextInputWindow:cancelEnabled(button)
  return self.cancelAllowed
end

---------------------------------------------------------------------------------------------------
-- Input handlers
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:onTextInput.
-- Updates current text.
function TextInputWindow:onTextInput(c)
  if c == 'backspace' then
    if #self.textBox.input >= self.textBox.cursorPoint - 1 then
      self.textBox:eraseCharacter()
      if self.onTextChange then
        self:onTextChange(self.textBox.input)
      end
    else
      AudioManager:playSFX(Config.sounds.buttonError)
      return
    end
  else
    if #self.textBox.input < self.maxLength then
      self.textBox:insertCharacter(c)
      if self.onTextChange then
        self:onTextChange(self.textBox.input)
      end
    else
      AudioManager:playSFX(Config.sounds.buttonError)
      return
    end
  end
  self.confirmButton:refreshEnabled()
end
-- Shows text cursor.
function TextInputWindow:selectText()
  self.textBox:setCursorVisible(true)
  self:setSelectedWidget(nil)
  InputManager:startTextInput()
end
-- Hides test cursor.
function TextInputWindow:deselectText()
  self.textBox:setCursorVisible(false)
  self:setSelectedWidget(self:currentWidget())
  InputManager:endTextInput()
end
-- Overrides GridWindow:setSelectedWidget.
-- Hides text cursor.
function TextInputWindow:setSelectedWidget(widget)
  if widget ~= nil then
    self.textBox:setCursorVisible(false)
    InputManager:endTextInput()
  end
  GridWindow.setSelectedWidget(self, widget)
end
-- Overrides GridWindow:onMove.
-- Updates current selected widget.
function TextInputWindow:onMove(dx, dy)
  if dy < 0 then
    if self.currentRow == 1 then
      self.currentRow = 0
      self:selectText()
      return
    elseif self.currentRow == 0 then
      self.currentRow = self:rowCount()
      self:deselectText()
      return
    end
  elseif dy > 0 then
    if self.currentRow == 0 then
      self.currentRow = 1
      self:deselectText()
      return
    elseif self.currentRow == self:rowCount() then
      self.currentRow = 0
      self:selectText()
      return
    end
  elseif dx ~= 0 then
    if self.currentRow == 0 then
      self.textBox:moveCursor(dx)
      return
    end
  end
  GridWindow.onMove(self, dx, dy)
end
-- Overrides GridWindow:show.
-- Start text input.
function TextInputWindow:show(...)
  self.currentRow = 0
  GridWindow.show(self, ...)
  self:setSelectedWidget(nil)
  InputManager:startTextInput()
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- @ret(number) Grid y-axis displacement in pixels.
function TextInputWindow:gridY()
  return self:cellHeight() + self:rowMargin()
end
-- Overrides GridWindow:colCount.
function TextInputWindow:colCount()
  return 2
end
-- Overrides GridWindow:rowCount.
function TextInputWindow:rowCount()
  return 1
end
-- @ret(string) String representation (for debugging).
function TextInputWindow:__tostring()
  return 'Text Input Window'
end

return TextInputWindow
