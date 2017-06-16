
--[[===============================================================================================

The GUI that is visible during normal gameplay in the field.

=================================================================================================]]

-- Imports
local GUI = require('core/gui/GUI')

local FieldGUI = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

function FieldGUI:createWindows()
end

function FieldGUI:setProperties()
  self.name = 'Field GUI'
  self.blockField = false
end

local old_update = FieldGUI.update
function FieldGUI:update()
  old_update(self)
end

return FieldGUI
