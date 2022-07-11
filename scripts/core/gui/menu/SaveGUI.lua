
--[[===============================================================================================

SaveGUI
---------------------------------------------------------------------------------------------------


=================================================================================================]]

-- Imports
local GUI = require('core/gui/GUI')
local SaveWindow = require('core/gui/menu/window/interactable/SaveWindow')

local SaveGUI = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides GUI:createWindows.
function SaveGUI:createWindows()
  self.name = 'Save GUI'
  self:createMainWindow()
end
-- Creates the list with the main commands.
function SaveGUI:createMainWindow()
  self.mainWindow = SaveWindow(self)
  self:setActiveWindow(self.mainWindow)
end

return SaveGUI
