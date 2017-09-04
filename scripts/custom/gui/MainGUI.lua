
--[[===============================================================================================

The GUI that is openned when player presses the menu button in the field.

=================================================================================================]]

-- Imports
local GUI = require('core/gui/GUI')
local MainWindow = require('core/gui/field/MainWindow')

local MainGUI = class(GUI)

function MainGUI:createWindows()
  self.name = 'Main GUI'
  local mainWindow = MainWindow(self)
  self.windowList:add(mainWindow)
  self:setActiveWindow(mainWindow)
end

return MainGUI
