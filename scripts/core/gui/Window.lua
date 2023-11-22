
-- ================================================================================================

--- Provides the base for windows.
-- Every content element for the window must inherit from `Component`.
---------------------------------------------------------------------------------------------------
-- @windowmod Window
-- @extend Component
-- @extend Transformable

-- ================================================================================================

-- Imports
local Component = require('core/gui/Component')
local List = require('core/datastruct/List')
local SpriteGrid = require('core/graphics/SpriteGrid')
local Transformable = require('core/math/transform/Transformable')
local Vector = require('core/math/Vector')

-- Alias
local floor = math.floor

-- Class table.
local Window = class(Component, Transformable)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Menu menu Parent Menu.
-- @tparam[opt] number width Total width in pixels. If nil, must be set later.
-- @tparam[opt] number height Total height in pixels. If nil, must be set later.
-- @tparam[opt] Vector position The position of the center of the window.
--  If nil, sets as tha center of the screen.
function Window:init(menu, width, height, position)
  Transformable.init(self, position)
  self.menu = menu
  self:setProperties()
  if not self.noSkin then
    self.background = SpriteGrid(self:getBG())
    self.frame = SpriteGrid(self:getFrame())
  end
  self.width = width
  self.height = height
  self.active = false
  self:insertSelf()
  Component.init(self, position, width, height)
  self:setPosition(position or self.position)
  self:setVisible(false)
  self.lastOpen = true
end
--- Sets general properties.
function Window:setProperties()
  self.offsetDepth = 3
  self.noSkin = false
  self.maxTouchHoldTime = 1
  self.speed = 10
  self.offBoundsCancel = true
end
--- Overrides `Component:createContent`. By default, only creates the skin.
-- @override
function Window:createContent(width, height)
  self.width = width
  self.height = height
  if self.background then
    self.background:createGrid(MenuManager.renderer, width, height)
    self.background:setHSV(nil, nil, MenuManager.windowColor / 100)
  end
  if self.frame then
    self.frame:createGrid(MenuManager.renderer, width, height)
  end
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Updates all content elements.
function Window:update(dt)
  Transformable.update(self, dt)
  if self.background then
    self.background:update(dt)
  end
  if self.frame then
    self.frame:update(dt)
  end
  Component.update(self, dt)
end
--- Updates all content element's position.
function Window:updatePosition()
  if self.background then
    self.background:updateTransform(self)
    self.background:setXYZ(nil, nil, self.position.z + 1)
  end
  if self.frame then
    self.frame:updateTransform(self)
    self.frame:setXYZ(nil, nil, self.position.z + 1)
  end
  Component.updatePosition(self)
end
--- Overrides `Component:refresh`. Refreshes the background color.
-- @override
function Window:refresh()
  Component.refresh(self)
  if self.background then
    self.background:setHSV(nil, nil, MenuManager.windowColor / 100)
  end
end
--- Erases content.
function Window:destroy()
  if self.background then
    self.background:destroy()
  end
  if self.frame then
    self.frame:destroy()
  end
  Component.destroy(self)
end
--- Sets this window as the active one.
function Window:activate()
  self.menu:setActiveWindow(self)
end
--- Deactivate this window if it's the current active one.
function Window:deactivate()
  if self.menu.activeWindow == self then
    self.menu:setActiveWindow(nil)
  end
end
--- Activates/deactivates window.
-- @tparam boolean value True to activate, false to deactivate.
function Window:setActive(value)
  self.active = value
end
--- Checks in a screen point is within window's bounds.
-- @tparam number x Pixel x of point.
-- @tparam number y Pixel y of point.
-- @treturn boolean Whether the given point is inside window.
function Window:isInside(x, y)
  local w = self.width / 2
  local h = self.height / 2
  return x >= -w and x <= w and y >= -h and y <= h
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Sets the window to fully open or fully closed.
-- @tparam boolean value True to open it, false to hide.
function Window:setVisible(value)
  if value then
    self:showContent()
    self:setScale(nil, 1)
    self.open = true
    self.lastOpen = true
    self.closed = false
  else
    self:hideContent()
    self:setScale(nil, 0)
    self.lastOpen = false
    self.open = false
    self.closed = true
  end
