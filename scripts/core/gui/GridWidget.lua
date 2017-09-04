
--[[===============================================================================================

GridWidget
---------------------------------------------------------------------------------------------------
Generic widget for windows (like button or spinner).

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local List = require('core/datastruct/List')

-- Alias
local ceil = math.ceil

local GridWidget = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(window : GridWindow) the window this widget belongs to
-- @param(index : number) the child index of this widget
function GridWidget:init(window)
  local index = #window.buttonMatrix + 1
  self.window = window
  self:setIndex(index)
  window.content:add(self)
  window.buttonMatrix[index] = self
  self.content = List()
  self.enabled = true
  self.selected = false
end
-- Changes the index.
function GridWidget:setIndex(i)
  self.index = i
  self.row = ceil(i / self.window:colCount())
  self.col = i - (self.row - 1) * self.window:colCount()
end
-- @ret(Vector) the offset from the window's position.
function GridWidget:relativePosition()
  local w = self.window
  local x = w:gridX() - (w.width / 2 - w:hPadding()) + 
    (self.col - w.offsetCol - 1) * w:buttonWidth()
  local y = w:gridY() - (w.height / 2 - w:vpadding()) + 
    (self.row - w.offsetRow - 1) * w:buttonHeight()
  return Vector(x, y, -1)
end

---------------------------------------------------------------------------------------------------
-- Input handlers
---------------------------------------------------------------------------------------------------

-- Called when player presses "Confirm" on this widget.
function GridWidget.onConfirm(window, button)
end
-- Called when player presses "Cancel" on this widget.
function GridWidget.onCancel(window, button)
end
-- Called when player presses arrows on this widget.
function GridWidget.onMove(window, button, dx, dy)
end
-- Called when this widget is selected (highlighted).
function GridWidget.onSelect(window, button)
end

---------------------------------------------------------------------------------------------------
-- Content
---------------------------------------------------------------------------------------------------

-- Enables/disables this button.
-- @param(value : boolean) true to enable, false to disable
function GridWidget:setEnabled(value)
end
-- Selects/deselects this button.
-- @param(value : boolean) true to select, false to deselect
function GridWidget:setSelected(value)
end
-- Updates each content widget's position.
function GridWidget:updatePosition(windowPos)
  local pos = self:relativePosition()
  pos:add(windowPos)
  for i = 1, #self.content do
    if self.content[i].updatePosition then
      self.content[i]:updatePosition(pos)
    end
  end
end
-- Updates each content widget (called once per frame).
function GridWidget:update()
  for i = 1, #self.content do
    if self.content[i].udpate then
      self.content[i]:update()
    end
  end
end
-- Destroys each content widget.
function GridWidget:destroy()
  for i = 1, #self.content do
    if self.content[i].destroy then
      self.content[i]:destroy()
    end
  end
end
-- Shows each content widget.
function GridWidget:show()
  for i = 1, #self.content do
    if self.content[i].show then
      self.content[i]:show()
    end
  end
end
-- Hides each content widget.
function GridWidget:hide()
  for i = 1, #self.content do
    if self.content[i].hide then
      self.content[i]:hide()
    end
  end
end

return GridWidget
  