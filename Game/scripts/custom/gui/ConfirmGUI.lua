
local GUI = require('core/gui/GUI')
local ConfirmWindow = require('custom/gui/ConfirmWindow')

--[[===========================================================================

The GUI that contains only a confirm window.

=============================================================================]]

local ConfirmGUI = class(GUI)

function ConfirmGUI:createWindows()
  self.name = 'Confirm GUI'
  local confirmWindow = ConfirmWindow(self)
  self.windows:add(confirmWindow)
  self.activeWindow = confirmWindow
end

return ConfirmGUI
