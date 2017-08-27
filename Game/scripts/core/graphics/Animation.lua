
--[[===============================================================================================

Animation
---------------------------------------------------------------------------------------------------
An Animation updates the quad of the associated Sprite, assuming that the texture of the sprite 
is a spritesheet.

=================================================================================================]]

-- Imports
local Sprite = require('core/graphics/Sprite')

-- Alias
local abs = math.abs
local mod = math.mod
local sign = math.sign
local deltaTime = love.timer.getDelta
local Image = love.graphics.newImage
local Quad = love.graphics.newQuad

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
    loop, allRows, sprite, param)
  self.sprite = sprite
  self.paused = sprite == nil
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
  -- Loop type
  if loop then
    self.loop = 1
  else
    self.loop = 0
  end
  self.allRows = allRows
  -- Duration
  self.duration = duration
  if self.allRows then
    self.frameDuration = duration / (rowCount * colCount)
  else
    self.frameDuration = duration / colCount
  end
  self.speed = 1
  self.param = param
end
-- Creates a new animation from file data.
-- @param(data : table) the animation data from file
-- @param(renderer : Renderer) the renderer this sprite will be rendered with
-- @param(sprite : Sprite) the sprite this animation is associated to (optional)
-- @ret(Animation) the new animation
-- @ret(Texture) the new texture
-- @ret(Quad) the new quad
function Animation.fromData(data, renderer, sprite, ...)
  local texture = Image('images/' .. data.imagePath)
  local w, h = texture:getWidth(), texture:getHeight()
  local quad = Quad(0, 0, w / data.cols, h / data.rows, w, h)
  local transform = nil
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
    w / data.cols, h / data.rows, data.loop, data.allRows, sprite, data.script.param, ...)
  return animation, texture, quad
end
-- Creates a 1-quad animation for the given image.
-- @param(texture : Image) the single image
-- @param(renderer : Renderer) the renderer of the sprite
-- @ret(Animation)
function Animation.fromImage(texture, renderer)
  local w, h = texture:getWidth(), texture:getHeight()
  local quad = Quad(0, 0, w, h, w, h)
  local sprite = Sprite(renderer, texture, quad)
  local Static = require('custom/animation/Static')
  return Static(1, 1, 1, w, h, false, false, sprite, '')
end
-- Creates a 1-quad animation for the given quad.
-- @param(quadData : table) the quad from database, with bounds and image path
-- @param(renderer : Renderer) the renderer of the sprite
-- @ret(Animation)
function Animation.fromQuad(quadData, renderer)
  local texture = Image('images/' .. quadData.imagePath)
  local quad = Quad(quadData.x, quadData.y, quadData.width, quadData.height, 
    texture:getWidth(), texture:getHeight())
  local sprite = Sprite(renderer, texture, quad)
  local Static = require('custom/animation/Static')
  return Static(1, 1, 1, quadData.width, quadData.height, false, false, sprite, '')
end
-- Creates a clone of this animation.
-- @param(sprite : Sprite) the sprite of the animation, if cloned too (optional)
-- @ret(Animation)
function Animation:clone(sprite)
  local anim = Animation(self.duration, self.rowCount, self.colCount, self.quadWidth, 
    self.quadHeight, self.loop, self.allRows, sprite or self.sprite, self.param)
  anim.col = self.col
  anim.row = self.row
  anim.paused = self.paused
  anim.time = self.time
  return anim
end

---------------------------------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------------------------------

-- Increments the frame count and automatically changes que sprite.
function Animation:update()
  if self.paused then
    return
  end
  self.time = self.time + deltaTime() * 60 * abs(self.speed)
  if self.time >= self.frameDuration then
    self.time = self.time - self.frameDuration
    self:nextFrame()
  end
end
-- Sets to next frame.
function Animation:nextFrame()
  local lastCol, lastRow = 0, 0
  if self.speed > 0 then
    lastCol, lastRow = self.colCount - 1, self.rowCount - 1
  end
  if self.allRows then
    lastRow = self.row
  end
  if self.col ~= lastCol then
    self:nextCol()
  elseif self.row ~= lastRow and self.allRows then
    self:nextRow()
  else
    self:onEnd()
  end
end
-- What happens when the animations finishes.
function Animation:onEnd()
  if self.loop == 0 then
    self.paused = true
  elseif self.loop == 1 then
    self:nextCol()
    if self.allRows then
      self:nextRow()
    end
  elseif self.loop == 2 then
    self.speed = -self.speed
    if self.colCount > 1 then
      self:nextCol()
    else
      self:nextRow()
    end
  end
end
-- Sets to the next column.
function Animation:nextCol()
  self:setCol(self.col + sign(self.speed))
end
-- Sets to the next row.
function Animation:nextRow()
  self:setRow(self.row + sign(self.speed))
end
-- Changes the column of the current quad
-- @param(col : number) the column number, starting from 0
function Animation:setCol(col)
  col = mod(col, self.colCount)
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
  row = mod(row, self.rowCount)
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

function Animation:reset()
  self.time = 0
  self:setCol(0)
  self:setRow(0)
end
-- Destroy this animation.
function Animation:destroy()
  if self.sprite then
    self.sprite:destroy()
  end
end
-- Sets this animation as visible.
function Animation:show()
  self.sprite:setVisible(true)
end
-- Sets this animation as invisible.
function Animation:hide()
  self.sprite:setVisible(false)
end

return Animation
