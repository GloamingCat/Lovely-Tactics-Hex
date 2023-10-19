
-- ================================================================================================

--- The GUI that is openned when player chooses a target for the call action.
---------------------------------------------------------------------------------------------------
-- @classmod CallGUI

-- ================================================================================================

-- Imports
local GUI = require('core/gui/GUI')
local CallWindow = require('core/gui/battle/window/interactable/CallWindow')
local TargetWindow = require('core/gui/battle/window/TargetWindow')

-- Class table.
local CallGUI = class(GUI)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `GUI:init`. 
-- @override init
-- @tparam GUI parent Parent GUI.
-- @tparam Troop troop Current troop.
-- @tparam boolean allMembers If false will include only backup members.
function CallGUI:init(parent, troop, allMembers)
  self.troop = troop
  self.allMembers = allMembers
  GUI.init(self, parent)
end
--- Implements `GUI:createWindows`. Creates the CallWindow with the list of members, and TargetWindow
-- with selected member's info. 
-- @implement createWindows
function CallGUI:createWindows()
  self.name = 'Call GUI'
  -- Info window
  self.targetWindow = TargetWindow(self)
  -- List window
  self.callWindow = CallWindow(self, self.troop, self.allMembers)
  self:setActiveWindow(self.callWindow)
end

return CallGUI
