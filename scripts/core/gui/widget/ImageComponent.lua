
-- ================================================================================================

--- A generic window content that stores a sprite with a given viewport.
---------------------------------------------------------------------------------------------------
-- @uimod ImageComponent
-- @extend Component

-- ================================================================================================

-- Imports
local Component = require('core/gui/Component')
local Sprite = require('core/graphics/Sprite')

-- Alias
local max = math.max
local min = math.min

-- Class table.
local ImageComponent = class(Component)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Sprite sprite Image's sprite.
-- @tparam number x The x position of the top-left corner inside parent.
-- @tparam number y The y position of the top-left corner inside parent.
-- @tparam number depth The depth of the image relative to parent.
-- @tparam number w Maximun width of the image.
-- @tparam number h Maximun height of the image.
function ImageComponent:init(sprite, x, y, depth, w, h)
  Component.init(self)
  self.position.z = depth or -1
  self.width = w
  self.height = h
  self.x = x
  self.y = y
  self:setSprite(sprite)
end
--- Changes the sprite in the component.
function ImageComponent:setSprite(sprite)
  if self.sprite then
    self.sprite:destroy()
  end
  self.content:clear()
  self.sprite = sprite
  if sprite then
    self:centerSpriteQuad()
    self.content:add(sprite)
  end
end
--- Centers sprite inside the given rectangle.
function ImageComponent:centerSpriteQuad()
  local px, py, pw, ph = self.sprite.quad:getViewport()
  pw, ph = pw * self.sprite.scaleX, ph * self.sprite.scaleY
  local x, y = self.x or 0, self.y or 0
  local w, h = self.width or pw, self.height or ph
  local mw, mh = min(pw, w), min(ph, h)
  local mx, my = (pw - mw) / 2, (ph - mh) / 2
  self.sprite:setQuad(px + mx, py + my, mw / self.sprite.scaleX, mh / self.sprite.scaleY)
  self.sprite:setCenterOffset()
  self.position.x = x + w / 2
  self.position.y = y + h / 2
end

-- ------------------------------------------------------------------------------------------------
-- Window Content methods
-- ------------------------------------------------------------------------------------------------

--- Overrides `Component:updatePosition`. 
-- @override
function ImageComponent:updatePosition(pos)
  if self.sprite then
    local rpos = self.position
    self.sprite:setXYZ(pos.x + rpos.x, pos.y + rpos.y, pos.z + rpos.z)
  end
end

return ImageComponent
