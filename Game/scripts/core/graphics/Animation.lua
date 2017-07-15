
--[[===============================================================================================

Animation
---------------------------------------------------------------------------------------------------
An Animation updates the quad of the associated Sprite, assuming that the texture of the sprite 
is a spritesheet.

=================================================================================================]]

-- Imports
local Sprite = require('core/graphics/Sprite')

local Animation = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(duration : number) the total duration
-- @param(rowCount : number) how many rows the spritesheet has
-- @param(colCount : number) how many columns the spritesheet has
-- @param(quadWidth : number) the width of each quad
-- @param(quadHeight : number) the height of each quad
-- @param(sprite : Sprite) the sprite that this animation if associated to 
--  (optional, but must be set later)
function Animation:init(duration, rowCount, colCount, quadWidth, quadHeight, 
    loop, allRows, sprite)
  self.sprite = sprite
  self.paused = sprite == nin
  -- The duration in frames of each quad of the animation
  self.duration = duration
  -- The size of each quad
  self.quadWidth = quadWidth
  self.quadHeight = quadHeight
  -- Number of rows and collunms of the spritesheet
  self.colCount = colCount
  self.rowCount = rowCount
  -- Current quad indexes col/row in the spritesheet
  self.col = 0
  self.row = 0
  -- Frame count (adapted to the frame rate)
  self.time = 0
  self.loop = loop
  self.allRows = allRows
end
-- Creates a new animation from file data.
-- @param(data : table) the animation data from file
-- @param(renderer : Renderer) the renderer this sprite will be rendered with
-- @param(sprite : Sprite) the sprite this animation is associated to (optional)
-- @ret(Animation) the new animation
-- @ret(Texture) the new texture
-- @ret(Quad) the new quad
function Animation.fromData(data, renderer, sprite)
  local texture = love.graphics.newImage('images/' .. data.imagePath)
  local w, h = texture:getWidth(), texture:getHeight()
  local quad = love.graphics.newQuad(0, 0, w / data.cols, h / data.rows, w, h)
  if not sprite then
    sprite = Sprite(renderer, texture, quad)
  end
  local AnimClass = Animation
  if data.script.path == '' then
    if data.cols == 1 then
      AnimClass = require('custom/animation/Static')
    end
  else
    AnimClass = require('custom/' .. data.script.path)
  end
  local animation = AnimClass(data.duration, data.rows, data.cols, 
    w / data.cols, h / data.rows, data.loop, data.allRows, sprite, data.script.param)
  return animation, texture, quad
end
-- Creates a 1-quad animation for the given image.
-- @param(texture : Image) the single image
-- @param(renderer : Renderer) the renderer of the sprite
function Animation.fromImage(texture, renderer)
  local w, h = texture:getWidth(), texture:getHeight()
  local quad = love.graphics.newQuad(0, 0, w, h, w, h)
  local sprite = Sprite(renderer, texture, quad)
  local Static = require('custom/animation/Static')
  return Static(1, 1, 1, w, h, false, false, sprite, '')
end

---------------------------------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------------------------------

-- Increments the frame count and automatically changes que sprite.
function Animation:update()
  local lastCol = self.col == self.colCount - 1
  if not self.paused and (self.loop or not lastCol) then
    self.time = self.time + love.timer.getDelta() * 60
    if self.time >= self.duration / self.colCount then
      self.time = self.time - self.duration / self.colCount
      if lastCol and self.allRows then
        self:setCol(0)
        self:setRow(self.row + 1)
      else
        self:setCol(self.col + 1)
      end
    end
  end
end
-- Changes the column of the current quad
-- @param(col : number) the column number, starting from 0
function Animation:setCol(col)
  col = col % self.colCount
  if self.col ~= col then
    local x, y, w, h = self.sprite.quad:getViewport()
    x = x + (col - self.col) * self.quadWidth
    self.col = col
    self.sprite.quad:setViewport(x, y, w, h)
    self.sprite.renderer.needsRedraw = true
  end
end
-- Changes the row of the current quad
-- @param(row : number) the row number, starting from 0
function Animation:setRow(row)
  row = row % self.rowCount
  if self.row ~= row then
    local x, y, w, h = self.sprite.quad:getViewport()
    y = y + (row - self.row) * self.quadHeight
    self.row = row
    self.sprite.quad:setViewport(x, y, w, h)
    self.sprite.renderer.needsRedraw = true
  end
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Destroy this animation.
function Animation:destroy()
  if self.sprite then
    self.sprite:destroy()
  end
end

return Animation
