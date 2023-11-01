
-- ================================================================================================

--- Opens when the player chooses a target for the `CallAction`.
---------------------------------------------------------------------------------------------------
-- @menumod CallMenu
-- @extend Menu

-- ================================================================================================

-- Imports
local Menu = require('core/gui/Menu')
local CallWindow = require('core/gui/battle/window/interactable/CallWindow')
local TargetWindow = require('core/gui/battle/window/TargetWindow')

-- Class table.
local CallMenu = class(Menu)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `Menu:init`. 
-- @override
-- @tparam Menu parent Parent Menu.
-- @tparam Troop troop Current troop.
-- @tparam boolean allMembers If false will include only backup members.
function CallMenu:init(parent, troop, allMembers)
  self.troop = troop
  self.allMembers = allMembers
  Menu.init(self, parent)
end
--- Implements `Menu:createWindows`. Creates the CallWindow with the list of members, and TargetWindow
-- with selected member's info. 
-- @implement
function CallMenu:createWindows()
  self.name = 'Call Menu'
  -- Info window
  self.targetWindow = TargetWindow(self)
  -- List window
  self.callWindow = CallWindow(self, self.troop, self.allMembers)
  self:setActiveWindow(self.callWindow)
end

return CallMenu
