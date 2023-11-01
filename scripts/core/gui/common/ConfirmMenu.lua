
-- ================================================================================================

--- Contains only a `ConfirmWindow`.
---------------------------------------------------------------------------------------------------
-- @menumod ConfirmMenu
-- @extend Menu

-- ================================================================================================

-- Imports
local Menu = require('core/gui/Menu')
local ConfirmWindow = require('core/gui/common/window/interactable/ConfirmWindow')

-- Class table.
local ConfirmMenu = class(Menu)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Menu parent Parent Menu.
-- @tparam string confirmTerm Term for the confirm button, from the `Vocab` table.
-- @tparam string cancelTerm Term for the cancel button, from the `Vocab` table.
function ConfirmMenu:init(parent, confirmTerm, cancelTerm)
  self.confirmTerm = confirmTerm
  self.cancelTerm = cancelTerm
  Menu.init(self, parent)
end
--- Overrides `Menu:createWindows`. 
-- @override
function ConfirmMenu:createWindows()
  self.name = 'Confirm Menu'
  local confirmWindow = ConfirmWindow(self, self.confirmTerm, self.cancelTerm)
  self:setActiveWindow(confirmWindow)
end

return ConfirmMenu
