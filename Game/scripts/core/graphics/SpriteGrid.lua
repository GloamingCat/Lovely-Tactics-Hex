
--[[===============================================================================================

SpriteGrid
---------------------------------------------------------------------------------------------------
A group of sprites created from a 9-sliced skin.

=================================================================================================]]

-- Imports
local Sprite = require('core/graphics/Sprite')

-- Alias
local Quad = love.graphics.newQuad
local floor = math.floor

local SpriteGrid = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(skin : Image) the image to be 9-sliced
function SpriteGrid:init(skin)
  self.skin = skin
end
-- Creates sprites and skinData.
-- @param(renderer : Renderer) the renderer of the sprites
-- @param(width : number) the width of the final image
-- @param(height : number) the height of the final image
function SpriteGrid:createGrid(renderer, width, height)
  local w = floor(self.skin:getWidth() / 3)
  local h = floor(self.skin:getHeight() / 3)
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
    self.skinData[i].quad = Quad(x, y, w, h, self.skin:getWidth(), self.skin:getHeight())
    self.skinData[i].sx = sx / w
    self.skinData[i].sy = sy / h
    self.skinData[i].x = ox / self.skinData[i].sx 
    self.skinData[i].y = oy / self.skinData[i].sy
  end
  if self.sprites then
    for i = 1, 9 do
      self.sprites[i]:dispose()
    end
  end
  self.sprites = {}
  for i = 1, 9 do
    self.sprites[i] = Sprite(renderer, self.skin, self.skinData[i].quad)
  end
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Updates position and scale according to the given parent transformable.
-- @param(t : Transformable)
function SpriteGrid:updateTransform(t)
  for i = 1, 9 do
    self.sprites[i]:setPosition(t.position)
    self.sprites[i]:setOffset(self.skinData[i].x, self.skinData[i].y)
    self.sprites[i]:setScale(self.skinData[i].sx * t.scaleX, self.skinData[i].sy * t.scaleY)
  end
end
-- Destroys all sprites.
function SpriteGrid:destroy()
  for i = 1, 9 do
    self.sprites[i]:destroy()
  end
end

return SpriteGrid
