
--[[===============================================================================================

SimpleImage
---------------------------------------------------------------------------------------------------
A generic window content that stores a sprite with a given viewport.

=================================================================================================]]

-- Imports
local Component = require('core/gui/Component')
local Sprite = require('core/graphics/Sprite')

-- Alias
local max = math.max
local min = math.min

local SimpleImage = class(Component)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(sprite : Sprite) Image's sprite.
-- @param(x : number) The x position of the top-left corner inside parent.
-- @param(y : number) The y position of the top-left corner inside parent.
-- @param(depth : number) The depth of the image relative to parent.
-- @param(w : number) Maximun width of the image.
-- @param(h : number) Maximun height of the image.
function SimpleImage:init(sprite, x, y, depth, w, h)
  Component.init(self)
  self.position.z = depth or -1
  self.width = w
  self.height = h
  self.x = x
  self.y = y
  self:setSprite(sprite)
end
-- Changes the sprite in the component.
function SimpleImage:setSprite(sprite)
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
-- Centers sprite inside the given rectangle.
function SimpleImage:centerSpriteQuad()
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

---------------------------------------------------------------------------------------------------
-- Window Content methods
---------------------------------------------------------------------------------------------------

-- Overrides Component:updatePosition.
function SimpleImage:updatePosition(pos)
  if self.sprite then
    local rpos = self.position
    self.sprite:setXYZ(pos.x + rpos.x, pos.y + rpos.y, pos.z + rpos.z)
  end
end

return SimpleImage
