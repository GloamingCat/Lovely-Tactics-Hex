
-- ================================================================================================

--- A Renderer manages a list of sprites to be rendered. 
-- Stores them in order and draws them using a batch.
---------------------------------------------------------------------------------------------------
-- @classmod Renderer

-- ================================================================================================

-- Imports
local List = require('core/datastruct/List')
local Transformable = require('core/math/transform/Transformable')

-- Alias
local lgraphics = love.graphics
local round = math.round
local getShader = love.graphics.getShader
local setShader = love.graphics.setShader

-- Constants
local blankTexture = lgraphics.newImage(love.image.newImageData(1, 1))
local spriteShader = lgraphics.newShader('shaders/Sprite.glsl')

-- Class table.
local Renderer = class(Transformable)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

-- @tparam numbwe width Canvas width in pixels.
-- @tparam numbwe height Canvas height in pixels.
-- @tparam number minDepth Minimum depth of a sprite.
-- @tparam number maxDepth Maximum depth of a sprite.
-- @tparam number batchSize Max number of sprites.
function Renderer:init(minDepth, maxDepth, batchSize)
  Transformable.init(self)
  self.spriteShader = spriteShader
  self.blankTexture = blankTexture
  self.minDepth = minDepth
  self.maxDepth = maxDepth
  self.batchSize = batchSize
  self.spriteList = {}
  self.batch = lgraphics.newSpriteBatch(blankTexture, batchSize, 'dynamic')
  self.canvas = lgraphics.newCanvas(1, 1)
  self.batchHSV = {0, 1, 1}
  self.minx = -math.huge
  self.maxx = math.huge
  self.miny = -math.huge
  self.maxy = math.huge
  self.batchDraws = 0
  self.textDraws = 0
end
--- Resize canvas acording to the zoom.
-- @tparam number newW New width of the canvas in pixels.
-- @tparam number newH New height of the canvas in pixels.
function Renderer:resizeCanvas(newW, newH)
  if newW ~= self.canvas:getWidth() or newH ~= self.canvas:getHeight() then
    assert(newW > 0 and newH > 0, "Renderer canvas dimensions are zero!")
    self.canvas = lgraphics.newCanvas(newW, newH)
    self.needsRedraw = true
  end
  for i = self.minDepth, self.maxDepth do
    local list = self.spriteList[i]
    if list then
      for j = 1, #list do
        list[j]:rescale(self)
      end
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Transformations
-- ------------------------------------------------------------------------------------------------

--- Sets Renderer's center position in the world coordinates.
-- @tparam number x Pixel x.
-- @tparam number y Pixel y.
-- @tparam number z Pixel z.
function Renderer:setXYZ(x, y, z)
  x = round(x or self.position.x)
  y = round(y or self.position.y)
  if self.position.x ~= x or self.position.y ~= y then
    Transformable.setXYZ(self, x, y, 0)
    self.needsRedraw = true
  end
end
--- Sets Renderer's zoom. 1 is normal.
-- @tparam number zoom New zoom.
function Renderer:setZoom(zoom)
  if self.scaleX ~= zoom or self.scaleY ~= zoom then
    self:setScale(zoom, zoom)
    self.needsRedraw = true
  end
end
--- Sets Renderer's rotation.
-- @tparam number angle Rotation in degrees.
function Renderer:setRotation(angle)
  if angle ~= self.rotation then
    self.rotation = angle
    self.needsRedraw = true
  end
end

-- ------------------------------------------------------------------------------------------------
-- Draw
-- ------------------------------------------------------------------------------------------------

--- Draws all sprites in the renderer's table.
function Renderer:draw()
  self.batchDraws = 0
  self.textDraws = 0
  if self.needsRedraw then
    self:redrawCanvas()
  end
  local r, g, b, a = lgraphics.getColor()
  lgraphics.setShader()
  lgraphics.setColor(self:getRGBA())
  if self.spriteShader then
    self.spriteShader:send('phsv', {self:getHSV()})
  end
  lgraphics.draw(self.canvas, 0, 0)
  lgraphics.setColor(r, g, b, a)
