
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
local isFullScreen = love.window.getFullscreen
local lgraphics = love.graphics
local floor = math.floor
local round = math.round
local rotate = math.rotate

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
  self.scaleX = Config.screen.widthScale / 100
  self.scaleY = Config.screen.heightScale / 100
  self.offsetX = 0
  self.offsetY = 0
  self.canvas = lgraphics.newCanvas(self.width * self.scaleX, self.height * self.scaleY)
  self.renderers = {}
  self.drawCalls = 0
  self.mode = 1
  self.closed = false
end

---------------------------------------------------------------------------------------------------
-- Draw
---------------------------------------------------------------------------------------------------

-- Overrides love draw to count the calls.
local old_draw = love.graphics.draw
function love.graphics.draw(...)
  old_draw(...)
  _G.ScreenManager.drawCalls = _G.ScreenManager.drawCalls + 1
end
-- Draws game canvas.
function ScreenManager:draw()
  self.drawCalls = 0
  lgraphics.setCanvas(self.canvas)
  lgraphics.clear()
  for i = 1, #self.renderers do
    if self.renderers[i] then
      self.renderers[i]:draw()
    end
  end
  lgraphics.setCanvas()
  lgraphics.setShader(self.shader)
  lgraphics.draw(self.canvas, self.offsetX, self.offsetY)
end

---------------------------------------------------------------------------------------------------
-- Size
---------------------------------------------------------------------------------------------------

-- Scales the screen (deforms both field and GUI).
-- @param(x : number) The scale factor in axis x.
-- @param(y : number) The scale factor in axis y.
function ScreenManager:setScale(x, y, fullScreen)
  if self.scalingType == 0 then
    return
  elseif self.scalingType == 1 then
    x = floor(x)
    y = x
  elseif self.scalingType == 2 then
    y = x
  end
  fullScreen = fullScreen or false
  y = y or x
  if x == self.scaleX and y == self.scaleY and fullScreen == isFullScreen() then
    return
  end
  self.scaleX = x
  self.scaleY = y
  self.offsetX = 0
  self.offsetY = 0
  local newW = self.width * x
  local newH = self.height * y
  self.canvas = lgraphics.newCanvas(newW, newH)
  love.window.setMode(newW, newH, {fullscreen = fullScreen})
  for i = 1, #self.renderers do
    if self.renderers[i] then
      self.renderers[i]:resizeCanvas(newW, newH)
    end
  end
end
-- @ret(number) Width in world size.
function ScreenManager:totalWidth()
  return self.scaleX * self.width
end
-- @ret(number) Height in world size.
function ScreenManager:totalHeight()
  return self.scaleY * self.height
end

---------------------------------------------------------------------------------------------------
-- Coordinates
---------------------------------------------------------------------------------------------------

-- Converts a screen point to a world point.
-- @param(x : number) Screen x.
-- @param(y : number) Screen y.
-- @ret(number) World x.
-- @ret(number) World y.
function ScreenManager:screen2World(renderer, x, y)
  -- Canvas center
  local ox = self.width / 2
  local oy = self.height / 2
  -- Total scale
  local sx = self.scaleX * renderer.scaleX
  local sy = self.scaleY * renderer.scaleY
  -- Screen black border offset
  x, y = x - self.offsetX, y - self.offsetY
  -- Set to origin
  x = x + (renderer.position.x - ox) * sx
  y = y + (renderer.position.y - oy) * sy
  -- Revert Transformation
  x, y = x - ox * sx, y - oy * sy
  x, y = rotate(x, y, -renderer.rotation)
  x, y = x / sx, y / sy
  x, y = x + ox, y + oy
  return x, y
end
-- Converts a world point to a screen point.
-- @param(x : number) World x.
-- @param(y : number) World y.
-- @ret(number) Screen x.
-- @ret(number) Screen y.
function ScreenManager:world2Screen(renderer, x, y)
  -- Canvas center
  local ox = self.width / 2
  local oy = self.height / 2
  -- Total scale
  local sx = self.scaleX * renderer.scaleX
  local sy = self.scaleY * renderer.scaleY
  -- Apply Transformation
  x, y = x - ox, y - oy
  x, y = x * sx, y * sy
  x, y = rotate(x, y, renderer.rotation)
  x, y = x + ox * sx, y + oy * sy
  -- Set to position
  x = x - (renderer.position.x - ox) * sx
  y = y - (renderer.position.y - oy) * sy
  -- Screen black border offset
  x, y = x + self.offsetX, y + self.offsetY
  return x, y
end

---------------------------------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------------------------------

-- Sets window mode (windowd or fullscreen).
-- @param(mode : number) 1, 2, 3 are window modes, 4 is fullscreen.
function ScreenManager:setMode(mode)
  if mode == 4 then
    self:setFullScreen()
  else
    self:setScale(mode, mode)
  end
  self.mode = mode
end
-- Changes screen to window mode.
function ScreenManager:setWindowed()
  if isFullScreen() then
    self:setScale(Config.screen.widthScale / 100, Config.screen.heightScale / 100)
  end
end
-- Changes screen to full screen mode.
function ScreenManager:setFullScreen()
  if isFullScreen() then
    return
  end
  local modes = love.window.getFullscreenModes(1)
  local mode = modes[1]
  local scaleX = mode.width / self.width
  local scaleY = mode.height / self.height
  if self.scalingType == 1 or self.scalingType == 2 then
    scaleX = math.min(scaleX, scaleY)
    scaleY = scaleX
  end
  self:setScale(scaleX, scaleY, true)
  self.offsetX = round((mode.width - self.canvas:getWidth()) / 2)
  self.offsetY = round((mode.height - self.canvas:getHeight()) / 2)
end
-- Called when window receives/loses focus.
-- @param(f : boolean) True if screen received focus, false if lost.
function ScreenManager:onFocus(f)
  if f then
    ResourceManager:refreshImages()
    local renderers = _G.ScreenManager.renderers
    for i = 1, #renderers do
      if renderers[i] then
        renderers[i].needRedraw = true
      end
    end
  end
end
-- Called window is resizes.
-- @param(w : number) New window width.
-- @param(h : number) New window height.
function ScreenManager:onResize(w, h)
  self.offsetX = (w - self.width * self.scaleX) / 2
  self.offsetY = (h - self.height * self.scaleY) / 2
end
-- Closes game window, but keeps it running.
function ScreenManager:closeWindow()
  if self.closed then
    return
  end
  love.window.close()
  self.closed = true
end
-- Reopens game window if closed.
function ScreenManager:openWindow()
  if not self.closed then
    return
  end
  self.closed = false
  local newW = self.width * self.scaleX
  local newH = self.height * self.scaleY
  love.window.setMode(newW, newH, {fullscreen = self.mode == 4})
end

return ScreenManager
