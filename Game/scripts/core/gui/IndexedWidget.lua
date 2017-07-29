
--[[===============================================================================================

IndexedWidget
---------------------------------------------------------------------------------------------------
Generic widget for windows (like button or spinner).

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local List = require('core/datastruct/List')

-- Alias
local ceil = math.ceil

local IndexedWidget = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(window : ButtonWindow) the window this widget belongs to
-- @param(index : number) the child index of this widget
function IndexedWidget:init(window)
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
function IndexedWidget:setIndex(i)
  self.index = i
  self.row = ceil(i / self.window:colCount())
  self.col = i - (self.row - 1) * self.window:colCount()
end
-- @ret(Vector) the offset from the window's position.
function IndexedWidget:relativePosition()
  local w = self.window
  local x = -(w.width / 2 - w:hpadding()) + 
    (self.col - w.offsetCol - 1) * w:buttonWidth()
  local y = -(w.height / 2 - w:vpadding()) + 
    (self.row - w.offsetRow - 1) * w:buttonHeight()
  return Vector(x, y, -1)
end

---------------------------------------------------------------------------------------------------
-- Input handlers
---------------------------------------------------------------------------------------------------

-- Called when player presses "Confirm" on this widget.
function IndexedWidget.onConfirm(window, button)
end
-- Called when player presses "Cancel" on this widget.
function IndexedWidget.onCancel(window, button)
end
-- Called when player presses arrows on this widget.
function IndexedWidget.onMove(window, button, dx, dy)
end
-- Called when this widget is selected (highlighted).
function IndexedWidget.onSelect(window, button)
end

---------------------------------------------------------------------------------------------------
-- Content
---------------------------------------------------------------------------------------------------

-- Enables/disables this button.
-- @param(value : boolean) true to enable, false to disable
function IndexedWidget:setEnabled(value)
end
-- Selects/deselects this button.
-- @param(value : boolean) true to select, false to deselect
function IndexedWidget:setSelected(value)
end
-- Updates each content widget's position.
function IndexedWidget:updatePosition(windowPos)
  local pos = self:relativePosition()
  pos:add(windowPos)
  for i = 1, #self.content do
    if self.content[i].updatePosition then
      self.content[i]:updatePosition(pos)
    end
  end
end
-- Updates each content widget (called once per frame).
function IndexedWidget:update()
  for i = 1, #self.content do
    if self.content[i].udpate then
      self.content[i]:update()
    end
  end
end
-- Destroys each content widget.
function IndexedWidget:destroy()
  for i = 1, #self.content do
    if self.content[i].destroy then
      self.content[i]:destroy()
    end
  end
end
-- Shows each content widget.
function IndexedWidget:show()
  for i = 1, #self.content do
    if self.content[i].show then
      self.content[i]:show()
    end
  end
end
-- Hides each content widget.
function IndexedWidget:hide()
  for i = 1, #self.content do
    if self.content[i].hide then
      self.content[i]:hide()
    end
  end
end

return IndexedWidget
  