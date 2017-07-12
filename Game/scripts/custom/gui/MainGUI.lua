
--[[===============================================================================================

The GUI that is openned when player presses the menu button in the field.

=================================================================================================]]

-- Imports
local GUI = require('core/gui/GUI')
local TestWindow = require('custom/gui/TestWindow')

local MainGUI = class(GUI)

function MainGUI:createWindows()
  self.name = 'Main GUI'
  local testWindow = TestWindow(self)
  self.windowList:add(testWindow)
  self.activeWindow = testWindow
end

return MainGUI
