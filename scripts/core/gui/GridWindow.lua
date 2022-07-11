
--[[===============================================================================================

GridWindow
---------------------------------------------------------------------------------------------------
Provides the base for windows with widgets in a matrix.

=================================================================================================]]

-- Imports
local GridScroll = require('core/gui/widget/GridScroll')
local Highlight = require('core/gui/widget/Highlight')
local Matrix2 = require('core/math/Matrix2')
local Vector = require('core/math/Vector')
local Window = require('core/gui/Window')
local WindowCursor = require('core/gui/widget/WindowCursor')

local GridWindow = class(Window)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides Window:createContent.
function GridWindow:createContent(width, height)
  self.matrix = Matrix2(self:colCount(), 1)
  self:createWidgets()
  self.currentCol = 1
  self.currentRow = 1
  self.offsetCol = 0
  self.offsetRow = 0
  if not self.noCursor then
    self.cursor = WindowCursor(self)
  end
  if not self.noHighlight then
    self.highlight = Highlight(self)
  end
  self.loopVertical = true
  self.loopHorizontal = true
  Window.createContent(self, width or self:calculateWidth(), height or self:calculateHeight())
  self:packWidgets()
end
-- Refreshes widgets' color, position, and enabled condition.
function GridWindow:refreshWidgets()
  for i = 1, #self.matrix do
    self.matrix[i]:refreshEnabled()
    self.matrix[i]:refreshState()
  end
  if not self:currentWidget() then
    self.currentCol = 1
    self.currentRow = 1
  end
  local current = self:currentWidget()
  if current then
    self:setSelectedWidget(current)
  end
  self:packWidgets()
