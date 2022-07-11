
--[[===============================================================================================

CallGUI
---------------------------------------------------------------------------------------------------
The GUI that is openned when player chooses a target for the call action.

=================================================================================================]]

-- Imports
local GUI = require('core/gui/GUI')
local CallWindow = require('core/gui/battle/window/interactable/CallWindow')
local TargetWindow = require('core/gui/battle/window/TargetWindow')

local CallGUI = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides GUI:init.
-- @param(troop : Troop) Current troop.
-- @param(allMembers : boolean) If false will include only backup members.
function CallGUI:init(parent, troop, allMembers)
  self.troop = troop
  self.allMembers = allMembers
  GUI.init(self, parent)
end
-- Implements GUI:createWindows.
-- Creates the CallWindow with the list of members, and TargetWindow with selected member's info. 
function CallGUI:createWindows()
  self.name = 'Call GUI'
  -- Info window
  self.targetWindow = TargetWindow(self)
  -- List window
  self.callWindow = CallWindow(self, self.troop, self.allMembers)
  self:setActiveWindow(self.callWindow)
end

return CallGUI
