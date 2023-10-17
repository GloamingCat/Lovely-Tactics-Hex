
-- ================================================================================================

--- Stores info about screen's transformation (translation and scale).
--
-- Scaling types:
--  * 0 -> cannot scale at all.
--  * 1 -> scale only by integer scalars.
--  * 2 -> scale by real scalars, but do not change width:height ratio.
--  * 3 -> scale freely.
-- ------------------------------------------------------------------------------------------------
-- @classmod ScreenManager

-- ================================================================================================

-- Alias
local lgraphics = love.graphics
local floor = math.floor
local round = math.round
local min = math.min
local rotate = math.rotate

-- Class table.
local ScreenManager = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
function ScreenManager:init()
  love.graphics.setDefaultFilter("nearest", "nearest")
  self.width = Config.screen.nativeWidth
  self.height = Config.screen.nativeHeight
  self.pixelPerfect = Config.screen.pixelPerfect
  self.canvasFilter = "nearest"
  self.scaleX = 0
  self.scaleY = 0
  self.offsetX = 0
  self.offsetY = 0
  self.canvasScaleX = 1
  self.canvasScaleY = 1
  self.closed = false
  self.mode = nil
  self.drawCalls = 0
  self:clear()
end
--- Creates the canvas, after the screen size is set.
function ScreenManager:initCanvas()
  if not GameManager:isMobile() then
    self.scalingType = Config.screen.scaleType or 1
  else
    self.scalingType = Config.screen.mobileScaleType or 2
  end
  local w = lgraphics.getWidth()
  local h = lgraphics.getHeight()
  self:onResize(w, h)
end

-- ------------------------------------------------------------------------------------------------
-- Draw
-- ------------------------------------------------------------------------------------------------

--- Overrides love draw to count the calls.
local old_draw = love.graphics.draw
function love.graphics.draw(...)
  old_draw(...)
  _G.ScreenManager.drawCalls = _G.ScreenManager.drawCalls + 1
end
--- Draws game canvas.
function ScreenManager:draw()
  self.drawCalls = 0
  lgraphics.setCanvas(self.canvas)
  lgraphics.clear()
  for i = 1, self.rendererCount do
    if self.renderers[i] then
      self.renderers[i]:draw()
    end
  end
  lgraphics.setCanvas()
  lgraphics.setShader(self.shader)
  lgraphics.draw(self.canvas, self.offsetX, self.offsetY, 0, self.canvasScaleX, self.canvasScaleY)
end

-- ------------------------------------------------------------------------------------------------
-- Renderers
-- ------------------------------------------------------------------------------------------------

--- Set a renderer in the given order.
-- @tparam Renderer renderer
-- @tparam number i
function ScreenManager:setRenderer(renderer, i)
  self.renderers[i] = renderer
  self.rendererCount = math.max(self.rendererCount, i)
end
--- Clears renderer list and resets shader.
function ScreenManager:clear()
  self.shader = nil
  self.renderers = {}
  self.rendererCount = 0
end
--- Resizes renderers' canvases.
function ScreenManager:refreshRenderers()
  for i = 1, self.rendererCount do
    if self.renderers[i] then
      self.renderers[i]:resizeCanvas(self.canvas:getWidth(), self.canvas:getHeight())
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Size
-- ------------------------------------------------------------------------------------------------

--- Scales the screen (deforms both field and GUI).
-- @tparam number x The scale factor in axis x.
-- @tparam number y The scale factor in axis y.
-- @treturn boolean True if the canvas size changed.
function ScreenManager:setScale(x, y)
  if self.scalingType == 0 then
    return
  elseif self.scalingType == 1 then
    local m = min(x, y)
    if m > 1 then
      m = floor(m)
    end
    x, y = m, m
  elseif self.scalingType == 2 then
    local m = min(x, y)
    x, y = m, m
  end
  if self.pixelPerfect then
    self.scaleX = math.ceil(x)
    self.scaleY = math.ceil(y)
  else
    self.scaleX = x
    self.scaleY = y
  end
  self.canvasScaleX = x / self.scaleX
  self.canvasScaleY = y / self.scaleY
  self.canvasFilter = x == self.scaleX and y == self.scaleY and "nearest" or "linear"
  local newW = self.width * self.scaleX
  local newH = self.height * self.scaleY
  if self.canvas and newW == self.canvas:getWidth() and newH == self.canvas:getHeight() then
    self.canvas:setFilter(self.canvasFilter, self.canvasFilter)
    return false
  else
    assert(newW > 0 and newH > 0, "Screen canvas dimensions are zero!")
    self.canvas = lgraphics.newCanvas(newW, newH)
    self.canvas:setFilter(self.canvasFilter)
    return true
  end
