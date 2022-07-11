
--[[===============================================================================================

SpriteGrid
---------------------------------------------------------------------------------------------------
A group of sprites created from a 9-sliced skin.

=================================================================================================]]

-- Imports
local Sprite = require('core/graphics/Sprite')
local Vector = require('core/math/Vector')

-- Alias
local Quad = love.graphics.newQuad
local floor = math.floor

local SpriteGrid = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(skin : Image) The image to be 9-sliced.
function SpriteGrid:init(skin, relativePos)
  self.skin = skin
  self.position = relativePos or Vector(0, 0)
end
-- Creates sprites and skinData.
-- @param(renderer : Renderer) The renderer of the sprites.
-- @param(width : number) The width of the final image.
-- @param(height : number) The height of the final image.
function SpriteGrid:createGrid(renderer, width, height)
  local skin = self.skin.quad
  local w = skin.width / 3
  local h = skin.height / 3
  local mw = width - 2 * w
  local mh = height - 2 * h
  self.skinData = {}
  local x, y, ox, oy, sx, sy
  for i = 1, 9 do
    if i % 3 == 1 then
      x = 0
      sx = w
      ox = width / 2
    elseif i % 3 == 2 then
      x = w
      sx = mw
      ox = mw / 2
    else
      x = w * 2
      sx = w
      ox = -mw / 2
    end
    if i <= 3 then
      y = 0
      sy = h
      oy = height / 2
    elseif i <= 6 then
      y = h
      sy = mh
      oy = mh / 2
    else
      y = h * 2
      sy = h
      oy = -mh / 2
    end
    self.skinData[i] = {}
    self.skinData[i].quad = Quad(skin.x + x, skin.y + y, w, h, skin.width, skin.height)
    self.skinData[i].sx = sx / w
    self.skinData[i].sy = sy / h
    self.skinData[i].x = ox / self.skinData[i].sx
    self.skinData[i].y = oy / self.skinData[i].sy
  end
  if self.slices then
    for i = 1, 9 do
      self.slices[i]:destroy()
    end
  end
  self.slices = {}
  local texture = ResourceManager:loadTexture(skin.path)
  for i = 1, 9 do
    local sprite = Sprite(renderer, texture, self.skinData[i].quad)
    self.slices[i] = ResourceManager:loadAnimation(self.skin, sprite)
    sprite:setOffset(self.skinData[i].x, self.skinData[i].y)
    sprite:setScale(self.skinData[i].sx, self.skinData[i].sy)
  end
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Updates each slice animation.
function SpriteGrid:update()
  for i = 1, 9 do
    self.slices[i]:update()
  end
end
-- Updates position and scale according to the given parent transformable.
-- @param(t : Transformable)
function SpriteGrid:updateTransform(t)
  local pos = t.position + self.position
  for i = 1, 9 do
    local sprite = self.slices[i].sprite
    sprite:setPosition(pos)
    sprite:setOffset(self.skinData[i].x, self.skinData[i].y)
    sprite:setScale(self.skinData[i].sx * t.scaleX, self.skinData[i].sy * t.scaleY)
  end
end
-- Destroys all slices.
function SpriteGrid:destroy()
  for i = 1, 9 do
    self.slices[i]:destroy()
  end
end
-- Sets each slice visibility.
-- @param(value : boolean) True to show, false to hide.
function SpriteGrid:setVisible(value)
  for i = 1, 9 do
    self.slices[i]:setVisible(value)
  end
end
-- Updates each slice position.
-- @param(pos : Vector) Parent position.
function SpriteGrid:updatePosition(pos)
  pos = pos + self.position
  for i = 1, 9 do
    local sprite = self.slices[i].sprite
    sprite:setPosition(pos)
  end
end

return SpriteGrid