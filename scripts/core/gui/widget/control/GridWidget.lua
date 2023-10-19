
-- ================================================================================================

--- Generic widget for windows (like button or spinner).
---------------------------------------------------------------------------------------------------
-- @classmod GridWidget

-- ================================================================================================

-- Imports
local Component = require('core/gui/Component')
local List = require('core/datastruct/List')
local Vector = require('core/math/Vector')

-- Alias
local ceil = math.ceil

-- Class table.
local GridWidget = class(Component)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam GridWindow window The window this widget belongs to.
function GridWidget:init(window)
  Component.init(self)
  local index = #window.matrix + 1
  self.window = window
  self:setIndex(index)
  window.content:add(self)
  window.matrix[index] = self
  self.enabled = true
  self.selected = false
  self.confirmSound = Config.sounds.buttonConfirm
  self.cancelSound = Config.sounds.buttonCancel
  self.selectSound = Config.sounds.buttonSelect
  self.errorSound = Config.sounds.buttonError
  self.clickSound = self.confirmSound
end
--- Changes the index.
function GridWidget:setIndex(i)
  self.index = i
  self.row = ceil(i / self.window:colCount())
  self.col = i - (self.row - 1) * self.window:colCount()
end
-- @treturn Vector The offset of the widget's top left corner from the window's center.
function GridWidget:relativePosition()
  local w = self.window
  local col, row = self.col - w.offsetCol, self.row - w.offsetRow
  local x = w:gridX() - w.width / 2 + w:paddingX() + 
    (col - 1) * (w:cellWidth() + w:colMargin())
  local y = w:gridY() - w.height / 2 + w:paddingY() + 
    (row - 1) * (w:cellHeight() + w:rowMargin())
  return Vector(x, y, -1)
end

-- ------------------------------------------------------------------------------------------------
-- Content
-- ------------------------------------------------------------------------------------------------

--- Enables/disables this button.
-- @tparam boolean value True to enable, false to disable.
function GridWidget:setEnabled(value)
end
--- Selects/deselects this button.
-- @tparam boolean value True to select, false to deselect.
function GridWidget:setSelected(value)
end
--- Updates each content widget's position.
function GridWidget:updatePosition(windowPos)
  local pos = self:relativePosition()
  pos:add(windowPos)
  for i = 1, #self.content do
    if self.content[i].updatePosition then
      self.content[i]:updatePosition(pos)
    end
  end
end
--- Updates each content widget (called once per frame).
function GridWidget:update(dt)
  for i = 1, #self.content do
    if self.content[i].udpate then
      self.content[i]:update(dt)
    end
  end
end
--- Destroys each content widget.
function GridWidget:destroy()
  for i = 1, #self.content do
    if self.content[i].destroy then
      self.content[i]:destroy()
    end
  end
  self.window.content:removeElement(self)
end
--- Shows each content widget.
function GridWidget:show()
  for i = 1, #self.content do
    if self.content[i].show then
      self.content[i]:show()
    end
  end
end
--- Hides each content widget.
function GridWidget:hide()
  for i = 1, #self.content do
    if self.content[i].hide then
      self.content[i]:hide()
    end
  end
end

return GridWidget
  