
-- ================================================================================================

--- Provides the base for windows with widgets in a matrix.
---------------------------------------------------------------------------------------------------
-- @classmod GridWindow

-- ================================================================================================

-- Imports
local GridScroll = require('core/gui/widget/GridScroll')
local Highlight = require('core/gui/widget/Highlight')
local Matrix2 = require('core/math/Matrix2')
local Vector = require('core/math/Vector')
local Window = require('core/gui/Window')
local WindowCursor = require('core/gui/widget/WindowCursor')

-- Class table.
local GridWindow = class(Window)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `Window:setProperties`. 
-- @override
function GridWindow:setProperties()
  Window.setProperties(self)
  self.loopVertical = true
  self.loopHorizontal = true
  self.tooltipTerm = nil
end
--- Overrides `Window:createContent`. 
-- @override
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
  Window.createContent(self, width or self:computeWidth(), height or self:computeHeight())
  self:packWidgets()
end
--- Refreshes widgets' color, position, and enabled condition.
function GridWindow:refreshWidgets()
  for i = 1, #self.matrix do
    self.matrix[i]:refresh()
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
--- Reposition widgets so they are aligned and inside the window and adjusts sliders.
function GridWindow:packWidgets()
  self.matrix.height = math.ceil(#self.matrix / self:colCount())
  if self:actualRowCount() > self:rowCount() then
    self.scroll = self.scroll or GridScroll(self)
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

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Overrides `Window:setActive`. Hides cursor and unselected widget if deactivated.
-- @override
function GridWindow:setActive(value)
  if self.active ~= value then
    Window.setActive(self, value)
    local widget = self:currentWidget()
    if value then
      if widget then
        widget:setSelected(true)
        if widget.onSelect then
          widget.onSelect(self, widget)
        end
        self:setWidgetTooltip(widget)
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
--- Overrides `Window:showContent`. Checks if there is a selected widget to show/hide the cursor.
-- @override
function GridWindow:showContent()
  Window.showContent(self)
  local widget = self:currentWidget()
  if widget and widget.selected then
    if widget.onSelect then
      widget.onSelect(self, widget)
    end
    self:setWidgetTooltip(widget)
  else
    if self.cursor then
      self.cursor:hide()
    end
    if self.highlight then
      self.highlight:hide()
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Widgets
-- ------------------------------------------------------------------------------------------------

--- Gets the cell shown in the given position.
-- @treturn Widget
function GridWindow:getCell(x, y)
  if x < 1 or x > self:colCount() or y < 1 or y > self:rowCount() then
    return nil
  end
  return self.matrix:get(self.offsetCol + x, self.offsetRow + y)
end
--- Adds the grid widgets of the window.
function GridWindow:createWidgets()
  -- Abstract.
end
--- Gets current selected widget.
-- @treturn GridWidget The selected widget.
function GridWindow:currentWidget()
  if self.currentCol < 1 or self.currentCol > self.matrix.width or
      self.currentRow < 1 or self.currentRow > self.matrix.height then
    return nil
  end
  return self.matrix:get(self.currentCol, self.currentRow)
end
--- Gets widget that was clicked on.
-- @treturn GridWidget The clicked widget, or nil if the coordinates are invalid.
function GridWindow:clickedWidget(x, y, triggerPoint)
  if triggerPoint ~= nil then
    -- Touch
    local widget1 = self:getCell(self:getCellCoordinates(triggerPoint.x, triggerPoint.y))
    local widget2 = self:getCell(self:getCellCoordinates(x, y))
    if widget1 ~= widget2 then
      return nil
    end
  end
  if not self:onMouseMove(x, y) then
    return nil
  end
  return self:currentWidget()
end
--- Gets the number of buttons.
-- @treturn number
function GridWindow:widgetCount()
  return #self.matrix
end
--- Insert widget at the given index.
-- @tparam GridWidget widget The widget to insert.
-- @tparam number i The index of the widget (optional, last position by default).
function GridWindow:insertWidget(widget, i)
  i = i or #self.matrix + 1
  local last = #self.matrix
  assert(i >= 1 and i <= last + 1, 'invalid widget index: ' .. i)
  for w = last + 1, i + 1, -1 do
    self.matrix[w] = self.matrix[w - 1]
    self.matrix[w]:setIndex(w)
    self.matrix[w]:updatePosition(self.position)
  end
  self.matrix[i] = widget
  widget:setIndex(i)
  widget:updatePosition(self.position)
end
--- Removes widget at the given index.
-- @tparam number i The index of the widget.
-- @treturn GridWidget The removed widget.
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
--- Removes all widgets.
function GridWindow:clearWidgets()
  local last = #self.matrix
  for w = 1, last do
    self.matrix[w]:destroy()
    self.matrix[w] = nil
  end
end
--- Selects the next widget in the grid from the given direction.
-- @tparam number dx Horizontal direction (from -1 to 1).
-- @tparam number dy Horizontal direction (from -1 ot 1).
-- @tparam boolean playSound True of play the select sound.
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
    if oldWidget then
      oldWidget:setSelected(false)
    end
  end
  self:setSelectedWidget(newWidget)
end
--- Sets the current selected widget.
-- @tparam GridWidget widget Nil to unselected all widgets.
function GridWindow:setSelectedWidget(widget)
  if widget then
    widget:setSelected(true)
    if widget.onSelect then
      widget.onSelect(self, widget)
    end
    self:setWidgetTooltip(widget)
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
--- Gets the tooltip term according to gven widget.
-- @tparam GridWidget|string widget The new term or the widget with the new term.
function GridWindow:setWidgetTooltip(widget)
  if not self.tooltip then
    return
  end
  if type(widget) == 'string' then
    self.tooltip:setTerm('manual.' .. widget, self.tooltipTerm)
  elseif widget and widget.tooltipTerm then
    self.tooltip:setTerm('manual.' .. widget.tooltipTerm, widget.tooltipTerm)
  else
    self.tooltip:setTerm('manual.' .. self.tooltipTerm, self.tooltipTerm)
  end
  self.tooltip:redraw()
end
--- Moves to the next #cols widgets at once, keeping the cursor in place when possible.
-- @tparam number dx Page change direction (1 or -1).
function GridWindow:nextPage(dx)
  local oldWidget = self:currentWidget()
  self.offsetRow = math.max(0, self.offsetRow + dx * self:rowCount())
  self.currentRow = self.currentRow + dx * self:rowCount()
  self:refreshGrid()
  local newWidget = self:currentWidget()
  while not newWidget do
    self.currentRow = self.currentRow - dx
    newWidget = self:currentWidget()
  end
  if oldWidget ~= newWidget then
    if newWidget.selectSound then
      AudioManager:playSFX(newWidget.selectSound)
    end
    if oldWidget then
      oldWidget:setSelected(false)
    end
  end
  self:setSelectedWidget(newWidget)
end

-- ------------------------------------------------------------------------------------------------
-- Input - Keybord
-- ------------------------------------------------------------------------------------------------

--- Called when player confirms.
-- @tparam GridWidget widget The current selected widget.
function GridWindow:onConfirm(widget)
  widget = widget or self:currentWidget()
  if widget then
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
      if widget.onError then
        widget.onError(self, widget)
      end
    end
  else
    Window.onConfirm(self)
  end
end
--- Called when player cancels.
-- @tparam GridWidget widget The current selected widget.
function GridWindow:onCancel(widget)
  widget = widget or self:currentWidget()
  if widget then
    if widget.cancelSound then
      AudioManager:playSFX(widget.cancelSound)
    end
    if widget.onCancel then
      widget.onCancel(self, widget)
    end
  else
    Window.onCancel(self)
  end
end
--- Called when a text input is received.
-- @tparam string c The input character.
-- @tparam GridWidget widget The current selected widget.
function GridWindow:onTextInput(c, widget)
  widget = widget or self:currentWidget()
  if widget.onTextInput then
    widget.onTextInput(self, widget)
  end
end
--- Called when player moves cursor.
-- @tparam number dx The input in the horizontal axis (-1 to 1).
-- @tparam number dy The input in the vertical axis (-1 to 1).
-- @tparam GridWidget widget The current selected widget.
function GridWindow:onMove(dx, dy, widget)
  widget = widget or self:currentWidget()
  if widget and widget.onMove then
    widget.onMove(self, widget, dx, dy)
  end
  self:nextWidget(dx, dy, true)
end

-- ------------------------------------------------------------------------------------------------
-- Input - Mouse
-- ------------------------------------------------------------------------------------------------

--- Overrides `Window:onClick`. First verifies if user clicked on scroll.
-- @override
function GridWindow:onClick(button, x, y, triggerPoint)
  if button == 1 and self.scroll and self.scroll:onClick(x, y) then
    return
  else
    Window.onClick(self, button, x, y, triggerPoint)
  end
end
--- Overrides `Window:onMouseConfirm`.
-- @override
function GridWindow:onMouseConfirm(x, y, triggerPoint)
  local widget = self:clickedWidget(x, y, triggerPoint)
  if not widget then
    return
  end
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
    if widget.onError then
      widget.onError(self, widget)
    end
  end
end
--- Called when player moves the mouse.
-- @tparam number x Mouse x.
-- @tparam number y Mouse y.
-- @treturn boolean True if the pointer is over a selectablt widget, false otherwise.
function GridWindow:onMouseMove(x, y)
  if self:isInside(x, y) then
    if self.scroll then
      self.scroll:onMouseMove(x, y)
    end
    x, y = self:getCellCoordinates(x, y)
    local widget = self:getCell(x, y)
    if widget then
      self.currentCol = x + self.offsetCol
      self.currentRow = y + self.offsetRow
      self:setSelectedWidget(widget)
      return true
    end
  end
  return false
end

-- ------------------------------------------------------------------------------------------------
-- Button Input
-- ------------------------------------------------------------------------------------------------

--- Called when player presses "Confirm" on this button.
-- @tparam Button button The selected button.
function GridWindow:onButtonConfirm(button)
  self.result = button.index
end
--- Called when player presses "Cancel" on this button.
-- @tparam Button button The selected button.
function GridWindow:onButtonCancel(button)
  self.result = 0
end

-- ------------------------------------------------------------------------------------------------
-- Coordinate change
-- ------------------------------------------------------------------------------------------------

--- Computes the column and row based on mouse coordinates.
-- @tparam number x Pixel x relative to window's center.
-- @tparam number y Pixel y relative to window's center.
-- @treturn number Hovered column.
-- @treturn number Hovered row.
function GridWindow:getCellCoordinates(x, y)
  x = x + self.width / 2 - self:paddingX() - self:gridX() + self:colMargin() / 2
  x = x / (self:cellWidth() + self:colMargin())
  y = y + self.height / 2  - self:paddingY() - self:gridY() + self:rowMargin() / 2
  y = y / (self:cellHeight() + self:rowMargin()) 
  x = math.floor(x) + 1
  y = math.floor(y) + 1
  return x, y
end
--- Gets the coordinates adjusted depending on loop types.
-- @tparam number c The column number.
-- @tparam number r The row number.
-- @tparam number dx The direction in x.
-- @tparam number dy The direction in y.
-- @treturn number New column number.
-- @treturn number New row number.
function GridWindow:movedCoordinates(c, r, dx, dy)
  local widget = self.matrix:get(c + dx, r + dy)
  if widget then
    return c + dx, r + dy
  end
  if dx ~= 0 then
    if self.loopHorizontal then
      if dx > 0 then
        c = self:rightCell(r)
      else
        c = self:leftCell(r)
      end
    end
  else
    if self.loopVertical then
      if dy > 0 then
        r = self:upperCell(c)
      else
        r = self:bottomCell(c)
      end
    end
  end
  return c, r
end
--- Loops row r to the right.
-- @tparam number r Row number of the current selected cell.
-- @treturn number New row number.
function GridWindow:rightCell(r)
  local c = 1
  while not self.matrix:get(c,r) do
    c = c + 1
  end
  return c
end
--- Loops row r to the left.
-- @tparam number r Row number of the current selected cell.
-- @treturn number New row number.
function GridWindow:leftCell(r)
  local c = self.matrix.width
  while not self.matrix:get(c,r) do
    c = c - 1
  end
  return c
end
--- Loops column c up.
-- @tparam number c Column number of the current selected cell.
-- @treturn number New column number.
function GridWindow:upperCell(c)
  local r = 1
  while not self.matrix:get(c,r) do
    r = r + 1
  end
  return r
end
--- Loops column c down.
-- @tparam number c Column number of the current selected cell.
-- @treturn number New column number.
function GridWindow:bottomCell(c)
  local r = self.matrix.height
  while not self.matrix:get(c,r) do
    r = r - 1
  end
  return r
end

-- ------------------------------------------------------------------------------------------------
-- Viewport
-- ------------------------------------------------------------------------------------------------

--- Adapts the visible buttons.
-- @tparam number c The current widget's column.
-- @tparam number r The current widget's row.
function GridWindow:updateViewport(c, r)
  local newOffsetCol, newOffsetRow = self:newViewport(c, r)
  if newOffsetCol ~= self.offsetCol or newOffsetRow ~= self.offsetRow then
    self.offsetCol = newOffsetCol
    self.offsetRow = newOffsetRow
    self:refreshGrid()
  end
end
--- Refreshes which widget is visible according to current offset.
function GridWindow:refreshGrid()
  for widget in self.matrix:iterator() do
    widget:hide()
    widget:updatePosition(self.position)
    widget:show()
  end
  if self.scroll then
    self.scroll:updatePosition(self.position)
  end
end
--- Determines the new minimum offset (c, r) coordinates of the widget matrix viewport.
-- The offset if the difference between the current widget's coordinates and the selected visible cell's coordinates.
-- @tparam number newc The selected widget's column.
-- @tparam number newr The selected widget's row.
-- @treturn number Offset column.
-- @treturn number Offset row.
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

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- The number of visible columns.
-- @treturn number
function GridWindow:colCount()
  return 3
end
--- The number of visible rows.
-- @treturn number
function GridWindow:rowCount()
  return 4
end
--- Number of rows that where actually occupied by buttons.
-- @treturn number
function GridWindow:actualRowCount()
  return self.matrix.height
end
--- Grid x-axis displacement in pixels.
-- @treturn number
function GridWindow:gridX()
  return 0
end
--- Grid y-axis displacement in pixels.
-- @treturn number
function GridWindow:gridY()
  return 0
end
---The window's width in pixels.
-- @treturn number
function GridWindow:computeWidth()
  local cols = self:colCount()
  local buttons = cols * self:cellWidth() + (cols - 1) * self:colMargin()
  return self:paddingX() * 2 + buttons + self:gridX()
end
--- The window's height in pixels.
-- @treturn number
function GridWindow:computeHeight()
  local rows = self:rowCount()
  local cells = rows * self:cellHeight() + (rows - 1) * self:rowMargin()
  return self:paddingY() * 2 + cells + self:gridY()
end
--- The adjusted cell width for the given total window width.
-- @treturn number
function GridWindow:computeCellWidth(w)
  return (w - self:paddingX() * 2 - self:colMargin() * (self:colCount() - 1)) / self:colCount()
end
--- The adjusted cell height for the given total window height.
-- @treturn number
function GridWindow:computeCellHeight(h)
  return (h - self:paddingY() * 2 - self:rowMargin() * (self:rowCount() - 1)) / self:rowCount()
end
--- The width of a cell in pixels.
-- @treturn number
function GridWindow:cellWidth()
  return 100
end
--- The height of a cell in pixels.
-- @treturn number
function GridWindow:cellHeight()
  return GameManager:isMobile() and 22 or 18
end
--- The space between columns in pixels.
-- @treturn number
function GridWindow:colMargin()
  return 6
end
--- The space between rows in pixels.
-- @treturn number
function GridWindow:rowMargin()
  return 2
end

return GridWindow
