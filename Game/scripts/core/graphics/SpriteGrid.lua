
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
-- @param(skin : Image) the image to be 9-sliced
function SpriteGrid:init(skin, relativePos)
  self.skin = skin
  self.position = relativePos or Vector(0, 0)
end
-- Creates sprites and skinData.
-- @param(renderer : Renderer) the renderer of the sprites
-- @param(width : number) the width of the final image
-- @param(height : number) the height of the final image
function SpriteGrid:createGrid(renderer, width, height)
  local w = floor(self.skin.width / 3)
  local h = floor(self.skin.height / 3)
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
    self.skinData[i].quad = Quad(self.skin.x + x, self.skin.y + y, w, h, self.skin.width, self.skin.height)
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
  local texture = ResourceManager:loadTexture(self.skin.path)
  for i = 1, 9 do
    local sprite = Sprite(renderer, texture, self.skinData[i].quad)
    self.slices[i] = ResourceManager:loadAnimation(self.skin, sprite)
  end
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

function SpriteGrid:update()
  for i = 1, 9 do
    self.slices[i]:update()
  end
end
-- Updates position and scale according to the given parent transformable.
-- @param(t : Transformable)
function SpriteGrid:updateTransform(t)
  for i = 1, 9 do
    local sprite = self.slices[i].sprite
    sprite:setPosition(t.position + self.position)
    sprite:setOffset(self.skinData[i].x, self.skinData[i].y)
    sprite:setScale(self.skinData[i].sx * t.scaleX, self.skinData[i].sy * t.scaleY)
  end
end
-- Destroys all sprites.
function SpriteGrid:destroy()
  for i = 1, 9 do
    self.slices[i]:destroy()
  end
end

return SpriteGrid
