
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

--- Constructor.
-- @tparam Menu parent Parent menu.
-- @tparam string description The text shown in the window above the input window.
-- @tparam[opt=0]  number minLength The minimum length of the input text.
-- @tparam[opt] number maxLength The maximum length of the input text.
-- @tparam[opt] number cancelValue The value returned when the player cancels.
--  If nil, the player can't cancel.
function TextInputMenu:init(parent, description, minLength, maxLength, cancelValue)
  self.description = description
  self.minLength = minLength
  self.maxLength = maxLength
  Menu.init(self, parent)
end
--- Overrides `Menu:createWindows`. 
-- @override
function TextInputMenu:createWindows()
  self.name = 'TextInput Menu'
  local textWindow = TextInputWindow(self, self.minLength, self.maxLength, self.cancelValue,
    nil, nil, Vector(0, 0, -10))
  if self.description then
    local descriptionWindow = DescriptionWindow(self, 100, 30, Vector(0, -50, -10))
    descriptionWindow.text:setMaxHeight(30 - descriptionWindow:paddingY() * 2)
    descriptionWindow.text:setAlign('center', 'center')
    descriptionWindow:updateText(self.description)
  end
  self.mainWindow = textWindow
  self:setActiveWindow(textWindow)
end

return TextInputMenu
