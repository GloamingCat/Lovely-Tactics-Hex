
--[[===============================================================================================

ConfirmGUI
---------------------------------------------------------------------------------------------------
The GUI that contains only a confirm window.

=================================================================================================]]

-- Imports
local GUI = require('core/gui/GUI')
local ConfirmWindow = require('core/gui/general/ConfirmWindow')

local ConfirmGUI = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

function ConfirmGUI:createWindows()
  self.name = 'Confirm GUI'
  local confirmWindow = ConfirmWindow(self)
  self.windowList:add(confirmWindow)
  self:setActiveWindow(confirmWindow)
end

return ConfirmGUI
