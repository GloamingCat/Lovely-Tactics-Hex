
-- ================================================================================================

--- Window with resolution options.
---------------------------------------------------------------------------------------------------
-- @windowmod ResolutionWindow
-- @extend GridWindow

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
-- @implement
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
-- @override
function ResolutionWindow:colCount()
  return 1
end
--- Overrides `GridWindow:rowCount`. 
-- @override
function ResolutionWindow:rowCount()
  return 4
end
-- For debugging.
function ResolutionWindow:__tostring()
  return 'Resolution Window'
end

return ResolutionWindow
