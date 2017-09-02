
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
local List = require('core/datastruct/List')

-- Alias
local floor = math.floor

local Window = class(Transformable)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(GUI : GUI) parent GUI
-- @param(width : number) total width in pixels (if nil, must be set later)
-- @param(height : number) total height in pixels (if nil, must be set later)
-- @param(position : Vector) the position of the center of the window 
--  (optional, center of the screen by default)
function Window:init(GUI, width, height, position)
  Transformable.init(self, position)
  self.speed = 10
  self.spriteGrid = SpriteGrid(self:getSkin(), Vector(0, 0, 1))
  self.GUI = GUI
  self.content = List()
  self:createContent(width, height)
  self:setPosition(position or Vector(0, 0, 0))
  self:setVisible(false)
end
-- Creates all content elements.
-- By default, only creates the skin.
function Window:createContent(width, height)
  self.width = width
  self.height = height
  self.spriteGrid:createGrid(GUIManager.renderer, width, height)
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Updates all content elements.
function Window:update()
  Transformable.update(self)
  self.spriteGrid:update()
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
-- Sets this window as the active one.
function Window:activate()
  self.GUI:setActiveWindow(self)
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
function Window:setXYZ(...)
  Transformable.setXYZ(self, ...)
  self.spriteGrid:updateTransform(self)
  for c in self.content:iterator() do
    if c.updatePosition then
      c:updatePosition(self.position)
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
-- Window's skin.
-- @ret(Image) 
function Window:getSkin()
  return Database.animations[Config.animations.windowSkinID]
end
-- Horizontal padding.
function Window:hPadding()
  return 8
end
-- Vertical padding.
function Window:vpadding()
  return 8
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

---------------------------------------------------------------------------------------------------
-- Content
---------------------------------------------------------------------------------------------------

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
-- Input
---------------------------------------------------------------------------------------------------

-- Checks if player pressed any GUI button.
-- By default, only checks the "cancel" key.
function Window:checkInput()
  if InputManager.keys['cancel']:isTriggered() then
    self:onCancel()
  elseif InputManager.keys['next']:isTriggered() then
    self:onNext()
  elseif InputManager.keys['prev']:isTriggered() then
    self:onPrev()
  end
end
-- Called when player presses "cancel" key.
-- By default, only dets the result to 0.
function Window:onCancel()
  self.result = 0
end
-- Called when player presses "next" key.
function Window:onNext()
end
-- Called when player presses "prev" key.
function Window:onPrev()
end

return Window