end
--- Sets this window's position.
-- @tparam Vector position New position.
function Window:setXYZ(...)
  Transformable.setXYZ(self, ...)
  self:updatePosition()
end
--- Scales this window.
-- @tparam number sx Scale in axis x.
-- @tparam number sy Scale in axis y.
function Window:setScale(sx, sy)
  Transformable.setScale(self, sx, sy)
  if self.background then
    self.background:updateTransform(self, 1)
  end
  if self.frame then
    self.frame:updateTransform(self, 1)
  end
end
--- Changes the window's size.
-- It recreates all contents.
-- @tparam number w Window's width in UI coordinates.
-- @tparam number h Window's width in UI coordinates.
function Window:resize(w, h)
  w, h = w or self.width, h or self.height
  if w ~= self.width or h ~= self.height then
    self.width = w
    self.height = h
    if self.background then
      self.background:createGrid(MenuManager.renderer, w, h)
      self.background:setHSV(nil, nil, MenuManager.windowColor / 100)
    end
    if self.frame then
      self.frame:createGrid(MenuManager.renderer, w, h)
    end
    self:setPosition(self.position)
  end
end
--- Window's frame.
-- @treturn table
function Window:getFrame()
  return Database.animations[Config.animations.windowFrame]
end
--- Window's background.
-- @treturn table
function Window:getBG()
  return Database.animations[Config.animations.windowSkin]
end
--- Horizontal padding.
function Window:paddingX()
  return 8
end
--- Vertical padding.
function Window:paddingY()
  return 8
end

-- ------------------------------------------------------------------------------------------------
-- Show/hide
-- ------------------------------------------------------------------------------------------------

--- Overrides `Component:show`. Opens this window.
-- @override
function Window:show()
  if self.scaleY >= 1 then
    return
  end
  self.closed = false
  self.lastOpen = true
  self:scaleTo(self.scaleX, 1, self.speed, true)
  if self.scaleY >= 1 then
    self.open = true
    self:showContent()
  end
end
--- Overrides `Component:hide`. Closes this window.
-- @override
-- @tparam boolean fromMenu If it's called from Menu:hide.
--  If true, automatically opens the window back if its Menu opens again.
--  Else, it stays hidden until it is manually openned again.
function Window:hide(fromMenu)
  if self.scaleY <= 0 then
    return
  end
  self.lastOpen = fromMenu
  self.open = false
  self:hideContent()
  self:scaleTo(self.scaleX, 0, self.speed, true)
  if self.scaleX >= 1 then
    self.closed = true
  end
end
--- Inserts this window in the Menu's list.
function Window:insertSelf()
  if not self.menu.windowList:contains(self) then
    self.menu.windowList:add(self)
  end
end
--- Removes this window from the Menu's list.
function Window:removeSelf()
  self.menu.windowList:removeElement(self)
end

-- ------------------------------------------------------------------------------------------------
-- Content
-- ------------------------------------------------------------------------------------------------

--- Shows all content elements.
function Window:showContent(...)
  for c in self.content:iterator() do
    if c.updatePosition then
      c:updatePosition(self.position)
    end
    c:show(...)
  end
end
--- Hides all content elements.
function Window:hideContent(...)
  for c in self.content:iterator() do
    c:hide(...)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Input
-- ------------------------------------------------------------------------------------------------

