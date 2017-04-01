
--[[===========================================================================

Window
-------------------------------------------------------------------------------
Provides the base for windows.
Every content element for the window must have all the following methods:
  show
  hide
  updatePosition(pos) (optional)
  update (optional)
  destroy

=============================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')
local List = require('core/algorithm/List')

local Window = require('core/class'):new()

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

-- @param(GUI : GUI) parent GUI
-- @param(width : number) total width in pixels
-- @param(height : number) total height in pixels
-- @param(position : Vector) the position of the center of the window
-- @param(skin : Image) window skin (optional)
function Window:init(GUI, width, height, position, skin)
  self.width = width
  self.height = height
  self.scaleX = 1
  self.scaleY = 1
  self.speed = 5
  self.open = false
  self.closed = true
  self.skin = skin or love.graphics.newImage('images/GUI/windowSkin.png')
  self.paddingw = math.floor(self.skin:getWidth() / 3)
  self.paddingh = math.floor(self.skin:getHeight() / 3)
  self.GUI = GUI
  self.content = List()
  self:createContent()
  self:setPosition(position or Vector(0,0,0))
  self:setVisible(false)
end

-- Updates all content elements.
function Window:update()
  for c in self.content:iterator() do
    if c.update then
      c:update()
    end
  end
end

-- Erases content.
function Window:destroy()
  for i = 1, 9 do
    self.sprites[i]:removeSelf()
  end
  for c in self.content:iterator() do
    c:destroy()
  end
end

-------------------------------------------------------------------------------
-- Properties
-------------------------------------------------------------------------------

-- Sets the window to fully open or fully closed.
-- @param(value : boolean) true to open it, false to hide
function Window:setVisible(value)
  if value then
    self:showContent()
    self:setScale(self.scaleX, 1)
    self.open = true
    self.closed = false
  else
    self:hideContent()
    self:setScale(self.scaleX, 0)
    self.open = false
    self.closed = true
  end
end

-- Sets this window's position.
-- @param(position : Vector) new position
function Window:setPosition(position)
  self.position = position
  self:updateSkinSprites()
  for c in self.content:iterator() do
    if c.updatePosition then
      c:updatePosition(position)
    end
  end
end

-- Scales this window.
-- @param(sx : number) scale in axis x
-- @param(sy : number) scale in axis y
function Window:setScale(sx, sy)
  self.scaleX = sx
  self.scaleY = sy
  self:updateSkinSprites()
end

-------------------------------------------------------------------------------
-- Content
-------------------------------------------------------------------------------

-- Abstract. Creates all content elements.
function Window:createContent()
  self:createSkinData()
end

-- Shows all content elements.
function Window:showContent()
  for c in self.content:iterator() do
    if c.updatePosition then
      c:updatePosition(self.position)
    end
    c:show()
  end
end

-- Hides all content elements.
function Window:hideContent()
  for c in self.content:iterator() do
    c:hide()
  end
end

-------------------------------------------------------------------------------
-- Window skin
-------------------------------------------------------------------------------

-- Create skin sprites.
function Window:createSkinData()
  local Quad = love.graphics.newQuad
  local w = math.floor(self.skin:getWidth() / 3)
  local h = math.floor(self.skin:getHeight() / 3)
  local mw = self.width - 2 * w
  local mh = self.height - 2 * h
  self.skinData = {}
  local x, y, ox, oy, sx, sy
  for i = 1, 9 do
    if i % 3 == 1 then
      x = 0
      sx = w
      ox = self.width / 2
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
      oy = self.height / 2
    elseif i <= 6 then
      y = h
      sy = mh
      oy = mh / 2
    else
      y = h * 2
      sy = h
      oy = -mh / 2
    end
    local quad = Quad(x, y, w, h, self.skin:getWidth(), self.skin:getHeight())
    self.skinData[i] = {}
    self.skinData[i].quad = quad
    self.skinData[i].sx = sx / w
    self.skinData[i].sy = sy / h
    self.skinData[i].x = ox / self.skinData[i].sx 
    self.skinData[i].y = oy / self.skinData[i].sy
  end
  if self.sprites then
    for i = 1, 9 do
      self.sprites[i]:dispose()
    end
  end
  self.sprites = {}
  for i = 1, 9 do
    self.sprites[i] = Sprite(GUIManager.renderer, self.skin, self.skinData[i].quad)
  end
end

-- Rescale and repositionate skin sprites.
function Window:updateSkinSprites()
  for i = 1, 9 do
    self.sprites[i]:setPosition(self.position)
    self.sprites[i]:setOffset(self.skinData[i].x, self.skinData[i].y)
    self.sprites[i]:setScale(self.skinData[i].sx * self.scaleX, self.skinData[i].sy * self.scaleY)
  end
end

-------------------------------------------------------------------------------
-- Show/hide
-------------------------------------------------------------------------------

-- [COROUTINE] Opens this window.
function Window:show(add)
  if self.open then
    return
  end
  self.closed = false
  local time = love.timer.getDelta
  repeat
    coroutine.yield()
    self:setScale(self.scaleX, self.scaleY + time() * self.speed)
  until self.scaleY >= 1
  self:showContent()
  self:setScale(self.scaleX, 1)
  if add then
    self.GUI.windowList:add(self)
  end
  self:setScale(self.scaleX, 1)
  self.open = true
end

-- [COROUTINE] Closes this window.
function Window:hide(remove)
  if self.closed then
    return
  end
  self.open = false
  local time = love.timer.getDelta
  self:hideContent()
  repeat
    coroutine.yield()
    self:setScale(self.scaleX, self.scaleY - time() * self.speed)
  until self.scaleY <= 0
  self:setScale(self.scaleX, 0)
  if remove then
    self.GUI.windowList:removeElement(self)
  end
  self:setScale(self.scaleX, 0)
  self.closed = true
end

return Window
