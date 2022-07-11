
--[[===============================================================================================

ResolutionWindow
---------------------------------------------------------------------------------------------------
Window with resolution options.

=================================================================================================]]

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')

local ResolutionWindow = class(GridWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Implements GridWindow:createWidgets.
function ResolutionWindow:createWidgets()
  Button:fromKey(self, 'resolution1')
  Button:fromKey(self, 'resolution2')
  Button:fromKey(self, 'resolution3')
  Button:fromKey(self, 'fullScreen')
end

---------------------------------------------------------------------------------------------------
-- Input
---------------------------------------------------------------------------------------------------

-- Chooses new resolution.
function ResolutionWindow:onButtonConfirm(button)
  ScreenManager:setMode( button.index)
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function ResolutionWindow:colCount()
  return 1
end
-- Overrides GridWindow:rowCount.
function ResolutionWindow:rowCount()
  return 4
end
-- @ret(string) String representation (for debugging).
function ResolutionWindow:__tostring()
  return 'Resolution Window'
end

return ResolutionWindow
