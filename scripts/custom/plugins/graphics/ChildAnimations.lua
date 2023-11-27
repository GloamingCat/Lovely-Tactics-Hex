
-- ================================================================================================

--- Child that synchronizes with the parent animation.
---------------------------------------------------------------------------------------------------
-- @plugin ChildAnimations

--- Parameters in the Animation tags.
-- @tags Animation
-- @tfield table|string|number child Add a child to the animation. Can have multiple `child` tags.
--  When it's a table, the first element is the time stamp in frames to spawn the child, and the
--  second element is the child's ID or string. Otherwise, the value of the is the child ID/key and
-- the time stamp is `0`.

-- ================================================================================================

-- Imports
local Animation = require('core/graphics/Animation')
local Sprite = require('core/graphics/Sprite')
local List = require('core/datastruct/List')
local Vector = require('core/math/Vector')

-- Rewrites
local Animation_init = Animation.init
local Animation_callEvents = Animation.callEvents
local Animation_update = Animation.update
local Animation_reset = Animation.reset
local Animation_setOneshot = Animation.setOneshot
local Animation_destroy = Animation.destroy
local Sprite_setXYZ = Sprite.setXYZ
local Sprite_isVisible = Sprite.isVisible

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Rewrites `Animation:init`.
-- @rewrite
function Animation:init(...)
  Animation_init(self, ...)
  if self.tags and self.tags.child then
    for _, child in ipairs(self.tags:getAll('child')) do
      if type(child) == 'table' then
        self.childQueue = self.childQueue or {}
        self.childQueue[#self.childQueue + 1] = child
      else
        self:addChild(child)
      end
    end
  end
end
--- Adds an animation to the children list. If it's not an `Animation` type, then a new animation
-- is created from the it data in the database.
-- @tparam string|number|Animation anim The animation to be added, or its ID or key.
function Animation:addChild(anim)
  if type(anim) == 'number' or type(anim) == 'string' then
    anim = ResourceManager:loadAnimation(Database.animations[anim], self.sprite.renderer)
  elseif anim.parent then
    anim.parent:removeChild(anim)
  end
  anim.parent = self
  self.children = self.children or List()
  self.children:add(anim)
  if self.sprite and anim.sprite then
    self.sprite.children = self.sprite.children or List()
    self.sprite.children:add(anim.sprite)
    anim.sprite.parent = self.sprite
    anim.sprite:setParentXYZ(self.sprite.position:coordinates())
  end
end
--- Remove an animation from the children list.
-- @tparam Animation anim The animation to be removed.
-- @treturn boolean Whether `anim` was actually a child of this animation or not.
function Animation:removeChild(anim)
  if self.children and self.children:removeElement(anim) then
    anim.parent = nil
    if self.sprite and self.sprite.children and anim.sprite then
      self.sprite.children:removeElement(anim.sprite)
      anim.sprite.parent = nil
    end
    return true
  else
    return false
  end
end
--- Rewrites `Animation:callEvents`.
-- @rewrite
function Animation:callEvents()
  if self.childQueue then
    for _, c in pairs(self.childQueue) do
      if c[2] > self.lastEventTime and c[2] <= self.time then
        self:addChild(c[1])
      end
    end
  end
  Animation_callEvents(self)
end

-- ------------------------------------------------------------------------------------------------
-- Update
-- ------------------------------------------------------------------------------------------------

--- Rewrites `Animation:update`.
-- @rewrite
function Animation:update(dt)
  Animation_update(self, dt)
  if self.paused or not self.duration or not self.timing or not self.children then
    return
  end
  if self.children then
    for i = 1, self.children.size do
      self.children[i]:update(dt)
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Finish
-- ------------------------------------------------------------------------------------------------

--- Rewrites `Animation:reset`.
-- @rewrite
function Animation:reset()
  Animation_reset(self)
  if self.children then
    for i = 1, self.children.size do
      self.children[i]:reset()
    end
  end
end
--- Rewrites `Animation:setOneshot`.
-- @rewrite
function Animation:setOneshot(value)
  Animation_setOneshot(self, value)
  if self.children then
    for i = 1, self.children.size do
      self.children[i]:setOneshot(value)
    end
  end
end
--- Rewrites `Animation:destroy`.
-- @rewrite
function Animation:destroy()
  Animation_destroy(self)
  if self.children then
    for child in self.children:iterator() do
      child:destroy()
    end
  end
  if self.parent then
    self.parent:removeChild(self)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Sprite
-- ------------------------------------------------------------------------------------------------

--- Rewrites `Sprite:setXYZ`. Updates the parent position for each of the children.
-- @rewrite
function Sprite:setXYZ(...)
  Sprite_setXYZ(self, ...)
  if self.children then
    for i = 1, self.children.size do
      self.children[i]:setParentXYZ(...)
    end
  end
end
--- Stores the local position if nil and combines it with the parent's position.
-- @tparam number x Parent x.
-- @tparam number y Parent y.
-- @tparam number z Parent depth.
function Sprite:setParentXYZ(x, y, z)
  if not self.localPosition then
    self.localPosition = self.position:clone()
  end
  self:setXYZ((x or 0) + self.localPosition.x,
              (y or 0) + self.localPosition.y, 
              (z or 0) + self.localPosition.z)
end
--- Rewrites `Sprite:isVisible`. Returns false if parent is invisible.
-- @rewrite
function Sprite:isVisible()
  return Sprite_isVisible(self) and (self.parent == nil or self.parent:isVisible())
end
