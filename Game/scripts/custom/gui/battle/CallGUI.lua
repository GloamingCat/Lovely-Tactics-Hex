
--[[===============================================================================================

CallGUI
---------------------------------------------------------------------------------------------------
The GUI that is openned when player chooses a target for the call action

=================================================================================================]]

-- Imports
local GUI = require('core/gui/GUI')
local CallWindow = require('core/gui/battle/CallWindow')

local CallGUI = class(GUI)

function CallGUI:init(tile)
  GUI.init(self)
  self.tile = tile
end

function CallGUI:createWindows()
  self.name = 'Call GUI'
  local callWindow = CallWindow(self, self.tile)
  self.windowList:add(callWindow)
  self.activeWindow = callWindow
end

return CallGUI
