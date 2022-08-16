
--[[===============================================================================================

ButtonWindow
---------------------------------------------------------------------------------------------------
Shows a list of custom choices.

=================================================================================================]]

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')
local List = require('core/datastruct/List')

local ButtonWindow = class(GridWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(gui : GUI) Parent GUI.
-- @param(args : table) Table of arguments, including choies, width, align and cancel choice ID.
function ButtonWindow:init(GUI, name, ...)
  self.align = 'center'
  self.buttonName = name
  GridWindow.init(self, GUI, ...)
end
-- Implements GridWindow:creatwWidgets.
-- Creates a button for each choice.
function ButtonWindow:createWidgets()
  local button = Button(self)
  button.confirmSound = nil
  button.selectSound = nil
  button.cancelSound = nil
  button:createText(self.buttonName, 'gui_medium', self.align)
end

---------------------------------------------------------------------------------------------------
-- Input Callbacks
---------------------------------------------------------------------------------------------------

function ButtonWindow:checkInput()
  if not self.open then
    return
  end
  local x, y = InputManager.mouse:guiCoord()
  x, y = x - self.position.x, y - self.position.y
  if InputManager.keys['mouse1']:isTriggered() then
    self:onClick(1, x, y)
  elseif InputManager.keys['mouse2']:isTriggered() then
    self:onClick(2, x, y)
  elseif InputManager.keys['mouse3']:isTriggered() then
    self:onClick(3, x, y)
  elseif InputManager.keys['touch']:isTriggered() then
    self:onClick(5, x, y)
  elseif InputManager.keys['touch']:isTriggered() then
    self:onClick(4, x, y)
  elseif InputManager.mouse.moved then
    self:onMouseMove(x, y)
  end
end
-- Overrides ButtonWindow:onCancel.
function ButtonWindow:onButtonConfirm(button)
  self.result = 1
end
-- Overrides GridWindow:onCancel.
function ButtonWindow:onCancel()
  self.result = 0
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function ButtonWindow:colCount()
  return 1
end
-- Overrides GridWindow:rowCount.
function ButtonWindow:rowCount()
  return 1
end
-- Overrides GridWindow:cellWidth.
function ButtonWindow:cellWidth()
  return (self.width or 50) - self:paddingX() * 2
end
-- @ret(string) String representation (for debugging).
function ButtonWindow:__tostring()
  return self.buttonName .. ' Button Window'
end

return ButtonWindow
