
local GUI = require('core.gui.GUI')

--[[===========================================================================

The GUI that is visible during normal gameplay in the field.

=============================================================================]]

local FieldGUI = GUI:inherit()

function FieldGUI:setProperties()
  self.name = 'Field GUI'
  self.blockField = false
end

function FieldGUI:createWindows()
end

local old_update = FieldGUI.update
function FieldGUI:update()
  old_update(self)
end

return FieldGUI
