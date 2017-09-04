
--[[===============================================================================================

AnimatedObject
---------------------------------------------------------------------------------------------------
An object with a table of animations.

=================================================================================================]]

-- Imports
local Sprite = require('core/graphics/Sprite')
local Animation = require('core/graphics/Animation')
local Object = require('core/objects/Object')

-- Alias
local mathf = math.field
local Quad = love.graphics.newQuad

local AnimatedObject = class(Object)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Creates sprite and animation list.
-- @param(animations : table) an array of animation data
-- @param(animID : number) the start animation's ID
function AnimatedObject:initializeGraphics(animations, initAnim, transform)
  self.animName = nil
  self.transform = transform
  self.animationData = {}
  self.sprite = Sprite(FieldManager.renderer)
  for i = #animations, 1, -1 do
    self:addAnimation(animations[i].name, animations[i].id)
  end
  if initAnim then
    self:playAnimation(initAnim)
  end
end
-- Creates a new animation from the database.
-- @param(name : string) the name of the animation for the character
-- @param(id : number) the animation's ID in the database
function AnimatedObject:addAnimation(name, id)
  local data = Database.animations[id]
  local animation = Animation(self.sprite, data)
  local quad, texture = ResourceManager:loadQuad(data)
  self.animationData[name] = {
    transform = data.transform,
    animation = animation,
    texture = texture,
    quad = quad }
end

---------------------------------------------------------------------------------------------------
-- Play
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Plays an animation by name.
-- @param(name : string) animation's name
-- @param(wait : boolean) true to wait until first loop finishes (optional)
function AnimatedObject:playAnimation(name, wait, row)
  if self.animName == name then
    return self.animation
  end
  local data = self.animationData[name]
  assert(data, "Animation does not exist: " .. name)
  self.animName = name
  local anim = data.animation
  self.sprite.quad = data.quad
  self.sprite:setTexture(data.texture)
  self.sprite:setTransformation(self.transform)
  self.sprite:applyTransformation(data.transform)
  self.animation = anim
  anim.sprite = self.sprite
  if row then
    anim:setRow(row)
  end
  anim.paused = false
  if wait and anim.duration then
    _G.Fiber:wait(anim.duration)
  end
  return anim
end
-- Updates animation.
function AnimatedObject:update()
  Object.update(self)
  if self.animation then
    self.animation:update()
  end
end

return AnimatedObject
