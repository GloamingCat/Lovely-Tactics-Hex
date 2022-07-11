
--[[===============================================================================================

TextInputGUI
---------------------------------------------------------------------------------------------------
The GUI that contains only a text input window.

=================================================================================================]]

-- Imports
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local GUI = require('core/gui/GUI')
local TextInputWindow = require('core/gui/common/window/interactable/TextInputWindow')
local Vector = require('core/math/Vector')

local TextInputGUI = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides GUI:init.
function TextInputGUI:init(parent, description, emptyAllowed, cancelAllowed)
  self.description = description
  self.emptyAllowed = emptyAllowed
  self.cancelAllowed = cancelAllowed
  GUI.init(self, parent)
end
-- Overrides GUI:createWindow.
function TextInputGUI:createWindows()
  self.name = 'TextInput GUI'
  local textWindow = TextInputWindow(self, self.emptyAllowed, self.cancelAllowed)
  if self.description then
    local descriptionWindow = DescriptionWindow(self, 100, 30, Vector(0, -50, 0))
    descriptionWindow.text:setMaxHeight(30 - descriptionWindow:paddingY() * 2)
    descriptionWindow.text:setAlign('center', 'center')
    descriptionWindow:updateText(self.description)
  end
  self.mainWindow = textWindow
  self:setActiveWindow(textWindow)
end

return TextInputGUI
