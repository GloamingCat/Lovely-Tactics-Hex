
--[[===============================================================================================

Child Animation
---------------------------------------------------------------------------------------------------
Child that synchronizes with the parent animation.

=================================================================================================]]

-- Imports
local Animation = require('core/graphics/Animation')
local List = require('core/datastruct/List')

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Override. Gets child animations from tags.
local Animation_init = Animation.init
function Animation:init(...)
  Animation_init(self, ...)
  if self.tags and self.tags.child then
    for _, childID in ipairs(self.tags:getAll('child')) do
      childID = childID:split()
      childID[2] = tonumber(childID[2])
      if childID[2] then
        self.childQueue = self.childQueue or {}
        self.childQueue[#self.childQueue + 1] = childID
      else
        self:addChild(childID[1])
      end
    end
  end
end
-- Shortcut function.
-- @param(anim : number : Animation)
function Animation:addChild(anim)
  self.children = self.children or List()
  if type(anim) == 'number' or type(anim) == 'string' then
    anim = ResourceManager:loadAnimation(Database.animations[anim], self.sprite.renderer)
  end
  anim:setXYZ(self.sprite.position:coordinates())
  self.children:add(anim)
end
-- Override. Instantiate delayed children.
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

---------------------------------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------------------------------

-- Override. Updates children.
local Animation_update = Animation.update
function Animation:update()
  Animation_update(self)
  if self.paused or not self.duration or not self.timing or not self.children then
    return
  end
  if self.children then
    for i = 1, #self.children do
      self.children[i]:update()
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Finish
---------------------------------------------------------------------------------------------------

-- Override. Destroys children.
local Animation_destroy = Animation.destroy
function Animation:destroy()
  Animation_destroy(self)
  if self.children then
    for i = 1, #self.children do
      self.children[i]:destroy()
    end
  end
end
-- Override. Resets children.
local Animation_reset = Animation.reset
function Animation:reset()
  Animation_reset(self)
  if self.children then
    for i = 1, #self.children do
      self.children[i]:reset()
    end
  end
end
-- Override. Sets children as oneshot.
local Animation_setOneshot = Animation.setOneshot
function Animation:setOneshot(value)
  Animation_setOneshot(self, value)
  if self.children then
    for i = 1, #self.children do
      self.children[i]:setOneshot(value)
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Position
---------------------------------------------------------------------------------------------------

-- Override. Sets children's position.
local Animation_setXYZ = Animation.setXYZ
function Animation:setXYZ(...)
  Animation_setXYZ(self, ...)
  if self.children then
    for i = 1, #self.children do
      self.children[i]:setXYZ(...)
    end
  end
end
