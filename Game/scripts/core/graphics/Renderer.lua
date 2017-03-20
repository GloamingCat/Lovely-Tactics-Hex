
local List = require('core/algorithm/List')
local lgraphics = love.graphics
local blankTexture = lgraphics.newImage(love.image.newImageData(1, 1))
--local spriteShader = lgraphics.newShader('shaders/sprite.glsl')
--local canvasShader = lgraphics.newShader('shaders/canvas.glsl')
local round = math.round
local colorf = 255 / 100

--[[===========================================================================

A Renderer manages a list of sprites to be rendered. 
Stores them in order and draws them using a batch.

=============================================================================]]

local Renderer = require('core/class'):new()

-- @param(size : number) the max number of sprites.
-- @param(minDepth : number) the minimun depth of a sprite
-- @param(maxDepth : number) the maximum depth of a sprite
function Renderer:init(size, minDepth, maxDepth)
  self.minDepth = minDepth
  self.maxDepth = maxDepth
  self.size = size
  self.list = {}
  self.x = 0
  self.y = 0
  self.zoom = 1
  self.rotation = 0
  self.batch = lgraphics.newSpriteBatch(blankTexture, size, 'dynamic')
  self.canvas = lgraphics.newCanvas(1, 1)
  self:resizeCanvas()
end

-- Resize canvas acording to the zoom.
function Renderer:resizeCanvas()
  local newW = ScreenManager.scaleX * ScreenManager.width * self.zoom
  local newH = ScreenManager.scaleY * ScreenManager.height * self.zoom
  if newW ~= self.canvas:getWidth() and newH ~= self.canvas:getHeight() then
    self.canvas = lgraphics.newCanvas(newW, newH)
    self.needsRedraw = true
  end
end

-- Sets Renderer's center position in the world coordinates.
-- @param(x : number) pixel x
-- @param(y : number) pixel y
function Renderer:setPosition(x, y)
  x = round(x)
  y = round(y)
  if self.x ~= x or self.y ~= y then
    self.needsRedraw = true
  end
  self.x = x
  self.y = y
end

-- Sets Renderer's zoom. 1 is normal.
-- @param(zoom : number) new zoom
function Renderer:setZoom(zoom)
  if zoom < self.zoom then
    self.zoom = zoom
    self:resizeCanvas()
  else
    self.zoom = zoom
  end
end

-- Sets Renderer's rotation.
-- @param(angle : number) rotation in degrees
function Renderer:setRotation(angle)
  if angle ~= self.angle then
    self.angle = angle
    self.needsRedraw = true
  end
end

-- Draws all sprites in the renderer's table.
function Renderer:draw()
  if self.needsRedraw then
    self:redrawCanvas()
  end
  local ox = round(self.canvas:getWidth() / 2)
  local oy = round(self.canvas:getHeight() / 2)
  local x = round(ScreenManager.scaleX * ScreenManager.width / 2)
  local y = round(ScreenManager.scaleY * ScreenManager.height / 2)
  lgraphics.draw(self.canvas, x - ox, y - oy)
end

-- Draws all sprites in the table to the canvas.
function Renderer:redrawCanvas()
  -- Center of the canvas
  self.toDraw = List()
  local ox = math.round(self.canvas:getWidth() / 2)
  local oy = math.round(self.canvas:getHeight() / 2)
  local firstCanvas = lgraphics.getCanvas()
  lgraphics.push()
  lgraphics.setCanvas(self.canvas)
  lgraphics.translate(-ox, -oy)
  lgraphics.scale(ScreenManager.scaleX * self.zoom, ScreenManager.scaleY * self.zoom)
  lgraphics.rotate(self.rotation)
  lgraphics.translate(-self.x + ox, -self.y + oy)
  lgraphics.clear()
  local drawCalls = 0
  local started = false
  for i = self.maxDepth, self.minDepth, -1 do
    local list = self.list[i]
    if list then
      if not started then
        self.batch:setTexture(blankTexture)
        started = true
      end
      self:drawList(list, toDraw)
    end
  end
  self:clearBatch()
  lgraphics.setCanvas(firstCanvas)
  lgraphics.pop()
  self.toDraw = nil
  self.needsRedraw = false
end

-- Draws all sprites in the same depth.
-- @param(list : Sprite Table) the list of sprites to be drawn
function Renderer:drawList(list)
  local n = #list
  for i = 1, n do
    local sprite = list[i]
    if sprite:isVisible() then
      if sprite.texture ~= self.batch:getTexture() then
        self:changeTexture(sprite)
      end
      if sprite.texture ~= nil then
        if sprite.isText then
          self:clearBatch()
          self:writeText(sprite)
        else
          self:addSprite(sprite)
        end
      end
    end
  end
end

-- Draws current batch and sets new texture.
-- @param(texture : Texture) the new texture
function Renderer:changeTexture(sprite)
  if sprite.texture == nil then
    if sprite.text ~= nil then
      self:clearBatch()
      self:writeText(sprite)
    end
  else
    self:clearBatch()
    self.batch:setTexture(sprite.texture)
  end
end

-- Draws current and clears.
function Renderer:clearBatch()
  if self.batch then
    -- TODO: attach mesh from sprites in the toDraw list
    love.graphics.draw(self.batch)
    self.batch:clear()
    self.toDraw.size = 0
  end
end

-- Inserts sprite to the batch.
-- @param(sprite : Sprite) sprite to be added
function Renderer:addSprite(sprite)
  self.batch:setColor(sprite.color.red * colorf, sprite.color.green * colorf, 
    sprite.color.blue * colorf, sprite.color.alpha * colorf)
  self.batch:add(sprite.quad, sprite.position.x, sprite.position.y, 
    sprite.rotation, sprite.scaleX, sprite.scaleY, sprite.offsetX, sprite.offsetY)
  self.toDraw:add(sprite)
end

-- Draws a text.
-- @param(sprite : Sprite) sprite containing the text
function Renderer:writeText(sprite)
  lgraphics.setColor(sprite.color.red * colorf, sprite.color.green * colorf, 
    sprite.color.blue * colorf, sprite.color.alpha * colorf)
  sprite:draw()
  lgraphics.setColor(255, 255, 255, 255)
end

-- Organizes current sprite list by texture.
-- @param(list : Sprite Table) list of sprites to be sorted
function Renderer:sortList(list)
  local texture = self.batch:getTexture()
  local n = #list
  local l = 1
  local r = n
  repeat
    while l < r do
      while list[r].texture ~= texture and l < r do
        r = r - 1
      end
      while list[l].texture == texture and l < r do
        l = l + 1
      end
      if l <= r then
        list[l], list[r] = list[r], list[l]
        r = r - 1
        l = l + 1
      end
    end
    if l < r then
      texture = list[l].texture
      r = n
    end
  until l >= r
end

return Renderer
