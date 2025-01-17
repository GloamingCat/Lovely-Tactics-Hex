
-- ================================================================================================

--- Shows a list of custom choices.
---------------------------------------------------------------------------------------------------
-- @windowmod ButtonWindow
-- @extend GridWindow

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
-- @tparam Menu menu Parent Menu.
-- @tparam table names A list of the names (keys) of the buttons.
-- @tparam string align The horizontal alignment of the text in the buttons.
-- @param ... Other parameters from the GridWindow constructor.
function ButtonWindow:init(menu, names, align, ...)
  if type(names) == 'string' then
    self.buttonNames = {names}
  else
    self.buttonNames = names
  end
  GridWindow.init(self, menu, ...)
end
--- Overrides `GridWindow:setProperties`.
-- @override
function ButtonWindow:setProperties()
  GridWindow.setProperties(self)
  if #self.buttonNames == 1 then
    self.noHighlight = true
    self.noCursor = true
  end
  self.align = align or 'center'
  self.offBoundsCancel = false
  self.active = true
end
--- Implements `GridWindow:createWidgets`. Creates a button for each choice.
-- @implement
function ButtonWindow:createWidgets()
  for _, name in ipairs(self.buttonNames) do
    local button = Button:fromKey(self, name)
    button.text:setAlign(self.align, 'center')
    button.confirmSound = nil
    button.selectSound = nil
    button.cancelSound = nil
  end
end

-- ------------------------------------------------------------------------------------------------
-- Input Callbacks
-- ------------------------------------------------------------------------------------------------

--- Overrides `Window:update`.
-- Opens or closes automatically depending if the player is using the mouse or not.
-- @override
function ButtonWindow:update(dt)
  if self.menu.open and self.active then
    self:refreshLastOpen()
    if not self.lastOpen then
      if self.open then
        MenuManager.fiberList:forkMethod(self, 'hide')
      end
    else
      if self.closed then
        MenuManager.fiberList:forkMethod(self, 'show')
      end
    end
  end
  for _, button in ipairs(self.matrix) do
    button:refreshEnabled()
  end
  GridWindow.update(self, dt)
end
--- Implements `GridWindow:buttonEnabled`. Disables when window is inactive.
-- @implement
function ButtonWindow:buttonEnabled(button)
  return self.active
end
--- Overrides `Window:checkInput`. Ignores keyboard input.
-- @override
function ButtonWindow:checkInput()
  if not self.open then
    return
  end
  local x, y = InputManager.mouse:menuCoord()
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
-- @treturn boolean True if the player clicked on it in this frame.
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
-- @override
function ButtonWindow:colCount()
  return 1
end
--- Overrides `GridWindow:rowCount`. 
-- @override
function ButtonWindow:rowCount()
  return #self.buttonNames
end
--- Overrides `GridWindow:cellWidth`. 
-- @override
function ButtonWindow:cellWidth()
  if self.width then
    return self.width - self:paddingX() * 2
  else
    return GridWindow.cellWidth(self) / 1.5
  end
end
--- Overrides `GridWindow:cellHeight`. 
-- @override
function ButtonWindow:cellHeight()
  if self.height then
    return self.height - self:paddingY() * 2
  else
    return GridWindow.cellHeight(self) * 1.5
  end
end
--- Overrides `Window:paddingX`. 
-- @override
function ButtonWindow:paddingX()
  return GridWindow.paddingX(self) / 4
end
--- Overrides `Window:paddingY`. 
-- @override
function ButtonWindow:paddingY()
  return GridWindow.paddingY(self) / 4
end
-- For debugging.
function ButtonWindow:__tostring()
  return self.buttonNames[1] .. ' Button Window'
end

return ButtonWindow
