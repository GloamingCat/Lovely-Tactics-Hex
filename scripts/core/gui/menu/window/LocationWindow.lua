
-- ================================================================================================

--- Small window that shows the location of the player.
---------------------------------------------------------------------------------------------------
-- @windowmod LocationWindow
-- @extend Window

-- ================================================================================================

-- Imports
local ImageComponent = require('core/gui/widget/ImageComponent')
local TextComponent = require('core/gui/widget/TextComponent')
local Vector = require('core/math/Vector')
local Window = require('core/gui/Window')

-- Class table.
local LocationWindow = class(Window)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `Window:createContent`. 
-- @override
function LocationWindow:createContent(width, height)
  Window.createContent(self, width, height)
  local icon = Config.icons.location
  local sprite = icon and icon.id >= 0 and ResourceManager:loadIcon(icon, MenuManager.renderer)
  icon = ImageComponent(sprite, -width / 2 + 4, -height / 2, -1, nil, height)
  self.content:add(icon)
  local pos = Vector(self:paddingX() - width / 2, self:paddingY() - height / 2, -1)
  if sprite then
    pos.x = pos.x + self:paddingX() * 2
  end
  local text = TextComponent('', pos, width - self:paddingX() * 2, 'left', Fonts.menu_medium)
  text.sprite.alignY = 'center'
  text.sprite.maxHeight = height - self:paddingY() * 2
  self.content:add(text)
  self.name = text
end
--- Sets the name shown.
-- @tparam Field field Current field.
function LocationWindow:setLocal(field)
  self.name:setTerm('data.field.' .. field.key, field.name)
  self.name:redraw()
end

return LocationWindow
