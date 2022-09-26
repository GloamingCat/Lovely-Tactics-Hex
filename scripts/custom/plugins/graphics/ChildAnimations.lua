
--[[===============================================================================================

Child Animation
---------------------------------------------------------------------------------------------------
Child that synchronizes with the parent animation.

=================================================================================================]]

-- Imports
local Animation = require('core/graphics/Animation')
local List = require('core/datastruct/List')

local Animation_initialize = Animation.initialize
function Animation:initialize(sprite, data)
  Animation_initialize(self, sprite, data)
  if self.tags.child then
    self.children = List()
    for _, childID in ipairs(self.tags:getAll('child')) do
      self.children:add(ResourceManager:loadAnimation(childID, sprite.renderer))
    end
  end
end
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
local Animation_destroy = Animation.destroy
function Animation:destroy()
  Animation_destroy(self)
  if self.children then
    for i = 1, #self.children do
      self.children[i]:destroy()
    end
  end
end
local Animation_reset = Animation.reset
function Animation:reset()
  Animation_reset(self)
  if self.children then
    for i = 1, #self.children do
      self.children[i]:reset()
    end
  end
end
-- Shortcut function.
-- @param(anim : number : Animation)
function Animation:addChild(anim)
  self.children = self.children or List()
  if type(anim) == 'number' then
    self.children:add(ResourceManager:loadAnimation(anim, self.sprite.renderer))
  else
    self.children:add(anim)
  end
end
