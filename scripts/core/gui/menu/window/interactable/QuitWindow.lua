
-- ================================================================================================

--- Window with options to close / restart game.
---------------------------------------------------------------------------------------------------
-- @classmod QuitWindow
-- @extend OptionsWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local OptionsWindow = require('core/gui/menu/window/interactable/OptionsWindow')

-- Class table.
local QuitWindow = class(OptionsWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Implements `GridWindow:createWidgets`.
-- @implement
function QuitWindow:createWidgets()
  Button:fromKey(self, 'cancel')
  Button:fromKey(self, 'title')
  if GameManager:isDesktop() then
    Button:fromKey(self, 'close')
  end
end
--- When player cancels the quit action.
function QuitWindow:cancelConfirm()
  self.result = 0
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:colCount`. 
-- @override
function QuitWindow:colCount()
  return 1
end
--- Overrides `GridWindow:rowCount`. 
-- @override
function QuitWindow:rowCount()
  return GameManager:isDesktop() and 3 or 2
end
-- @treturn string String representation (for debugging).
function QuitWindow:__tostring()
  return 'Quit Window'
end

return QuitWindow
