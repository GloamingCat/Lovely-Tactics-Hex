
--[[===============================================================================================

ListWindow
---------------------------------------------------------------------------------------------------
A Button Window that has its buttons generated automatically given a list of arbitrary elements.

=================================================================================================]]

-- Imports
local GridWindow = require('core/gui/GridWindow')

local ListWindow = class(GridWindow)

----------------------------------------------------------------------------------------------------
-- Initialization
----------------------------------------------------------------------------------------------------

-- Overrides GridWindow:init.
-- @param(list : table) Array of data used to create each button.
function ListWindow:init(parent, list, ...)
  self.list = list
  GridWindow.init(self, parent, ...)
end
-- Overrides GridWindow:createWidgets.
function ListWindow:createWidgets()
  for i = 1, #self.list do
    self:createListButton(self.list[i])
  end
end
-- Creates a button from an element in the list.
function ListWindow:createListButton(element)
  -- Abstract.
end
-- Clears and recreates buttons.
function ListWindow:refreshButtons(list)
  self.list = list or self.list
  self:clearWidgets()
  self:createWidgets()
  GridWindow.refreshWidgets(self)
end

----------------------------------------------------------------------------------------------------
-- Properties
----------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function ListWindow:colCount()
  return 2
end
-- Larger buttons.
function ListWindow:cellWidth()
  local w = ScreenManager.width - self.GUI:windowMargin() * 2
  return (w - self:paddingX() * 2 - self:colMargin()) / 2
end
-- @ret(string) String representation (for debugging).
function ListWindow:__tostring()
  return 'List Window'
end

return ListWindow