end
--- Draws all sprites in the table to the canvas.
function Renderer:redrawCanvas()
  -- Center of the canvas
  self.toDraw = List()
  local ox = round(self.canvas:getWidth() / 2)
  local oy = round(self.canvas:getHeight() / 2)
  local sx = ScreenManager.scaleX * self.scaleX
  local sy = ScreenManager.scaleY * self.scaleY
  local firstCanvas = lgraphics.getCanvas()
  local firstShader = lgraphics.getShader()
  lgraphics.push()
  lgraphics.setCanvas(self.canvas)
  lgraphics.translate(-ox, -oy)
  --lgraphics.scale(sx, sy)
  lgraphics.rotate(self.rotation)
  local tx = -self.position.x + ox * 2 / sx
  local ty = -self.position.y + oy * 2 / sy
  lgraphics.translate(round(tx * sx), round(ty * sy))
  lgraphics.clear()
  lgraphics.setShader(self.spriteShader)
  local w, h = ScreenManager.width * self.scaleX / 2, ScreenManager.height * self.scaleY / 2
  self.minx, self.maxx = self.position.x - w, self.position.x + w
  self.miny, self.maxy = self.position.y - h, self.position.y + h
  self:drawLists()
  self:clearBatch()
  lgraphics.setCanvas(firstCanvas)
  lgraphics.setShader(firstShader)
  lgraphics.pop()
  self.toDraw = nil
  self.needsRedraw = false
end
--- Draw each sprite list, ordered by depth.
function Renderer:drawLists()
  local started = false
  for i = self.maxDepth, self.minDepth, -1 do
    local list = self.spriteList[i]
    if list then
      if not started then
        self.batchTexture = blankTexture
        self.batch:setTexture(blankTexture)
        started = true
      end
      local drawList = List()
      for _, sprite in ipairs(list) do
        if sprite:isVisible() then
          if sprite.needsRecalcBox then
            sprite:recalculateBox()
          end
          if sprite.position.x - sprite.diag < self.maxx and 
              sprite.position.x + sprite.diag > self.minx and
              sprite.position.y - sprite.diag < self.maxy and 
              sprite.position.y + sprite.diag > self.miny then
            drawList:add(sprite)
          end
        end
      end
      self:drawSortedList(drawList)
    end
  end
end
--- Draws all sprites in the same depth, sorting by texture.
-- @tparam Sprite list Table The list of sprites to be drawn.
function Renderer:drawSortedList(list)
  local last = 1
  while last <= list.size do
    list[last]:draw(self)
    for i = last + 1, list.size do
      local sprite = list[i]
      if self:batchPossible(sprite) then
        last = last + 1
        list[i] = list[last]
        list[last] = sprite
        sprite:draw(self)
      end
    end
    last = last + 1
  end
end
-- @treturn number Number of sprites (visible or not).
function Renderer:spriteCount()
  local count = 0
  for i = self.minDepth, self.maxDepth do
    if self.spriteList[i] then
      count = count + #self.spriteList[i]
    end
  end
  return count
end

-- ------------------------------------------------------------------------------------------------
-- Batch
-- ------------------------------------------------------------------------------------------------

--- Draws current and clears.
function Renderer:clearBatch()
  if self.batch and self.toDraw.size > 0 then
    if self.batchHSV[1] == 0 and self.batchHSV[2] == 1 and self.batchHSV[3] == 1 then
      if getShader() == self.spriteShader then
        setShader(nil)
      end
    elseif self.spriteShader then
      if getShader() ~= self.spriteShader then
        setShader(self.spriteShader)
      end
      self.spriteShader:send('phsv', self.batchHSV)
    end
    self.batch:setTexture(self.batchTexture)
    lgraphics.draw(self.batch)
    self.batch:clear()
    self.toDraw.size = 0
    self.batchDraws = self.batchDraws + 1
  end
end
--- Checks if sprite may be added to the current batch.
-- @tparam Sprite sprite
-- @treturn boolean
function Renderer:batchPossible(sprite)
  if sprite.texture ~= self.batchTexture then
    return false
  end
  local hsv1, hsv2 = sprite.hsv, self.batchHSV
  return hsv1.h == hsv2[1] and hsv1.s == hsv2[2] and hsv1.v == hsv2[3]
end

return Renderer
