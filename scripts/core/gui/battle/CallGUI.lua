
--[[===============================================================================================

CallGUI
---------------------------------------------------------------------------------------------------
The GUI that is openned when player chooses a target for the call action

=================================================================================================]]

-- Imports
local GUI = require('core/gui/GUI')
local CallWindow = require('core/gui/battle/window/CallWindow')
local TargetWindow = require('core/gui/battle/window/TargetWindow')

local CallGUI = class(GUI)

function CallGUI:init(troop)
  self.troop = troop
  GUI.init(self)
end

function CallGUI:createWindows()
  self.name = 'Call GUI'
  -- Info window
  self.targetWindow = TargetWindow(self)
  self.windowList:add(self.targetWindow)
  -- List window
  local callWindow = CallWindow(self, self.troop)
  self.windowList:add(callWindow)
  self:setActiveWindow(callWindow)
end

return CallGUI
