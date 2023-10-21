
-- ================================================================================================

--- Shows a list of custom choices.
---------------------------------------------------------------------------------------------------
-- @classmod ChoiceWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')
local List = require('core/datastruct/List')

-- Class table.
local ChoiceWindow = class(GridWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam GUI gui Parent GUI.
-- @tparam table args Table of arguments, including choies, width, align and cancel choice ID.
function ChoiceWindow:init(gui, args)
  self.choices = List(args.choices)
  self.width = args.width
  self.align = args.align
  self.cancelChoice = args.cancel
  GridWindow.init(self, gui, self.width, nil, args.pos)
end
--- Implements `GridWindow:creatwWidgets`. Creates a button for each choice.
-- @implement
function ChoiceWindow:createWidgets()
  for i = 1, self.choices.size do
    local choice = self.choices[i]
    local button = Button(self)
    button:createText(choice, '', 'gui_button', self.align)
    button.choice = i
  end
end

-- ------------------------------------------------------------------------------------------------
-- Input Callbacks
-- ------------------------------------------------------------------------------------------------

--- Sets the result as the choice ID.
-- @tparam Button button
function ChoiceWindow:onButtonConfirm(button)
  self.result = button.choice
end
--- Sets the result as the cancel choice ID.
function ChoiceWindow:onButtonCancel(button)
  self.result = self.cancelChoice
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:colCount`. 
-- @override
function ChoiceWindow:colCount()
  return 1
end
--- Overrides `GridWindow:rowCount`. 
-- @override
function ChoiceWindow:rowCount()
  return #self.choices
end
--- Overrides `GridWindow:cellWidth`. 
-- @override
function ChoiceWindow:cellWidth()
  return (self.width or 100) - self:paddingX() * 2
end
-- @treturn string String representation (for debugging).
function ChoiceWindow:__tostring()
  return 'Choice Window ' .. tostring(self.choices)
end

return ChoiceWindow
