
--[[===============================================================================================

SpriteGrid
---------------------------------------------------------------------------------------------------
A group of sprites created from a 9-sliced skin.
Each animation frame should contain within itself all 9 slices.

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
-- @param(skin : table) Skin's animation data.
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
  local texture = ResourceManager:loadTexture(skin.path)
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
    self.skinData[i].quad = Quad(skin.x + x, skin.y + y, w, h, texture:getWidth(), texture:getHeight())
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
  for i = 1, 9 do
    local sprite = Sprite(renderer, texture, self.skinData[i].quad)
    self.slices[i] = ResourceManager:loadAnimation(self.skin, sprite)
    sprite:setTransformation(self.skin.transform)
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
-- Sets the RGBA values of each slice.
-- @param(r : number) Red component (optional, current by default).
-- @param(g : number) Green component (optional, current by default).
-- @param(b : number) Blue component (optional, current by default).
-- @param(a : number) Blpha component (optional, current by default).
function SpriteGrid:setRGBA(r, g, b, a)
  for i = 1, 9 do
    self.slices[i].sprite:setRGBA(r, g, b, a)
  end
end
-- Sets the HSV values of each slice.
-- @param(h : number) Hue component (optional, current by default).
-- @param(s : number) Saturation component (optional, current by default).
-- @param(v : number) Value/brightness component (optional, current by default).
function SpriteGrid:setHSV(h, s, v)
  for i = 1, 9 do
    self.slices[i].sprite:setHSV(h, s, v)
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
  self.visible = value
  for i = 1, 9 do
    self.slices[i]:setVisible(value)
  end
end
-- Makes visible.
function SpriteGrid:show()
  self:setVisible(true)
end
-- Makes invisible.
function SpriteGrid:hide()
  self:setVisible(false)
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
