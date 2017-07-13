
--[[===============================================================================================

ScreenManager
---------------------------------------------------------------------------------------------------
ScreenManager stores info about screen's 
transformation (translation and scale).

Scaling types:
0 => cannot scale at all
1 => scale only by integer scalars
2 => scale by real scalars, but do not change width:height ratio
3 => scale freely

=================================================================================================]]

-- Alias
local lgraphics = love.graphics
local setWindowMode = love.window.setMode
local isFullScreen = love.window.getFullscreen
local round = math.round

-- Constants
local defaultScaleX = Config.screen.widthScale
local defaultScaleY = Config.screen.heightScale

local ScreenManager = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function ScreenManager:init()
  love.graphics.setDefaultFilter("nearest", "nearest")
  self.width = Config.screen.nativeWidth
  self.height = Config.screen.nativeHeight
  self.scalingType = 1
  self.scaleX = defaultScaleX
  self.scaleY = defaultScaleY
  self.offsetX = 0
  self.offsetY = 0
  self.canvas = lgraphics.newCanvas(self.width * self.scaleX, self.height * self.scaleY)
  self.renderers = {}
end

---------------------------------------------------------------------------------------------------
-- Draw
---------------------------------------------------------------------------------------------------

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
  for i = 1, #self.renderers do
    self.renderers[i]:draw()
  end
  lgraphics.setCanvas()
  lgraphics.draw(self.canvas, self.offsetX, self.offsetY)
  --print('Draw calls: ' .. drawCalls)
end

---------------------------------------------------------------------------------------------------
-- Size
---------------------------------------------------------------------------------------------------

-- Scales the screen (deforms both field and GUI).
-- @param(x : number) the scale factor in axis x
-- @param(y : number) the scale factor in axis y
function ScreenManager:setScale(x, y)
  if self.scalingType == 0 then
    return
  elseif self.scalingType == 1 then
    x = round(x)
    y = x
  elseif self.scalingType == 2 then
    y = x
  end
  y = y or x
  self.scaleX = x
  self.scaleY = y
  self.canvas = lgraphics.newCanvas(self.width * x, self.height * y)
  if self.width * x == lgraphics.getWidth() 
      and self.height * y == lgraphics.getHeight() then
    return
  end
  setWindowMode(self.width * x, self.height * y, {fullscreen = false})
  for i = 1, self.renderers.size do
    self.renderers[i]:resizeCanvas()
  end
end
-- Width in world size.
function ScreenManager:totalWidth()
  return self.scaleX * self.width
end
-- Height in world size.
function ScreenManager:totalHeight()
  return self.scaleY * self.height
end

---------------------------------------------------------------------------------------------------
-- Mode
---------------------------------------------------------------------------------------------------

-- Changes screen to window mode.
function ScreenManager:setWindowed()
  if isFullScreen() then
    self:scale(defaultScaleX, defaultScaleY)
  end
end
-- Changes screen to full screen mode.
function ScreenManager:setFullscreen()
  if isFullScreen() then
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
  setWindowMode(mode.width, mode.height, {fullscreen = true})
end

---------------------------------------------------------------------------------------------------
-- Event handlers
---------------------------------------------------------------------------------------------------

-- Callback function triggered when window receives or loses focus.
-- @param(f : boolean) window focus
function love.focus(f)
  local renderers = _G.ScreenManager.renderers
  for i = 1, #renderers do
    renderers[i].paused = not f
  end
end

return ScreenManager
