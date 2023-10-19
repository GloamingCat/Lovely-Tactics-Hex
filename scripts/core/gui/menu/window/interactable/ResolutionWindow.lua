
-- ================================================================================================

--- Window with resolution options.
---------------------------------------------------------------------------------------------------
-- @classmod ResolutionWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')

-- Class table.
local ResolutionWindow = class(GridWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Implements `GridWindow:createWidgets`.
-- @implement createWidgets
function ResolutionWindow:createWidgets()
  Button:fromKey(self, 'resolution1')
  Button:fromKey(self, 'resolution2')
  Button:fromKey(self, 'resolution3')
  Button:fromKey(self, 'fullScreen')
end

-- ------------------------------------------------------------------------------------------------
-- Input
-- ------------------------------------------------------------------------------------------------

--- Chooses new resolution.
function ResolutionWindow:onButtonConfirm(button)
  ScreenManager:setMode(button.index % self:rowCount())
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:colCount`. 
-- @override colCount
function ResolutionWindow:colCount()
  return 1
end
--- Overrides `GridWindow:rowCount`. 
-- @override rowCount
function ResolutionWindow:rowCount()
  return 4
end
-- @treturn string String representation (for debugging).
function ResolutionWindow:__tostring()
  return 'Resolution Window'
end

return ResolutionWindow
