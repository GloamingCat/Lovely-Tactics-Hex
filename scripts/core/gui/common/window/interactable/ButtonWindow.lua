
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
function ButtonWindow:init(gui, names, align, ...)
  if type(names) == 'string' then
    self.buttonNames = {names}
    self.noCursor = true
    self.noHighlight = true
  else
    self.buttonNames = names
  end
  self.align = align or 'center'
  GridWindow.init(self, gui, ...)
end
-- Implements GridWindow:creatwWidgets.
-- Creates a button for each choice.
function ButtonWindow:createWidgets()
  for _, name in ipairs(self.buttonNames) do
    local button = Button(self)
    button.confirmSound = nil
    button.selectSound = nil
    button.cancelSound = nil
    button:createText(name, 'gui_medium', self.align)
  end
end

---------------------------------------------------------------------------------------------------
-- Input Callbacks
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:update.
-- Opens or closes automatically depending if the player is using the mouse or not.
function ButtonWindow:update()
  if self.lastOpen and self.GUI.open then
    if InputManager.usingKeyboard and not InputManager.mouse.active then
      if self.open then
        GUIManager.fiberList:fork(self.hide, self)
      end
    else
      if self.closed then
        GUIManager.fiberList:fork(self.show, self, true)
      end
    end
  end
  GridWindow.update(self)
end
-- Overrides GridWindow:checkInput.
-- Ignores keyboard input.
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

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function ButtonWindow:colCount()
  return 1
end
-- Overrides GridWindow:rowCount.
function ButtonWindow:rowCount()
  return #self.buttonNames
end
-- Overrides GridWindow:cellWidth.
function ButtonWindow:cellWidth()
  return (self.width or 50) - self:paddingX() * 2
end
-- @ret(string) String representation (for debugging).
function ButtonWindow:__tostring()
  return self.buttonNames[1] .. ' Button Window'
end

return ButtonWindow
