
local lgraphics = love.graphics

--[[===========================================================================

ScreenManager stores info about screen's 
transformation (translation and scale).

Scaling types:
0 => cannot scale at all
1 => scale only by integer scalars
2 => scale by real scalars, but do not change width:height ratio
3 => scale freely

=============================================================================]]

local ScreenManager = require('core/class'):new()

function ScreenManager:init()
  self.width = love.graphics.getWidth()
  self.height = love.graphics.getHeight()
  self.scalingType = 1
  self.defaultScaleX = 2
  self.defaultScaleY = 2
  self.scaleX = 1
  self.scaleY = 1
  self.offsetX = 0
  self.offsetY = 0
  self.canvas = lgraphics.newCanvas(self.width * self.scaleX, self.height * self.scaleY)
end

-- Overrides love draw to count the calls.
local drawCalls = 0
local old_draw = love.graphics.draw
function love.graphics.draw(...)
  old_draw(...)
  drawCalls = drawCalls + 1
end

-- Draws game canvas.
function ScreenManager:draw()
  drawCalls = 0
  lgraphics.setCanvas(self.canvas)
  lgraphics.clear()
  FieldManager.renderer:draw()
  GUIManager.renderer:draw()
  lgraphics.setCanvas()
  lgraphics.draw(self.canvas, self.offsetX, self.offsetY)
  --print(drawCalls)
end

-- Scales the screen (deforms both field and GUI).
-- @param(x : number) the scale factor in axis x
-- @param(y : number) the scale factor in axis y
function ScreenManager:setScale(x, y)
  if self.scalingType == 0 then
    return
  elseif self.scalingType == 1 then
    x = math.round(x)
    y = x
  elseif self.scalingType == 2 then
    y = x
  end
  y = y or x
  self.scaleX = x
  self.scaleY = y
  self.canvas = love.graphics.newCanvas(self.width * x, self.height * y)
  love.window.setMode(self.width * x, self.height * y, {fullscreen = false})
  FieldManager.renderer:resizeCanvas()
  GUIManager.renderer:resizeCanvas()
end

-- Changes screen to window mode.
function ScreenManager:setWindowed()
  if love.window.getFullscreen() then
    self:scale(self.defaultScaleX, self.defaultScaleY)
  end
end

-- Changes screen to full screen mode.
function ScreenManager:setFullscreen()
  if love.window.getFullscreen() then
    return
  end
  local modes = love.window.getFullscreenModes(1)
  local mode = modes[1]
  local scaleX = mode.width / self.width
  local scaleY = mode.height / self.height
  if self.scalingType == 1 then
    local bestScale = 1
    while bestScale * self.width <= mode.width and bestScale * self.height <= mode.height do
      bestScale = bestScale + 1
    end
    scaleX = bestScale - 1
    scaleY = bestScale - 1
  elseif self.scalingType == 2 then
    scaleX = math.min(scaleX, scaleY)
    scaleY = scaleX
  end
  self:scale(scaleX, scaleY)
  self.offsetX = (mode.width - self.canvas:getWidth()) / 2
  self.offsetY = (mode.height - self.canvas:getHeight()) / 2
  love.window.setMode(mode.width, mode.height, {fullscreen = true})
end

-- Callback function triggered when window receives or loses focus.
-- @param(f : boolean) window focus
function love.focus(f)
  GUIManager.paused = not f
  FieldManager.paused = not f
end

return ScreenManager
