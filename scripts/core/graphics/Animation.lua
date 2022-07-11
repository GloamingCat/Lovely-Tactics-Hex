
--[[===============================================================================================

Animation
---------------------------------------------------------------------------------------------------
An Animation updates the quad of the associated Sprite, assuming that the texture of the sprite 
is a spritesheet.

=================================================================================================]]

-- Imports
local Sprite = require('core/graphics/Sprite')

-- Alias
local mod = math.mod
local mod1 = math.mod1
local Quad = love.graphics.newQuad

local Animation = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(sprite : Sprite) The sprite that this animation if associated to.
function Animation:init(sprite, data)
  self.sprite = sprite
  self.data = data
  -- Current quad indexes col/row in the spritesheet
  self.col = 0
  self.row = 0
  self.index = 1
  self.time = 0
  self.speed = 1
  self.loop = false
  if data then
    -- The size of each quad
    self.quadWidth = data.quad.width / data.cols
    self.quadHeight = data.quad.height / data.rows
    -- Number of rows and colunms of the spritesheet
    self.colCount = data.cols
    self.rowCount = data.rows
    -- Pattern
    self:initPattern(data)
    -- Audio
    if data.audio and #data.audio > 0 then
      self.audio = data.audio
      self:playAudio()
    end
    -- Tags
    if data.tags and #data.tags > 0 then
      self.tags = Database.loadTags(data.tags)
    end
    self.paused = sprite == nil
  else
    if sprite and sprite.texture then
      self.quadWidth = sprite.texture:getWidth()
      self.quadHeight = sprite.texture:getHeight()
    end
    self.colCount = 1
    self.rowCount = 1
    self.duration = 0
    self.timing = nil
    self.paused = true
  end
end
-- Creates a clone of this animation.
-- @param(sprite : Sprite) The sprite of the animation, if cloned too (optional).
-- @ret(Animation) Clone of the given animation.
function Animation:clone(sprite)
  local anim = self(sprite or self.sprite, self.data)
  anim.col = self.col
  anim.row = self.row
  anim.index = self.index
  anim.paused = self.paused
  anim.time = self.time
  anim.speed = self.speed
  anim.loop = self.loop
  anim.timing = self.timing
  anim.pattern = self.pattern
  anim.duration = self.duration
  return anim
end
-- Initializes frame pattern and timing.
-- @param(data : table) Animation data.
function Animation:initPattern(data)
  -- Pattern
  self.introPattern = Database.loadPattern(data.introPattern, self.colCount)
  self.loopPattern = Database.loadPattern(data.loopPattern, self.colCount)
  -- Duration
  local introCount = self.introPattern and #self.introPattern or self.colCount
  local loopCount = self.loopPattern and #self.loopPattern or self.colCount
  self.introDuration = Database.loadDuration(data.introDuration, introCount)
  self.loopDuration = Database.loadDuration(data.loopDuration, loopCount)
  if self.introDuration then
    self:setFrames(self.introDuration, self.introPattern)
  elseif self.loopDuration then
    self:setFrames(self.loopDuration, self.loopPattern)
    self.loop = true
  else
    self.duration = 0
  end
end
-- Sets the time for each frame. 
-- @param(timing : table) Array of frame times, one element per frame.
-- @param(pattern : table) Array of frame columns, one element por frame.
function Animation:setFrames(timing, pattern)
  if not timing or #timing == 0 then
    self.timing = nil
    self.duration = 0
  else
    self.timing = timing
    self.duration = 0
    local indexCount = pattern and #pattern or self.colCount
    for i = 1, indexCount do
      assert(timing[i], 'Frame time of ' .. tostring(self) .. ' not defined: ' .. i)
      self.duration = self.duration + timing[i]
    end
  end
  self.pattern = pattern
end

---------------------------------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------------------------------

-- Increments the frame count and automatically changes que sprite.
function Animation:update()
  if self.paused or not self.duration or not self.timing then
    return
  end
  self.time = self.time + GameManager:frameTime() * 60 * self.speed
  if self.time >= self.timing[self.index] then
    self.time = self.time - self.timing[self.index]
    self:nextFrame()
  end
end
-- Sets to next frame.
function Animation:nextFrame()
  local lastIndex = self.pattern and #self.pattern or self.colCount
  if self.index < lastIndex then
    self:nextCol()
    self:playAudio()
  else
    self:onEnd()
  end
end
-- What happens when the animations finishes.
function Animation:onEnd()
  if self.loop then
    self:nextCol()
  elseif self.loopDuration then
    self.loop = true
    self:setFrames(self.loopDuration, self.loopPattern)
    self.index = 0
    self:nextCol()
  else
    self.paused = true
  end
end
-- Sets to the next column.
function Animation:nextCol()
  self:setIndex(self.index + 1)
end
-- Sets to the next row.
function Animation:nextRow()
  self:setRow(self.row + 1)
end
-- Sets the frame counter.
-- @param(i : number) Number of the frame, from 1 to #pattern.
function Animation:setIndex(i)
  if self.pattern then
    self.index = mod1(i, #self.pattern)
    self:setCol(self.pattern[self.index])
  else
    self.index = mod1(i, self.colCount)
    self:setCol(self.index - 1)
  end
end
-- Plays the audio in the current index, if any.
function Animation:playAudio()
  if self.audio then
    for i = 1, #self.audio do
      local audio = self.audio[i]
      if audio.time == self.index - 1 then
        AudioManager:playSFX(audio)
      end
    end
  end
end
-- Changes the column of the current quad
-- @param(col : number) The column number, starting from 0.
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
-- @param(row : number) The row number, starting from 0.
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

-- Sets animation to its starting point.
function Animation:reset()
  self.time = 0
  self.loop = false
  if self.introDuration then
    self:setFrames(self.introDuration, self.introPattern)
  elseif self.loopDuration then
    self:setFrames(self.loopDuration, self.loopPattern)
    self.loop = true
  end
  self:setIndex(1)
end
-- Destroy this animation.
function Animation:destroy()
  if self.sprite then
    self.sprite:destroy()
  end
end
-- String representation.
-- @ret(string)
function Animation:__tostring()
  local id = ''
  if self.data then
    id = ' (' .. self.data.id .. ')'
  end
  return 'Animation' .. id
end

---------------------------------------------------------------------------------------------------
-- Visibility
---------------------------------------------------------------------------------------------------

-- Sets the sprite's visibility.
-- @param(value : boolean)
function Animation:setVisible(value)
  self.sprite:setVisible(value)
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
