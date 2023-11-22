
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
-- @tparam Sprite|Animation|SpriteGrid img Image's sprite or the animation with the sprite.
-- @tparam[opt] Vector position The position of the top-left corner inside parent.
-- @tparam[opt] number w Maximun width of the image.
-- @tparam[opt] number h Maximun height of the image.
-- @tparam[opt=Vector(0,0,0)] The relative position of the component.
-- @param ... Any other parameters passed to the `Component:createContent` method.
function ImageComponent:init(img, position, w, h, ...)
  self.width = w
  self.height = h
  Component.init(self, position, img, ...)
end
--- Sets the sprite.
--- Implements `Component:createContent`.
-- @implement
-- @tparam Sprite|Animation|SpriteGrid img Image's sprite or the animation with the sprite.
function ImageComponent:createContent(img)
  self:setImage(img)
end
--- Sets the current sprite.
-- @tparam[opt] Sprite|Animation|SpriteGrid img Image's sprite or the animation with the sprite.
function ImageComponent:setImage(img)
  if not img then
    self:setSprite(nil)
  elseif img.quad or img.slices then
    -- Is sprite or spritegrid
    self:setSprite(img)
  else
    -- Is animation
    self:setSprite(img.sprite)
    self.anim = img
  end
end
--- Sets the current sprite.
-- @tparam Sprite sprite Image's current sprite.
function ImageComponent:setSprite(sprite)
  if self.sprite then
    if self.anim then
      self.anim:destroy(dt)
    elseif self.sprite then
      self.sprite:destroy()
    end
  end
  self.sprite = sprite
  if sprite then
    self:limitSpriteQuad()
  end
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Overrides `Component:update`.
-- @override
function ImageComponent:update(dt)
  Component.update(self, dt)
  if self.anim then
    self.anim:update(dt)
  end
end
--- Overrides `Component:destroy`.
-- @override
function ImageComponent:destroy()
  Component.destroy(self)
  if self.anim then
    self.anim:destroy()
  elseif self.sprite then
    self.sprite:destroy()
  end
end

-- ------------------------------------------------------------------------------------------------
-- Position
-- ------------------------------------------------------------------------------------------------

--- Cuts off parts of the texture quad that doesn't fit in the component's limits.
function ImageComponent:limitSpriteQuad()
  local x, y, w, h = self.sprite:getQuadBox()
  local sx = self.sprite.scaleX or 1
  local sy = self.sprite.scaleY or 1
  local ox = self.sprite.offsetX or 0
  local oy = self.sprite.offsetY or 0
  if self.width and w * sx > self.width then
    local d = math.floor((w - self.width / sx) / 2)
    x = x + d
    ox = ox - d
    w = self.width / sx
  end
  if self.height and h * sy > self.height then
    local d = math.floor((h - self.height / sy) / 2)
    y = y + d
    oy = oy - d
    h = self.height / sy
  end
  self.sprite:setQuad(x, y, w, h)
  if self.sprite.setOffset then
    self.sprite:setOffset(ox, oy)
  end
end
--- Overrides `Component:updatePosition`. 
-- @override
function ImageComponent:updatePosition(pos)
  if self.sprite then
    local rx = self.position.x + (self.width or 0) / 2
    local ry = self.position.y + (self.height or 0) / 2
    if pos then
      self.sprite:setXYZ(pos.x + rx, pos.y + ry, pos.z + self.position.z)
    else
      self.sprite:setXYZ(rx, ry, self.position.z)
    end
  end
  Component.updatePosition(self, pos)
end

-- ------------------------------------------------------------------------------------------------
-- Visibility
-- ------------------------------------------------------------------------------------------------

--- Sets sprite's color.
-- @tparam boolean value
function ImageComponent:setVisible(value)
  if self.sprite then
    self.sprite:setVisible(value)
  end
  Component.setVisible(self, value)
end

-- ------------------------------------------------------------------------------------------------
-- Color
-- ------------------------------------------------------------------------------------------------

--- Sets sprite's color.
-- @tparam Color.RGBA color New color.
function ImageComponent:setColor(color)
  if self.sprite then
    self.sprite:setRGBA(color.r, color.g, color.b, color.a)
  end
  Component.setVisible(self, color)
end

return ImageComponent
