
--[[===============================================================================================

Window
---------------------------------------------------------------------------------------------------
Provides the base for windows.
Every content element for the window must have all the following methods:
  show
  hide
  updatePosition(pos) (optional)
  update (optional)
  destroy

=================================================================================================]]

-- Imports
local Transformable = require('core/transform/Transformable')
local Vector = require('core/math/Vector')
local SpriteGrid = require('core/graphics/SpriteGrid')
local List = require('core/algorithm/List')

-- Alias
local floor = math.floor

-- Constants
local defaultSkin = love.graphics.newImage('images/GUI/windowSkin.png')

local Window = class(Transformable)

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- @param(GUI : GUI) parent GUI
-- @param(width : number) total width in pixels (if nil, must be set later)
-- @param(height : number) total height in pixels (if nil, must be set later)
-- @param(position : Vector) the position of the center of the window 
--  (optional, center of the screen by default)
-- @param(skin : Image) window skin (optional)
function Window:init(GUI, width, height, position, skin)
  Transformable.init(self, position)
  skin = skin or defaultSkin
  self.speed = 10
  self.width = width
  self.height = height
  self.spriteGrid = SpriteGrid(skin)
  self.paddingw = floor(skin:getWidth() / 3)
  self.paddingh = floor(skin:getHeight() / 3)
  self.GUI = GUI
  self.content = List()
  self:createContent()
  self:setPosition(position or Vector(0,0,0))
  self:setVisible(false)
end
-- Updates all content elements.
function Window:update()
  Transformable.update(self)
  for c in self.content:iterator() do
    if c.update then
      c:update()
    end
  end
end
-- Erases content.
function Window:destroy()
  self.spriteGrid:destroy()
  for c in self.content:iterator() do
    c:destroy()
  end
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

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
  Transformable.setPosition(self, position)
  self.spriteGrid:updateTransform(self)
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
  Transformable.setScale(self, sx, sy)
  self.spriteGrid:updateTransform(self)
end

---------------------------------------------------------------------------------------------------
-- Content
---------------------------------------------------------------------------------------------------

-- Creates all content elements.
-- By default, only creates the skin.
function Window:createContent()
  self.spriteGrid:createGrid(GUIManager.renderer, self.width, self.height)
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

---------------------------------------------------------------------------------------------------
-- Show/hide
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Opens this window.
function Window:show()
  if self.scaleY >= 1 then
    return
  end
  self.closed = false
  self:scaleTo(self.scaleX, 1, self.speed, true)
  if self.scaleY >= 1 then
    self.open = true
    self:showContent()
  end
end
-- [COROUTINE] Closes this window.
function Window:hide()
  if self.scaleY <= 0 then
    return
  end
  self.open = false
  self:hideContent()
  self:scaleTo(self.scaleX, 0, self.speed, true)
  if self.scaleX >= 1 then
    self.closed = true
  end
end
-- Inserts this window in the GUI's list.
function Window:insertSelf()
  if not self.GUI.windowList:contains(self) then
    self.GUI.windowList:add(self)
  end
end
-- Removes this window from the GUI's list.
function Window:removeSelf()
  self.GUI.windowList:removeElement(self)
end

return Window
