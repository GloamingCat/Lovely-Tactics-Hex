
--[[===============================================================================================

AnimatedObject
---------------------------------------------------------------------------------------------------
An object with a table of animations.
Sets of animations may be created by using the separator ":" the animation's name in the given
format: "setName:animationName".

=================================================================================================]]

-- Imports
local Sprite = require('core/graphics/Sprite')
local Object = require('core/objects/Object')

local AnimatedObject = class(Object)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Creates sprite and animation list.
-- @param(animations : table) An array of animation data.
-- @param(animID : number) The start animation's ID.
-- @param(sets : boolean) True if animations are separated in sets.
function AnimatedObject:initGraphics(animations, initAnim, transform, sets)
  self.animName = nil
  self.transform = transform
  self.sprite = Sprite(FieldManager.renderer)
  if sets then
    self:initAnimationSets(animations)
  else
    self:initAnimationTable(animations)
  end
  if initAnim then
    self:playAnimation(initAnim)
  end
end
-- Creates the animation table from the animation list.
-- @param(animations : table) Array of animations.
function AnimatedObject:initAnimationTable(animations)
  self.animationData = {}
  for i = 1, #animations do
    self:addAnimation(animations[i].name, animations[i].id)
  end
end
-- Creates the animation table from the animation list.
-- @param(animations : table) Array of animations.
function AnimatedObject:initAnimationSets(animations)
  self.animationSets = {}
  self.animationSets['Default'] = {}
  self.animationSets['Battle'] = {}
  for i = 1, #animations do
    local parts = animations[i].name:trim():split(':')
    local setName, animName
    if #parts < 2 then
      setName, animName = 'Default', parts[1]
    else
      setName, animName = parts[1], parts[2]
    end
    self.animationData = self.animationSets[setName]
    if not self.animationData then
      self.animationData = {}
      self.animationSets[setName] = self.animationData
    end
    self:addAnimation(animName, animations[i].id)
  end
  self.animationData = {}
  self:setAnimations('Default')
end
-- Creates a new animation from the database.
-- @param(name : string) The name of the animation for the character.
-- @param(id : number) The animation's ID in the database.
function AnimatedObject:addAnimation(name, id)
  local animation = ResourceManager:loadAnimation(id, self.sprite)
  local data = animation.data
  local quad, texture = ResourceManager:loadQuad(data.quad, nil, data.cols, data.rows)
  self.animationData[name] = {
    transform = data.transform,
    animation = animation,
    texture = texture,
    quad = quad }
end

---------------------------------------------------------------------------------------------------
-- Play
---------------------------------------------------------------------------------------------------

-- Plays an animation by name, ignoring if the animation is already playing.
-- @param(name : string) Animation's name.
-- @param(row : number) The row of the animation's sprite sheet to play.
-- @ret(Animation) The animation that started to play (or current one if the name is the same).
function AnimatedObject:playAnimation(name, row)
  if self.animName == name then
    return self.animation
  else
    return self:replayAnimation(name, row)
  end
end
-- Plays an animation by name.
-- @param(name : string) animation's name (optional; current animation by default)
-- @param(row : number) The row of the animation's sprite sheet to play.
-- @ret(Animation) The animation that started to play.
function AnimatedObject:replayAnimation(name, row)
  name = name or self.animName
  local data = self.animationData[name]
  assert(data, "Animation does not exist: " .. tostring(name))
  self.animName = name
  local anim = data.animation
  self.sprite.quad = data.quad
  self.sprite:setTexture(data.texture)
  self.sprite:setTransformation(data.transform)
  self.sprite:applyTransformation(self.transform)
  if self.statusTransform then
    self.sprite:applyTransformation(self.statusTransform)
  end
  self.animation = anim
  anim.sprite = self.sprite
  if row then
    anim:setRow(row)
  end
  anim.paused = false
  self.sprite.renderer.needsRedraw = true
  return anim
end
-- Overrides Object:update. Updates animation.
function AnimatedObject:update()
  Object.update(self)
  if self.animation then
    self.animation:update()
  end
end

---------------------------------------------------------------------------------------------------
-- Animation Sets
---------------------------------------------------------------------------------------------------

-- Changes the animations in the current set.
-- @param(name : string) The name of the set.
function AnimatedObject:setAnimations(name)
  assert(self.animationSets[name], 'Animation set does not exist: ' .. tostring(name))
  for k, v in pairs(self.animationSets[name]) do
    self.animationData[k] = v
  end
end

return AnimatedObject
