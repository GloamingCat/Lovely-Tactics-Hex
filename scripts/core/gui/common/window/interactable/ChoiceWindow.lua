
-- ================================================================================================

--- Shows a list of custom choices.
---------------------------------------------------------------------------------------------------
-- @windowmod ChoiceWindow
-- @extend GridWindow

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
-- @tparam Menu menu Parent Menu.
-- @tparam table choices Array of strings containing the text of each choice.
-- @tparam[opt] number cancelChoice The number of the choice returned when the player cancels.
--  If nil, the player can't cancel.
-- @tparam[opt] Vector pos Center position of the window.
-- @tparam[opt] number width Width of the window.
-- @tparam[opt="left"] string align Horizontal alignment of the button text.
function ChoiceWindow:init(menu, choices, cancelChoice, pos, width, align)
  self.choices = List(choices)
  self.width = width
  self.align = align or 'left'
  self.cancelChoice = cancelChoice
  GridWindow.init(self, menu, self.width, nil, pos)
end
--- Implements `GridWindow:creatwWidgets`. Creates a button for each choice.
-- @implement
function ChoiceWindow:createWidgets()
  for i = 1, self.choices.size do
    local choice = self.choices[i]
    local button = Button(self)
    button:createText(choice, nil, 'menu_button', self.align)
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
-- For debugging.
function ChoiceWindow:__tostring()
  return 'Choice Window ' .. tostring(self.choices)
end

return ChoiceWindow
