
--[[===============================================================================================

@classmod ListWindow
---------------------------------------------------------------------------------------------------
A Button Window that has its buttons generated automatically given a list of arbitrary elements.

=================================================================================================]]

-- Imports
local GridWindow = require('core/gui/GridWindow')

-- Class table.
local ListWindow = class(GridWindow)

-- -------------------------------------------------------------------------------------------------
-- Initialization
-- -------------------------------------------------------------------------------------------------

--- Overrides GridWindow:init.
-- @tparam table list Array of data used to create each button.
function ListWindow:init(parent, list, ...)
  self.list = list
  GridWindow.init(self, parent, ...)
end
--- Overrides GridWindow:createWidgets.
function ListWindow:createWidgets()
  for i = 1, #self.list do
    self:createListButton(self.list[i])
  end
end
--- Creates a button from an element in the list.
function ListWindow:createListButton(element)
  -- Abstract.
end
--- Clears and recreates buttons.
function ListWindow:refreshButtons(list)
  self.list = list or self.list
  self:clearWidgets()
  self:createWidgets()
  GridWindow.refreshWidgets(self)
end

-- -------------------------------------------------------------------------------------------------
-- Auxiliary
-- -------------------------------------------------------------------------------------------------

--- Computes a maximum number of rows given the maximum height in pixels.
-- @tparam number maxHeight
function ListWindow:computeRowCount(maxHeight)
  maxHeight = maxHeight - self:paddingY() * 2 - self:rowMargin()
  return math.floor(maxHeight / (self:cellHeight() + self:rowMargin()))
end
--- Computes height and pixel y to fit the window on top of the screen given a height limit.
function ListWindow:fitOnTop(h)
  self.visibleRowCount = self:computeRowCount(h)
  local fith = self:computeHeight()
  local y = fith / 2 - ScreenManager.height / 2 + (h - fith) / 2
  return y, fith
end

-- -------------------------------------------------------------------------------------------------
-- Properties
-- -------------------------------------------------------------------------------------------------

--- Overrides GridWindow:colCount.
function ListWindow:colCount()
  return 2
end
--- Overrides GridWindow:colCount.
function ListWindow:rowCount()
  return self.visibleRowCount
end
--- Overrides GridWindow:cellWidth. Adapts the cell width to fit the whole screen.
function ListWindow:cellWidth()
  local w = ScreenManager.width - self.GUI:windowMargin() * 2
  return self:computeCellWidth(w)
end
-- @treturn string String representation (for debugging).
function ListWindow:__tostring()
  return 'List Window'
end

return ListWindow
