
local GUI = require('core/gui/GUI')
local TestWindow = require('custom/gui/TestWindow')

--[[===========================================================================

The GUI that is openned when player presses the menu button in the field.

=============================================================================]]

local MainGUI = GUI:inherit()

function MainGUI:createWindows()
  self.name = 'Main GUI'
  local testWindow = TestWindow(self)
  self.windows:add(testWindow)
  self.activeWindow = testWindow
end

return MainGUI
