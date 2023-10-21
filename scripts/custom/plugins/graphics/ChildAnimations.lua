
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
local List = require('core/datastruct/List')

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Rewrites `Animation:init`.
-- @override Animation_init
local Animation_init = Animation.init
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
  self.children = self.children or List()
  if type(anim) == 'number' or type(anim) == 'string' then
    anim = ResourceManager:loadAnimation(Database.animations[anim], self.sprite.renderer)
  end
  anim:setXYZ(self.sprite.position:coordinates())
  self.children:add(anim)
end
--- Rewrites `Animation:callEvents`.
-- @override Animation_callEvents
local Animation_callEvents = Animation.callEvents
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
-- @override Animation_update
local Animation_update = Animation.update
function Animation:update(dt)
  Animation_update(self, dt)
  if self.paused or not self.duration or not self.timing or not self.children then
    return
  end
  if self.children then
    for i = 1, #self.children do
      self.children[i]:update(dt)
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Finish
-- ------------------------------------------------------------------------------------------------

--- Rewrites `Animation:destroy`.
-- @override Animation_destroy
local Animation_destroy = Animation.destroy
function Animation:destroy()
  Animation_destroy(self)
  if self.children then
    for i = 1, #self.children do
      self.children[i]:destroy()
    end
  end
end
--- Rewrites `Animation:reset`.
-- @override Animation_reset
local Animation_reset = Animation.reset
function Animation:reset()
  Animation_reset(self)
  if self.children then
    for i = 1, #self.children do
      self.children[i]:reset()
    end
  end
end
--- Rewrites `Animation:setOneshot`.
-- @override Animation_setOneshot
local Animation_setOneshot = Animation.setOneshot
function Animation:setOneshot(value)
  Animation_setOneshot(self, value)
  if self.children then
    for i = 1, #self.children do
      self.children[i]:setOneshot(value)
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Position
-- ------------------------------------------------------------------------------------------------

--- Rewrites `Animation:setXYZ`.
-- @override Animation_setXYZ
local Animation_setXYZ = Animation.setXYZ
function Animation:setXYZ(...)
  Animation_setXYZ(self, ...)
  if self.children then
    for i = 1, #self.children do
      self.children[i]:setXYZ(...)
    end
  end
end
