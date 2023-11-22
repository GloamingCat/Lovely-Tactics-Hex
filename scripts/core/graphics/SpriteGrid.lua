
-- ================================================================================================

--- A group of sprites created from a 9-sliced skin.
-- Each animation frame should contain within itself all 9 slices.
---------------------------------------------------------------------------------------------------
-- @animmod SpriteGrid

-- ================================================================================================

-- Imports
local Sprite = require('core/graphics/Sprite')

-- Alias
local Quad = love.graphics.newQuad
local floor = math.floor
local rotate = math.rotate

-- Class table.
local SpriteGrid = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam table skin Skin's animation data.
function SpriteGrid:init(skin)
  self.skin = skin
end
--- Creates sprites and skinData.
-- @tparam Renderer renderer The renderer of the sprites.
-- @tparam number width The width of the final image.
-- @tparam number height The height of the final image.
function SpriteGrid:createGrid(renderer, width, height)
  local skin = self.skin.quad
  local w = skin.width / 3
  local h = skin.height / 3
  local mw = width - 2 * w
  local mh = height - 2 * h
  if self.skinData then
    self:destroy()
  end
  self.width = width
  self.height = height
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

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Updates each slice animation.
function SpriteGrid:update(dt)
  for i = 1, 9 do
    self.slices[i]:update(dt)
  end
end
--- Destroys all slices.
function SpriteGrid:destroy()
  for i = 1, 9 do
    self.slices[i]:destroy()
  end
end
--- Sets each slice visibility.
-- @tparam boolean value True to show, false to hide.
function SpriteGrid:setVisible(value)
  self.visible = value
  for i = 1, 9 do
    self.slices[i].sprite:setVisible(value)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Transform
-- ------------------------------------------------------------------------------------------------

--- Updates position and scale according to the given parent transformable.
-- @tparam Transformable t
-- @tparam[opt] number offsetDepth
function SpriteGrid:updateTransform(t)
  for i = 1, 9 do
    local sprite = self.slices[i].sprite
    sprite:setXYZ(t.position.x - t.offsetX * t.scaleX, 
                  t.position.y - t.offsetY * t.scaleY,
                  t.position.z + t.offsetDepth)
    sprite:setOffset(self.skinData[i].x, self.skinData[i].y)
    sprite:setScale(self.skinData[i].sx * t.scaleX, self.skinData[i].sy * t.scaleY)
    if t.rotation ~= 0 then
      local x, y, ox, oy, r = Affine.rotateAround(sprite, t.position.x, t.position.y, t.rotation)
      sprite:setXYZ(x, y)
      sprite:setOffset(x, y)
      sprite:setRotation(r)
    end
  end
end
--- Updates each slice position.
-- @tparam Vector pos Parent position.
function SpriteGrid:setXYZ(x, y, z)
  for i = 1, 9 do
    self.slices[i].sprite:setXYZ(x, y, z)
  end
end
--- Sets the RGBA values of each slice.
-- If an argument is nil, the field is left unchanged.
-- @tparam[opt] number r Red component.
-- @tparam[opt] number g Green component.
-- @tparam[opt] number b Blue component.
-- @tparam[opt] number a Blpha component.
function SpriteGrid:setRGBA(r, g, b, a)
  for i = 1, 9 do
    self.slices[i].sprite:setRGBA(r, g, b, a)
  end
end
--- Sets the HSV values of each slice.
-- If an argument is nil, the field is left unchanged.
-- @tparam[opt] number h Hue component.
-- @tparam[opt] number s Saturation component.
-- @tparam[opt] number v Value/brightness component.
function SpriteGrid:setHSV(h, s, v)
  for i = 1, 9 do
    self.slices[i].sprite:setHSV(h, s, v)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Bounds
-- ------------------------------------------------------------------------------------------------

function SpriteGrid:getQuadBox(...)
  return 0, 0, self.width, self.height
end

function SpriteGrid:setQuad(...)
  -- TODO
end

return SpriteGrid
