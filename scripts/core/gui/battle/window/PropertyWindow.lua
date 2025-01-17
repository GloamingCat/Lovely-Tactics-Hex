
-- ================================================================================================

--- Show a property of the current character.
--- It opens in `ActionMenu` to show number of steps.
---------------------------------------------------------------------------------------------------
-- @windowmod PropertyWindow
-- @extend Window

-- ================================================================================================

-- Imports
local Vector = require('core/math/Vector')
local Window = require('core/gui/Window')
local TextComponent = require('core/gui/widget/TextComponent')

-- Class table.
local PropertyWindow = class(Window)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `Window:init`. 
-- @override
function PropertyWindow:init(Menu)
  local w, h, m = 90, 30, Menu:windowMargin()
  Window.init(self, Menu, w, h, Vector(ScreenManager.width / 2 - w / 2 - m, 
      ScreenManager.height / 2 - h / 2 - m))
end
--- Overrides `Window:createContent`. Creates step text.
-- @override
function PropertyWindow:createContent(width, height)
  Window.createContent(self, width, height)
  local w = self.width - self:paddingX() * 2
  local h = self.height - self:paddingY() * 2
  local pos = Vector(self:paddingX() - self.width / 2, self:paddingY() - self.height / 2)
  local text = TextComponent('', pos, w)
  local value = TextComponent('', pos, w)
  text:setAlign('left', 'center')
  text:setMaxHeight(h)
  value:setAlign('right', 'center')
  value:setMaxHeight(h)
  self.txtLabel = text
  self.txtValue = value
  self.content:add(text)
  self.content:add(value)
end
--- Sets content.
-- @tparam string term Property label.
-- @tparam unknown value Property value.
function PropertyWindow:setProperty(term, value)
  self.txtLabel:setTerm('{%' .. term .. '}:', term .. ':')
  self.txtLabel:redraw()
  self.txtValue:setText(tostring(value))
  self.txtValue:redraw()
end
-- For debugging.
function PropertyWindow:__tostring()
  return 'Property Window'
end

return PropertyWindow
