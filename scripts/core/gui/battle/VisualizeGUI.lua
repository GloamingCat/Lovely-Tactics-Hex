
-- ================================================================================================

--- GUI that is shown when player selects a battler during Visualize action.
---------------------------------------------------------------------------------------------------
-- @classmod VisualizeGUI

-- ================================================================================================

-- Imports
local BattlerWindow = require('core/gui/common/window/BattlerWindow')
local GUI = require('core/gui/GUI')

-- Class table.
local VisualizeGUI = class(GUI)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `GUI:init`. 
-- @override
-- @tparam GUI parent Parent GUI.
-- @tparam Character character Member's character in the battle field.
function VisualizeGUI:init(parent, character)
  self.name = 'Visualize GUI'
  self.character = character
  GUI.init(self, parent)
end
--- Overrides `GUI:createWindows`.
-- @override
function VisualizeGUI:createWindows()
  local mainWindow = BattlerWindow(self)
  mainWindow:setBattler(self.character.battler)
  self:setActiveWindow(mainWindow)
end

return VisualizeGUI
