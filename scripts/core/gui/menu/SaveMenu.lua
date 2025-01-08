
-- ================================================================================================

--- Menu to save the game.
---------------------------------------------------------------------------------------------------
-- @menumod SaveMenu
-- @extend Menu

-- ================================================================================================

-- Imports
local Menu = require('core/gui/Menu')
local SaveWindow = require('core/gui/menu/window/interactable/SaveWindow')

-- Class table.
local SaveMenu = class(Menu)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `Menu:createWindows`. 
-- @override
function SaveMenu:createWindows()
  self.name = 'Save Menu'
  self:createMainWindow()
end
--- Creates the list with the main commands.
function SaveMenu:createMainWindow()
  self.mainWindow = SaveWindow(self)
  self:setActiveWindow(self.mainWindow)
end

return SaveMenu
