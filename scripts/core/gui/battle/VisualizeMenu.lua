
-- ================================================================================================

--- Menu that is shown when player selects a battler during Visualize action.
---------------------------------------------------------------------------------------------------
-- @menumod VisualizeMenu
-- @extend Menu

-- ================================================================================================

-- Imports
local BattlerWindow = require('core/gui/common/window/BattlerWindow')
local Menu = require('core/gui/Menu')

-- Class table.
local VisualizeMenu = class(Menu)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `Menu:init`. 
-- @override
-- @tparam Menu parent Parent Menu.
-- @tparam Character character Member's character in the battle field.
function VisualizeMenu:init(parent, character)
  self.name = 'Visualize Menu'
  self.character = character
  Menu.init(self, parent)
end
--- Overrides `Menu:createWindows`.
-- @override
function VisualizeMenu:createWindows()
  local mainWindow = BattlerWindow(self)
  mainWindow:setBattler(self.character.battler)
  self:setActiveWindow(mainWindow)
end

return VisualizeMenu
