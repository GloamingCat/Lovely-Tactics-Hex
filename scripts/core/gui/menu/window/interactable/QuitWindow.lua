
--[[===============================================================================================

QuitWindow
---------------------------------------------------------------------------------------------------
Window with options to close / restart game.

=================================================================================================]]

-- Imports
local Button = require('core/gui/widget/control/Button')
local OptionsWindow = require('core/gui/menu/window/interactable/OptionsWindow')

local QuitWindow = class(OptionsWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Implements GridWindow:createWidgets.
function QuitWindow:createWidgets()
  Button:fromKey(self, 'cancel')
  Button:fromKey(self, 'title')
  if not GameManager:isWeb() then
    Button:fromKey(self, 'close')
  end
end
-- When player cancels the quit action.
function QuitWindow:cancelConfirm()
  self.result = 0
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function QuitWindow:colCount()
  return 1
end
-- Overrides GridWindow:rowCount.
function QuitWindow:rowCount()
  return GameManager:isWeb() and 2 or 3
end
-- @ret(string) String representation (for debugging).
function QuitWindow:__tostring()
  return 'Quit Window'
end

return QuitWindow