end
-- Reposition widgets so they are aligned and inside the window and adjusts sliders.
function GridWindow:packWidgets()
  self.matrix.height = math.ceil(#self.matrix / self:colCount())
  if self:actualRowCount() > self:rowCount() then
    self.scroll = self.scroll or GridScroll(self, Vector(self.width / 2 - self:paddingX(), 0), 
      self.height - self:paddingY() * 2)
  elseif self.scroll then
    self.scroll:destroy()
    self.scroll = nil
  end
  self:updateViewport(self.currentCol, self.currentRow)
  if self.cursor then
    self.cursor:updatePosition(self.position)
  end
  if self.highlight then
    self.highlight:updatePosition(self.position)
  end
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Overrides Window:setActive.
-- Hides cursor and unselected widget if deactivated.
function GridWindow:setActive(value)
  if self.active ~= value then
    self.active = value
    local widget = self:currentWidget()
    if value then
      if widget then
        widget:setSelected(true)
        if widget.onSelect then
          widget.onSelect(self, widget)
        end
        if self.cursor and self.open then
          self.cursor:show()
        end
        if self.highlight and self.open then
          self.highlight:show()
        end
      end
    else
      if self.cursor then
        self.cursor:hide()
      end
      if not (widget and widget.selected) then
        if self.highlight then
          self.highlight:hide()
        end
      end
    end
  end
end
-- Overrides Window:showContent.
-- Checks if there is a selected widget to show/hide the cursor.
function GridWindow:showContent()
  Window.showContent(self)
  local widget = self:currentWidget()
  if widget and widget.selected then
    if widget.onSelect then
      widget.onSelect(self, widget)
    end
  else
    if self.cursor then
      self.cursor:hide()
    end
    if self.highlight then
      self.highlight:hide()
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Widgets
---------------------------------------------------------------------------------------------------

-- Gets the cell shown in the given position.
-- @ret(Widget)
function GridWindow:getCell(x, y)
  if x < 1 or x > self:colCount() or y < 1 or y > self:rowCount() then
    return nil
  end
  return self.matrix:get(self.offsetCol + x, self.offsetRow + y)
end
-- Adds the grid widgets of the window.
function GridWindow:createWidgets()
  -- Abstract.
end
-- Getscurrent selected widget.
-- @ret(GridWidget) the selected widget
function GridWindow:currentWidget()
  if self.currentCol < 1 or self.currentCol > self.matrix.width or
      self.currentRow < 1 or self.currentRow > self.matrix.height then
    return nil
  end
  return self.matrix:get(self.currentCol, self.currentRow)
end
-- Gets the number of buttons.
-- @ret(number)
function GridWindow:widgetCount()
  return #self.matrix
end
-- Insert widget at the given index.
-- @param(widget : GridWidget) the widget to insert
-- @param(i : number) the index of the widget (optional, last position by default)
function GridWindow:insertWidget(widget, i)
  i = i or #self.matrix + 1
  local last = #self.matrix
  assert(i >= 1 and i <= last + 1, 'invalid widget index: ' .. pos)
  for w = last + 1, i + 1, -1 do
    self.matrix[w] = self.matrix[w - 1]
    self.matrix[w]:setIndex(w)
    self.matrix[w]:updatePosition(self.position)
  end
  self.matrix[i] = widget
  widget:setIndex(i)
  widget:updatePosition(self.position)
end
-- Removes widget at the given index.
-- @param(i : number) the index of the widget
-- @ret(GridWidget) the removed widget
function GridWindow:removeWidget(i)
  local last = #self.matrix
  assert(i >= 1 and i <= last, 'invalid widget index: ' .. i)
  local widget = self.matrix[i]
  widget:destroy()
  for w = i, last - 1 do
    self.matrix[w] = self.matrix[w+1]
    self.matrix[w]:setIndex(w)
    self.matrix[w]:updatePosition(self.position)
  end
  self.matrix[last] = nil
  return widget
end
-- Removes all widgets.
function GridWindow:clearWidgets()
  local last = #self.matrix
  for w = 1, last do
    self.matrix[w]:destroy()
    self.matrix[w] = nil
  end
end
-- Selects the next widget in the grid from the given direction.
-- @param(dx : number) Horizontal direction (from -1 to 1).
-- @param(dy : number) Horizontal direction (from -1 ot 1).
-- @param(playSound : boolean) True of play the select sound.
function GridWindow:nextWidget(dx, dy, playSound)
  local c, r = self:movedCoordinates(self.currentCol, self.currentRow, dx, dy)
  local oldWidget = self:currentWidget()
  self.currentCol = c
  self.currentRow = r
  local newWidget = self:currentWidget()
  if oldWidget ~= newWidget then 
    if playSound and newWidget.selectSound then
      AudioManager:playSFX(newWidget.selectSound)
    end
    oldWidget:setSelected(false)
  end
  self:setSelectedWidget(newWidget)
end
-- Sets the current selected widget.
-- @param(widget : GridWidget) Nil to unselected all widgets.
function GridWindow:setSelectedWidget(widget)
  if widget then
    widget:setSelected(true)
    if widget.onSelect then
      widget.onSelect(self, widget)
    end
    self:updateViewport()
    if self.cursor then
      self.cursor:updatePosition(self.position)
      if self.open then
        self.cursor:show()
      end
    end
    if self.highlight then
      self.highlight:updatePosition(self.position)
      if self.open then
        self.highlight:show()
      end
    end
  else
    widget = self:currentWidget()
    if widget then
      widget:setSelected(false)
    end
    if self.cursor then
      self.cursor:hide()
    end
    if self.highlight then
      self.highlight:hide()
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Input - Keybord
---------------------------------------------------------------------------------------------------

-- Called when player confirms.
function GridWindow:onConfirm(widget)
  widget = widget or self:currentWidget()
  if widget.enabled then
    if widget.confirmSound then
      AudioManager:playSFX(widget.confirmSound)
    end
    if widget.onConfirm then
      widget.onConfirm(self, widget)
    end
  else
    if widget.errorSound then
      AudioManager:playSFX(widget.errorSound)
    end
  end
end
-- Called when player cancels.
function GridWindow:onCancel(widget)
  widget = widget or self:currentWidget()
  if widget.cancelSound then
    AudioManager:playSFX(widget.cancelSound)
  end
  if widget.onCancel then
    widget.onCancel(self, widget)
  end
end
-- Called when a text input is received.
function GridWindow:onTextInput(c, widget)
  widget = widget or self:currentWidget()
  if widget.onTextInput then
    widget.onTextInput(self, widget)
  end
end
-- Called when player moves cursor.
function GridWindow:onMove(dx, dy, widget)
  widget = widget or self:currentWidget()
  if widget and widget.onMove then
    widget.onMove(self, widget, dx, dy)
  end
  self:nextWidget(dx, dy, true)
end

---------------------------------------------------------------------------------------------------
-- Input - Mouse
---------------------------------------------------------------------------------------------------

-- Called when player presses a mouse button.
-- Overrides Window:onClick.
function GridWindow:onClick(button, x, y)
  if button == 1 then
    if self:isInside(x, y) then
      local widget = self:currentWidget()
      if widget.enabled then
        if widget.clickSound then
          AudioManager:playSFX(widget.clickSound)
        end
        if widget.onClick then
          widget.onClick(self, widget, x, y)
        end
      else
        if widget.errorSound then
          AudioManager:playSFX(widget.errorSound)
        end
      end
    end
  else
    self:onCancel()
  end
end
-- Called when player moves the mouse.
-- @param(x : number) Mouse delta x.
-- @param(y : number) Mouse delta y.
function GridWindow:onMouseMove(x, y)
  if self:isInside(x, y) then
    if self.scroll then
      self.scroll:onMouseMove(x, y)
    end
    x = x + self.width / 2 - self:paddingX() - self:gridX() + self:colMargin() / 2
    y = y + self.height / 2 - self:paddingY() - self:gridY() + self:rowMargin() / 2
    x = math.floor( x / (self:cellWidth() + self:colMargin() ) ) + 1
    y = math.floor( y / (self:cellHeight() + self:rowMargin() ) ) + 1
    local widget = self:getCell(x, y)
    if widget then
      self.currentCol = x + self.offsetCol
      self.currentRow = y + self.offsetRow
      self:setSelectedWidget(widget)
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Button Input
---------------------------------------------------------------------------------------------------

-- Called when player presses "Confirm" on this button.
function GridWindow:onButtonConfirm(button)
  self.result = button.index
end
-- Called when player presses "Cancel" on this button.
function GridWindow:onButtonCancel(button)
  self.result = 0
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
function GridWindow:movedCoordinates(c, r, dx, dy)
  local widget = self.matrix:get(c + dx, r + dy)
  if widget then
    return c + dx, r + dy
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
      if dy > 0 then
        r = self:upLoop(c)
      else
        r = self:downLoop(c)
      end
    end
  end
  return c, r
end
-- Loops row r to the right.
function GridWindow:rightLoop(r)
  local c = 1
  while not self.matrix:get(c,r) do
    c = c + 1
  end
  return c
end
-- Loops row r to the left.
function GridWindow:leftLoop(r)
  local c = self.matrix.width
  while not self.matrix:get(c,r) do
    c = c - 1
  end
  return c
end
-- Loops column c up.
function GridWindow:upLoop(c)
  local r = 1
  while not self.matrix:get(c,r) do
    r = r + 1
  end
  return r
end
-- Loops column c down.
function GridWindow:downLoop(c)
  local r = self.matrix.height
  while not self.matrix:get(c,r) do
    r = r - 1
  end
  return r
end

---------------------------------------------------------------------------------------------------
-- Viewport
---------------------------------------------------------------------------------------------------

-- Adapts the visible buttons.
-- @param(c : number) the current widget's column
-- @param(r : number) the current widget's row
function GridWindow:updateViewport(c, r)
  local newOffsetCol, newOffsetRow = self:newViewport(c, r)
  if newOffsetCol ~= self.offsetCol or newOffsetRow ~= self.offsetRow then
    self.offsetCol = newOffsetCol
    self.offsetRow = newOffsetRow
    for widget in self.matrix:iterator() do
      widget:hide()
      widget:updatePosition(self.position)
      widget:show()
    end
    if self.scroll then
      self.scroll:updatePosition(self.position)
    end
  end
end
-- Determines the new (c, r) coordinates of the widget matrix viewport.
-- @param(newc : number) the selected widget's column
-- @param(newr : number) the selected widget's row
function GridWindow:newViewport(newc, newr)
  newc, newr = newc or self.currentCol, newr or self.currentRow
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

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- @ret(number) the number of visible columns.
function GridWindow:colCount()
  return 3
end
-- @ret(number) The number of visible rows.
function GridWindow:rowCount()
  return 4
end
-- @ret(number) Number of rows that where actually occupied by buttons.
function GridWindow:actualRowCount()
  return self.matrix.height
end
-- @ret(number) Grid x-axis displacement in pixels
function GridWindow:gridX()
  return 0
end
-- @ret(number) Grid y-axis displacement in pixels.
function GridWindow:gridY()
  return 0
end
-- @ret(number) The window's width in pixels.
function GridWindow:calculateWidth()
  local cols = self:colCount()
  local buttons = cols * self:cellWidth() + (cols - 1) * self:colMargin()
  return self:paddingX() * 2 + buttons + self:gridX()
end
-- @ret(number) The window's height in pixels.
function GridWindow:calculateHeight()
  local rows = self:rowCount()
  local cells = rows * self:cellHeight() + (rows - 1) * self:rowMargin()
  return self:paddingY() * 2 + cells + self:gridY()
end
-- @ret(number) The width of a cell in pixels.
function GridWindow:cellWidth()
  return 70
end
-- @ret(number) The height of a cell in pixels.
function GridWindow:cellHeight()
  return 12
end
-- @ret(number) The space between columns in pixels.
function GridWindow:colMargin()
  return 6
end
-- @ret(number) The space between rows in pixels.
function GridWindow:rowMargin()
  return 2
end

return GridWindow
