
-- ================================================================================================

--- Shows a list of custom choices.
---------------------------------------------------------------------------------------------------
-- @classmod ButtonWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')
local List = require('core/datastruct/List')

-- Class table.
local ButtonWindow = class(GridWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam GUI parent Parent GUI.
-- @tparam table names A list of the names (keys) of the buttons.
-- @tparam string align The horizontal alignment of the text in the buttons.
-- @param ... Other parameters from the GridWindow constructor.
function ButtonWindow:init(parent, names, align, ...)
  if type(names) == 'string' then
    self.buttonNames = {names}
    self.noCursor = true
    self.noHighlight = true
  else
    self.buttonNames = names
  end
  self.align = align or 'center'
  GridWindow.init(self, parent, ...)
  self.offBoundsCancel = false
  self.active = true
end
--- Implements `GridWindow:createWidgets`. Creates a button for each choice.
-- @implement createWidgets
function ButtonWindow:createWidgets()
  for _, name in ipairs(self.buttonNames) do
    local button = Button:fromKey(self, name)
    button.text:setAlign(self.align, 'center')
    button.confirmSound = nil
    button.selectSound = nil
    button.cancelSound = nil
    button.clickSound = nil
  end
end

-- ------------------------------------------------------------------------------------------------
-- Input Callbacks
-- ------------------------------------------------------------------------------------------------

--- Overrides `Window:update`. Opens or closes automatically depending if the player is using the mouse or not.
-- @override update
function ButtonWindow:update(dt)
  if self.GUI.open and self.active then
    self:refreshLastOpen()
    if not self.lastOpen then
      if self.open then
        GUIManager.fiberList:fork(self.hide, self)
      end
    else
      if self.closed then
        GUIManager.fiberList:fork(self.show, self)
      end
    end
  end
  for _, button in ipairs(self.matrix) do
    button:refreshEnabled()
  end
  GridWindow.update(self, dt)
end
--- Implements `GridWindow:buttonEnabled`. Disables when window is inactive.
-- @implement buttonEnabled
function ButtonWindow:buttonEnabled(button)
  return self.active
end
--- Overrides `Window:checkInput`. Ignores keyboard input.
-- @override checkInput
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
--- Checks input and returns whether the player clicked the button or not.
-- @treturn boolean
function ButtonWindow:checkClick()
  self:checkInput()
  if self.result then
    self.result = nil
    return true
  end
  return false
end
--- Refreshes the lastOpen property by checking if the mouse cursor is the current main input.
function ButtonWindow:refreshLastOpen()
  self.lastOpen = not InputManager.usingKeyboard and InputManager.mouse.active
    or not InputManager:hasKeyboard()
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:colCount`. 
-- @override colCount
function ButtonWindow:colCount()
  return 1
end
--- Overrides `GridWindow:rowCount`. 
-- @override rowCount
function ButtonWindow:rowCount()
  return #self.buttonNames
end
--- Overrides `GridWindow:cellWidth`. 
-- @override cellWidth
function ButtonWindow:cellWidth()
  if self.width then
    return self.width - self:paddingX() * 2
  else
    return GridWindow.cellWidth(self) / 1.5
  end
end
--- Overrides `GridWindow:cellHeight`. 
-- @override cellHeight
function ButtonWindow:cellHeight()
  if self.height then
    return self.height - self:paddingY() * 2
  else
    return GridWindow.cellHeight(self) * 1.5
  end
end
--- Overrides `Window:paddingX`. 
-- @override paddingX
function ButtonWindow:paddingX()
  return GridWindow.paddingX(self) / 4
end
--- Overrides `Window:paddingY`. 
-- @override paddingY
function ButtonWindow:paddingY()
  return GridWindow.paddingY(self) / 4
end
-- @treturn string String representation (for debugging).
function ButtonWindow:__tostring()
  return self.buttonNames[1] .. ' Button Window'
end

return ButtonWindow