end
-- @treturn number Width in world size.
function ScreenManager:totalWidth()
  return self.scaleX * self.width * self.canvasScaleX
end
-- @treturn number Height in world size.
function ScreenManager:totalHeight()
  return self.scaleY * self.height * self.canvasScaleY
end

-- ------------------------------------------------------------------------------------------------
-- Coordinates
-- ------------------------------------------------------------------------------------------------

--- Converts a screen point to a world point.
-- @tparam Renderer renderer World's renderer.
-- @tparam number x Screen x.
-- @tparam number y Screen y.
-- @treturn number World x.
-- @treturn number World y.
function ScreenManager:screen2World(renderer, x, y)
  -- Canvas center
  local ox = self.width / 2
  local oy = self.height / 2
  -- Total scale
  local sx = self.scaleX * renderer.scaleX
  local sy = self.scaleY * renderer.scaleY
  -- Screen black border offset
  x = (x - self.offsetX) / self.canvasScaleX
  y = (y - self.offsetY) / self.canvasScaleY
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
--- Converts a world point to a screen point.
-- @tparam Renderer renderer World's renderer.
-- @tparam number x World x.
-- @tparam number y World y.
-- @treturn number Screen x.
-- @treturn number Screen y.
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
  x = x * self.canvasScaleX + self.offsetX
  y = y * self.canvasScaleY + self.offsetY
  return x, y
end

-- ------------------------------------------------------------------------------------------------
-- Window
-- ------------------------------------------------------------------------------------------------

--- Sets window mode (windowed or fullscreen).
-- @tparam number mode 0 is fullscreen, 1+ are scales for window modes.
function ScreenManager:setMode(mode)
  assert(GameManager:isDesktop(), "Mode cannot be set programmatically in this platform.")
  self.mode = mode
  local sx = mode or Config.screen.widthScale / 100
  local sy = mode or Config.screen.heightScale / 100
  if mode == 0 then
    local modes = love.window.getFullscreenModes(1)
    local mode = modes[1]
    sx = mode.width / self.width
    sy = mode.height / self.height
  end
  self:setScale(sx, sy)
  love.window.setMode(self:totalWidth(), self:totalHeight(), {fullscreen = mode == 0})
  local w, h = love.window.getMode()
  self:onResize(w, h)
end
--- Called window is resizes.
-- @tparam number w New window width in pixels.
-- @tparam number h New window height in pixels.
function ScreenManager:onResize(w, h)
  if w > 0 and h > 0 then
    local scaleX = w / self.width
    local scaleY = h / self.height
    self:setScale(scaleX, scaleY)
    self.offsetX = (w - self:totalWidth()) / 2
    self.offsetY = (h - self:totalHeight()) / 2
    ResourceManager:clearFontCache()
    self:refreshRenderers()
  end
end
--- Called when window receives/loses focus.
-- @tparam boolean f True if screen received focus, false if lost.
function ScreenManager:onFocus(f)
  if f then
    ResourceManager:refreshImages()
    for i = 1, self.rendererCount do
      if self.renderers[i] then
        self.renderers[i].needRedraw = true
      end
    end
  end
end
--- Closes game window, but keeps it running.
function ScreenManager:closeWindow()
  if self.closed then
    return
  end
  love.window.close()
  self.closed = true
end
--- Reopens game window if closed.
function ScreenManager:openWindow()
  if not self.closed then
    return
  end
  self.closed = false
  local newW = self.width * self.scaleX
  local newH = self.height * self.scaleY
  love.window.setMode(newW, newH, {fullscreen = self.mode == 0})
end

return ScreenManager
