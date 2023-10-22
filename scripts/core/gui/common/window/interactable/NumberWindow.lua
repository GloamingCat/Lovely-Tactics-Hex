
-- ================================================================================================

--- Shows a list of numbers from 0 to 9 to be chosen.
---------------------------------------------------------------------------------------------------
-- @classmod NumberWindow
-- @extend GridWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')
local List = require('core/datastruct/List')
local VSpinner = require('core/gui/widget/control/VSpinner')

-- Class table.
local NumberWindow = class(GridWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `Window:init`. 
-- @override
function NumberWindow:init(GUI, args)
  self.noCursor = true
  self.length = args.length
  self.width = args.width
  self.align = args.align
  self.cancelValue = args.cancel
  GridWindow.init(self, GUI, self.width, nil, args.pos)
end
--- Implements `GridWindow:createWidgets`.
-- @implement
function NumberWindow:createWidgets()
  for i = 1, self.length do
    VSpinner(self, 0, 9, 0)
  end
  Button:fromKey(self, 'ok').text.sprite.alignX = 'center'
end

-- ------------------------------------------------------------------------------------------------
-- Input handlers
-- ------------------------------------------------------------------------------------------------

--- Called with player confirms chosen number.
function NumberWindow:onButtonConfirm(button)
  self:onSpinnerConfirm(nil)
end
--- Called with player presses a confirm key.
function NumberWindow:onSpinnerConfirm(spinner)
  self.result = self:getValue()
end
--- Called with player presses a cancel key.
function NumberWindow:onSpinnerCancel(spinner)
  self.result = self.cancelValue
end

-- ------------------------------------------------------------------------------------------------
-- Value
-- ------------------------------------------------------------------------------------------------

--- Gets current number.
-- @treturn number
function NumberWindow:getValue()
  local value = 0
  local e = 1
  for i = self.length, 1, -1 do
    value = value + e * self.matrix[i].value
    e = e * 10
  end
  return value
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:colCount`. 
-- @override
function NumberWindow:colCount()
  return self.length + 1
end
--- Overrides `GridWindow:rowCount`. 
-- @override
function NumberWindow:rowCount()
  return 1
end
--- Overrides `GridWindow:cellWidth`. 
-- @override
function NumberWindow:cellWidth()
  return 16
end
--- Overrides `GridWindow:cellHeight`. 
-- @override
function NumberWindow:cellHeight()
  return (self.height or 48) - self:paddingY() * 2
end
-- For debugging.
function NumberWindow:__tostring()
  return 'NumberWindow: ' .. tostring(self.choices)
end

return NumberWindow
