
--[[===============================================================================================

LoadWindow
---------------------------------------------------------------------------------------------------
Window that shows the list of save files to load.

=================================================================================================]]

-- Imports
local SaveWindow = require('core/gui/menu/window/interactable/SaveWindow')

local LoadWindow = class(SaveWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides SaveWindow:setProperties.
function LoadWindow:setProperties()
  SaveWindow.setProperties(self)
  self.tooltipTerm = 'loadSlot'
end
-- Overrides SaveWindow:createSaveButton.
function LoadWindow:createSaveButton(file, name)
  if SaveManager:getHeader(file) then
    return SaveWindow.createSaveButton(self, file, name)
  end
end

---------------------------------------------------------------------------------------------------
-- Input
---------------------------------------------------------------------------------------------------

-- When player chooses a file to load. Sets result as the save file name.
function LoadWindow:onButtonConfirm(button)
  self.result = button.file
end
-- When player cancels the load action. Sets result as an empty string. 
function LoadWindow:onButtonCancel(button)
  self.result = ''
end
-- Button enabled condition.
function LoadWindow:buttonEnabled(button)
  return SaveManager:getHeader(button.file) ~= nil
end
-- @ret(string) String representation (for debugging).
function LoadWindow:__tostring()
  return 'Load Window'
end

return LoadWindow
