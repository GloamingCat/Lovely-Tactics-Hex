
-- ================================================================================================

--- Menu that contains only a `TextInputWindow`.
---------------------------------------------------------------------------------------------------
-- @menumod TextInputMenu
-- @extend Menu

-- ================================================================================================

-- Imports
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local Menu = require('core/gui/Menu')
local TextInputWindow = require('core/gui/common/window/interactable/TextInputWindow')
local Vector = require('core/math/Vector')

-- Class table.
local TextInputMenu = class(Menu)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `Menu:init`. 
-- @override
function TextInputMenu:init(parent, description, emptyAllowed, cancelAllowed)
  self.description = description
  self.emptyAllowed = emptyAllowed
  self.cancelAllowed = cancelAllowed
  Menu.init(self, parent)
end
--- Overrides `Menu:createWindows`. 
-- @override
function TextInputMenu:createWindows()
  self.name = 'TextInput Menu'
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

return TextInputMenu
