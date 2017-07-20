
--[[===============================================================================================

VisualizeGUI
---------------------------------------------------------------------------------------------------
GUI that is shown when player selects a battler during Visualize action.

=================================================================================================]]

-- Imports
local GUI = require('core/gui/GUI')
local BattlerWindow = require('core/gui/battle/BattlerWindow')

local VisualizeGUI = class(GUI)

function VisualizeGUI:init(character)
  self.name = 'Visualize GUI'
  self.character = character
  print(character)
  GUI.init(self)
end

function VisualizeGUI:createWindows()
  local mainWindow = BattlerWindow(self, self.character)
  self.windowList:add(mainWindow)
  self.activeWindow = mainWindow
end

return VisualizeGUI
