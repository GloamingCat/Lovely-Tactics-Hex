
--[[===============================================================================================

ConfirmGUI
---------------------------------------------------------------------------------------------------
The GUI that contains only a confirm window.

=================================================================================================]]

-- Imports
local GUI = require('core/gui/GUI')
local ConfirmWindow = require('core/gui/common/window/interactable/ConfirmWindow')

local ConfirmGUI = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides GUI:createWindow.
function ConfirmGUI:createWindows()
  self.name = 'Confirm GUI'
  local confirmWindow = ConfirmWindow(self)
  self:setActiveWindow(confirmWindow)
end

return ConfirmGUI
