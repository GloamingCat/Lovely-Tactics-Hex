
-- ================================================================================================

--- The GUI that contains only a confirm window.
---------------------------------------------------------------------------------------------------
-- @uimod ConfirmGUI
-- @extend GUI

-- ================================================================================================

-- Imports
local GUI = require('core/gui/GUI')
local ConfirmWindow = require('core/gui/common/window/interactable/ConfirmWindow')

-- Class table.
local ConfirmGUI = class(GUI)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

function ConfirmGUI:init(parent, confirmTerm, cancelTerm, ...)
  self.confirmTerm = confirmTerm
  self.cancelTerm = cancelTerm
  GUI.init(self, parent, ...)
end
--- Overrides `GUI:createWindows`. 
-- @override
function ConfirmGUI:createWindows()
  self.name = 'Confirm GUI'
  local confirmWindow = ConfirmWindow(self, self.confirmTerm, self.cancelTerm)
  self:setActiveWindow(confirmWindow)
end

return ConfirmGUI
