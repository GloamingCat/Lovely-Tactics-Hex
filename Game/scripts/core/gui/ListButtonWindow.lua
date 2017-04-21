
--[[===============================================================================================

ListButtonWindow
---------------------------------------------------------------------------------------------------
A Button Window that has its buttons generated automatically given a list of
arbitrary elements.

=================================================================================================]]

-- Imports
local ButtonWindow = require('core/gui/ButtonWindow')

local ListButtonWindow = ButtonWindow:inherit()

----------------------------------------------------------------------------------------------------
-- Initialization
----------------------------------------------------------------------------------------------------

-- Overrides ButtonWindow:init.
local old_init = ListButtonWindow.init
function ListButtonWindow:init(list, ...)
  self.list = list
  old_init(self, ...)
end

-- Overrides ButtonWindow:createButtons.
function ListButtonWindow:createButtons()
  for i = 1, #self.list do
    self:createButton(self.list[i])
  end
end

-- Creates a button from an element in the list.
function ListButtonWindow:createButton(element)
end

return ListButtonWindow