--- Checks if player pressed any Menu button.
-- By default, only checks the "cancel" key.
function Window:checkInput()
  if not self.open then
    return
  end
  local x, y = InputManager.mouse:menuCoord()
  x, y = x - self.position.x, y - self.position.y
  if InputManager.textInput then
    self:onTextInput(InputManager.textInput)
  elseif InputManager.keys['confirm']:isTriggered() then
    self:onConfirm()
  elseif InputManager.keys['cancel']:isTriggered() then
    self:onCancel()
  elseif InputManager.keys['next']:isTriggered() then
    self:onNext()
  elseif InputManager.keys['prev']:isTriggered() then
    self:onPrev()
  elseif InputManager.keys['mouse1']:isTriggered() then
    self:onClick(1, x, y)
  elseif InputManager.keys['mouse2']:isTriggered() then
    self:onClick(2, x, y)
  elseif InputManager.keys['mouse3']:isTriggered() then
    self:onClick(3, x, y)
  elseif InputManager.keys['touch']:isReleased() and self.triggerPoint then
    local triggerPoint = self.triggerPoint
    self.triggerPoint = nil
    if InputManager.keys['touch']:getHoldTime() <= self.maxTouchHoldTime then
      self:onClick(5, x, y, triggerPoint)
    end
  elseif InputManager.keys['touch']:isTriggered() then
    self.triggerPoint = Vector(x, y)
    self:onClick(4, x, y)
  elseif InputManager.mouse.moved then
    self:onMouseMove(x, y)
  else
    local dx, dy = InputManager:ortAxis(0.5, 0.0625)
    if dx ~= 0 or dy ~= 0 then
      self:onMove(dx, dy)
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Input Callbacks
-- ------------------------------------------------------------------------------------------------

--- Called when player presses "confirm" key.
-- By default, only sets the result to 1.
function Window:onConfirm()
  self.result = 1
  if self.confirmSound then
    AudioManager:playSFX(self.confirmSound)
  end
end
--- Called when player presses "cancel" key.
-- By default, only dets the result to 0.
function Window:onCancel()
  self.result = 0
  if self.cancelSound then
    AudioManager:playSFX(self.cancelSound)
  end
end
--- Called when the player inserts a key while `InputManager.readingText` is true.
-- @tparam string c The inserted text.
function Window:onTextInput(c)
  -- Abstract.
end
--- Called when player presses arrows.
-- @tparam number dx Movement direction in the x axis (-1 to 1).
-- @tparam number dy Movement direction in the y axis (-1 to 1).
function Window:onMove(dx, dy)
  -- Abstract.
end
--- Called when player presses "next" key.
function Window:onNext()
  -- Abstract.
end
--- Called when player presses "prev" key.
function Window:onPrev()
  -- Abstract.
end
--- Called when player presses a mouse button or touches screen.
-- @tparam number button Button type ID (1-3 for mouse, 4-5 for touch).
-- @tparam number x Current cursor/touch x position relative to the window's center.
-- @tparam number y Current cursor/touch y position relative to the window's center.
-- @tparam Vector triggerPoint The point in which the click/touch started, relative to the window's center.
function Window:onClick(button, x, y, triggerPoint)
  if button == 1 then
    if self:isInside(x, y) then
      self:onMouseConfirm(x, y, triggerPoint)
    elseif self.offBoundsCancel then
      self:onMouseCancel(x, y)
    end
  elseif button == 2 then
    self:onCancel()
  elseif button == 4 then
    if self.offBoundsCancel and not self:isInside(x, y) then
      self:onMouseCancel(x, y)
    end
  elseif button == 5 then
    self:onMouseConfirm(x, y, triggerPoint)
  else
    self:onConfirm()
  end
end
--- Confirmation by mouse or touch.
-- @tparam number x Cursor/touch x position relative to the window's center.
-- @tparam number y Cursor/touch y position relative to the window's center.
function Window:onMouseConfirm(x, y)
  self:onConfirm()
end
--- Cancel my mouse or touch.
-- @tparam number x Cursor/touch x position relative to the window's center.
-- @tparam number y Cursor/touch y position relative to the window's center.
function Window:onMouseCancel(x, y)
  self:onCancel()
end
--- Called when player moves mouse.
-- @tparam number x Current cursor/touch x position relative to the window's center.
-- @tparam number y Current cursor/touch y position relative to the window's center.
function Window:onMouseMove(x, y)
end

return Window
