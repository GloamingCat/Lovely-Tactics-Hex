
--[[===============================================================================================

ButtonWindow
---------------------------------------------------------------------------------------------------
Provides the base for windows with buttons.

=================================================================================================]]

-- Imports
local List = require('core/datastruct/List')
local Matrix2 = require('core/math/Matrix2')
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')
local Button = require('core/gui/Button')
local ButtonCursor = require('core/gui/ButtonCursor')
local VSlider = require('core/gui/VSlider')
local Window = require('core/gui/Window')

-- Alias
local ceil = math.ceil

local ButtonWindow = class(Window)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides Window:createContent.
function ButtonWindow:createContent()
  self.buttonMatrix = Matrix2(self:colCount(), 1)
  self:createButtons()
  self.buttonMatrix.height = ceil(#self.buttonMatrix / self:colCount())
  self.currentCol = 1
  self.currentRow = 1
  self.offsetCol = 0
  self.offsetRow = 0
  self.cursor = ButtonCursor(self)
  self.width = self:totalWidth()
  self.height = self:totalHeight()
  self.loopVertical = true
  self.loopHorizontal = true
  Window.createContent(self)
  local button = self:currentButton()
  if button then
    button:setSelected(true)
  end
  if self:actualRowCount() > self:rowCount() then
    self.vSlider = VSlider(self, Vector(self.width / 2 - self:hpadding(), 0), 
      self.height - self:vpadding() * 2)
  end
  self:updateViewport(1, 1)
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Sets this window as the active one.
function ButtonWindow:activate()
  self.GUI:setActiveWindow(self)
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Columns of the button matrix.
-- @ret(number) the number of visible columns
function ButtonWindow:colCount()
  return 3
end
-- Rows of the button matrix.
-- @ret(number) the number of visible lines
function ButtonWindow:rowCount()
  return 4
end
-- Gets the total width of the window.
-- @ret(number) the window's width in pixels
function ButtonWindow:totalWidth()
  return self:hpadding() * 2 + self:colCount() * self:buttonWidth()
end
-- Gets the total height of the window.
-- @ret(number) the window's height in pixels
function ButtonWindow:totalHeight()
  return self:vpadding() * 2 + self:rowCount() * self:buttonHeight()
end
-- Gets the number of rows that where actually occupied by buttons.
-- @ret(number) row count
function ButtonWindow:actualRowCount()
  return self.buttonMatrix.height
end

---------------------------------------------------------------------------------------------------
-- Buttons
---------------------------------------------------------------------------------------------------

-- Adds the buttons of the window.
function ButtonWindow:createButtons()
end
-- Gets the width of a single button.
-- @ret(number) the width in pixels
function ButtonWindow:buttonWidth()
  return 55
end
-- Gets the height of a single button.
-- @ret(number) the height in pixels
function ButtonWindow:buttonHeight()
  return 15
end
-- Gets current selected button.
-- @ret(Button) the selected button
function ButtonWindow:currentButton()
  return self.buttonMatrix:get(self.currentCol, self.currentRow)
end
-- Gets the number of buttons.
-- @ret(number)
function ButtonWindow:buttonCount()
  return #self.buttonMatrix
end

---------------------------------------------------------------------------------------------------
-- Input
---------------------------------------------------------------------------------------------------

-- Check if player pressed any GUI button.
function ButtonWindow:checkInput()
  if InputManager.keys['confirm']:isTriggered() then
    self:onConfirm()
  elseif InputManager.keys['cancel']:isTriggered() then
    self:onCancel()
  else
    local dx, dy = InputManager:ortAxis(0.5, 0.0625)
    if dx ~= 0 or dy ~= 0 then
      local c, r = self:movedCoordinates(self.currentCol, 
        self.currentRow, dx, dy)
      self:onMove(c, r, dx, dy)
    end
  end
end
-- Called when player confirms.
function ButtonWindow:onConfirm()
  local button = self:currentButton()
  if button.enabled then
    button.onConfirm(self, button)
  end
end
-- Called when player cancels.
function ButtonWindow:onCancel()
  local button = self:currentButton()
  if button.enabled then
    button.onCancel(self, button)
  end
  Window.onCancel(self)
end
-- Called when player moves cursor.
function ButtonWindow:onMove(c, r, dx, dy)
  local button = self:currentButton()
  button:setSelected(false)
  if button.enabled then
    button.onMove(self, button, dx, dy)
  end
  self.currentCol = c
  self.currentRow = r
  button = self:currentButton()
  button:setSelected(true)
  if button.enabled then
    button.onSelect(self, button)
  end
  self:updateViewport(c, r)
  self.cursor:updatePosition(self.position)
end

---------------------------------------------------------------------------------------------------
-- Coordinate change
---------------------------------------------------------------------------------------------------

-- Gets the coordinates adjusted depending on loop types.
-- @param(c : number) the column number
-- @param(r : number) the row number
-- @param(dx : number) the direction in x
-- @param(dy : number) the direction in y
-- @ret(number) new column number
-- @ret(number) new row number
-- @ret(boolean) true if visible buttons changed
function ButtonWindow:movedCoordinates(c, r, dx, dy)
  local button = self.buttonMatrix:get(c + dx, r - dy)
  if button then
    return c + dx, r - dy
  end
  if dx ~= 0 then
    if self.loopHorizontal then
      if dx > 0 then
        c = self:rightLoop(r)
      else
        c = self:leftLoop(r)
      end
    end
  else
    if self.loopVertical then
      if dy < 0 then
        r = self:upLoop(c)
      else
        r = self:downLoop(c)
      end
    end
  end
  return c, r
end
-- Loops row r to the right.
function ButtonWindow:rightLoop(r)
  local c = 1
  while not self.buttonMatrix:get(c,r) do
    c = c + 1
  end
  return c
end
-- Loops row r to the left.
function ButtonWindow:leftLoop(r)
  local c = self.buttonMatrix.width
  while not self.buttonMatrix:get(c,r) do
    c = c - 1
  end
  return c
end
-- Loops column c up.
function ButtonWindow:upLoop(c)
  local r = 1
  while not self.buttonMatrix:get(c,r) do
    r = r + 1
  end
  return r
end
-- Loops column c down.
function ButtonWindow:downLoop(c)
  local r = self.buttonMatrix.height
  while not self.buttonMatrix:get(c,r) do
    r = r - 1
  end
  return r
end

---------------------------------------------------------------------------------------------------
-- Viewport
---------------------------------------------------------------------------------------------------

-- Adapts the visible buttons.
-- @param(c : number) the current button's column
-- @param(r : number) the current button's row
function ButtonWindow:updateViewport(c, r)
  local newOffsetCol, newOffsetRow = self:newViewport(c, r)
  if newOffsetCol ~= self.offsetCol or newOffsetRow ~= self.offsetRow then
    self.offsetCol = newOffsetCol
    self.offsetRow = newOffsetRow
    for button in self.buttonMatrix:iterator() do
      button:hide()
      button:updatePosition(self.position)
      button:show()
    end
    if self.vSlider then
      self.vSlider:updatePosition(self.position)
    end
  end
end
-- Determines the new (c, r) coordinates of the button matrix viewport.
-- @param(newc : number) the selected button's column
-- @param(newr : number) the selected button's row
function ButtonWindow:newViewport(newc, newr)
  local c, r = self.offsetCol, self.offsetRow
  if newc < c + 1 then
    c = newc - 1
  elseif newc > c + self:colCount() then
    c = newc - self:colCount()
  end
  if newr < r + 1 then
    r = newr - 1
  elseif newr > r + self:rowCount() then
    r = newr - self:rowCount()
  end
  return c, r
end

return ButtonWindow
