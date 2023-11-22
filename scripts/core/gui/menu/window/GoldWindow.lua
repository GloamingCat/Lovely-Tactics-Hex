
-- ================================================================================================

--- Small window that shows the troop's money.
---------------------------------------------------------------------------------------------------
-- @windowmod GoldWindow
-- @extend Window

-- ================================================================================================

-- Imports
local ImageComponent = require('core/gui/widget/ImageComponent')
local TextComponent = require('core/gui/widget/TextComponent')
local Vector = require('core/math/Vector')
local Window = require('core/gui/Window')

-- Class table.
local GoldWindow = class(Window)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Implements `Window:createContent`.
-- @implement
function GoldWindow:createContent(width, height)
  Window.createContent(self, width, height)
  local icon = Config.icons.money
  local sprite = icon and icon.id >= 0 and ResourceManager:loadIcon(icon, MenuManager.renderer)
  local pos = Vector(self:paddingX() - width / 2, self:paddingY() - height / 2, -1)
  if sprite then
    local x1, _, x2, _ = sprite:getBoundingBox()
    local imgPos = Vector(pos.x + (x2 - x1) / 2, 0)
    icon = ImageComponent(sprite, imgPos, nil, nil)
    self.content:add(icon)
  end
  local text = TextComponent('', pos, width - self:paddingX() * 2, 'right', Fonts.menu_medium)
  text.sprite.alignY = 'center'
  text.sprite.maxHeight = height - self:paddingY() * 2
  self.content:add(text)
  self.value = text
end
--- Sets the money value shown.
-- @tparam number money The current number of money.
function GoldWindow:setGold(money)
  self.value:setTerm(money .. ' {%g}', money .. '')
  self.value:redraw()
end

return GoldWindow
