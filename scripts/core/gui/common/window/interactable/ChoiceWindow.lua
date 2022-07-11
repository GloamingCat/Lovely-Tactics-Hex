
--[[===============================================================================================

ChoiceWindow
---------------------------------------------------------------------------------------------------
Shows a list of custom choices.

=================================================================================================]]

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')
local List = require('core/datastruct/List')

local ChoiceWindow = class(GridWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(gui : GUI) Parent GUI.
-- @param(args : table) Table of arguments, including choies, width, align and cancel choice ID.
function ChoiceWindow:init(gui, args)
  self.choices = List(args.choices)
  self.width = args.width
  self.align = args.align
  self.cancelChoice = args.cancel
  GridWindow.init(self, gui, self.width, nil, args.pos)
end
-- Implements GridWindow:creatwWidgets.
-- Creates a button for each choice.
function ChoiceWindow:createWidgets()
  for i = 1, self.choices.size do
    local choice = self.choices[i]
    local button = Button(self)
    button:createText(choice, 'gui_medium', self.align)
    button.choice = i
  end
end

---------------------------------------------------------------------------------------------------
-- Input Callbacks
---------------------------------------------------------------------------------------------------

-- Sets the result as the choice ID.
-- @param(button : Button)
function ChoiceWindow:onButtonConfirm(button)
  self.result = button.choice
end
-- Sets the result as the cancel choice ID.
function ChoiceWindow:onButtonCancel(button)
  self.result = self.cancelChoice
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function ChoiceWindow:colCount()
  return 1
end
-- Overrides GridWindow:rowCount.
function ChoiceWindow:rowCount()
  return #self.choices
end
-- Overrides GridWindow:cellWidth.
function ChoiceWindow:cellWidth()
  return (self.width or 100) - self:paddingX() * 2
end
-- @ret(string) String representation (for debugging).
function ChoiceWindow:__tostring()
  return 'Choice Window ' .. tostring(self.choices)
end

return ChoiceWindow
