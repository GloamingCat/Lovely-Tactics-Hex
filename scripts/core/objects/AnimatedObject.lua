
-- ================================================================================================

--- An object with a table of animations.
-- Sets of animations may be created by using the separator ":" the animation's name in the given
-- format: `setName:animationName`.
---------------------------------------------------------------------------------------------------
-- @fieldmod AnimatedObject
-- @extend TransformableObject

-- ================================================================================================

-- Imports
local Affine = require('core/math/Affine')
local Sprite = require('core/graphics/Sprite')
local TransformableObject = require('core/objects/TransformableObject')

-- Class table.
local AnimatedObject = class(TransformableObject)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Creates sprite and animation sets.
-- @tparam table animations An array of animation data.
-- @tparam[opt] number initAnim The initial animation's name.
-- @tparam[opt] Affine.Transform transform The graphic's affine transformation.
-- @tparam[opt] boolean sets Flag to separate animation names in the form of `setname:animname`.
function AnimatedObject:initGraphics(animations, initAnim, transform, sets)
  self.animName = nil
  self.transform = transform or Affine.neutralTransform
  if self.sprite then
    self.sprite:destroy()
  end
  self.sprite = Sprite(FieldManager.renderer)
  if self.position then
    self.sprite:setPosition(self.position)
  end
  if sets then
    self:initAnimationSets(animations)
  else
    self:initAnimationTable(animations)
  end
  if initAnim then
    self:playAnimation(initAnim)
  end
end
--- Creates the animation table from the animation list.
-- @tparam table animations Array of animations.
function AnimatedObject:initAnimationTable(animations)
  self.animationData = {}
  for i = 1, #animations do
    self:addAnimation(animations[i].name, animations[i].id)
  end
end
--- Creates the animation table from the animation list.
-- @tparam table animations Array of animations.
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
--- Creates a new animation from the database.
-- @tparam string name The name of the animation for the character.
-- @tparam number|string id The animation's ID or key in the database.
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

-- ------------------------------------------------------------------------------------------------
-- Play
-- ------------------------------------------------------------------------------------------------

--- Plays an animation by name, ignoring if the animation is already playing.
-- @tparam string name Animation's name.
-- @tparam[opt=0] number row The row of the animation's sprite sheet to play.
-- @tparam[opt=1] number index Starting animation index.
-- @treturn Animation The animation that started to play (or current one if the name is the same).
function AnimatedObject:playAnimation(name, row, index)
  if self.animName == name then
    if row then
      self.animation:setRow(row)
    end
    if index then
      self.animation:setIndex(index)
    end
    return self.animation
  else
    return self:replayAnimation(name, row, index)
  end
end
--- Plays an animation by name.
-- @tparam[opt] string name Animation's name. If nil, uses the current animation's name.
-- @tparam[opt=0] number row The row of the animation's sprite sheet to play.
-- @tparam[opt=1] number index Starting animation index.
-- @treturn Animation The animation that started to play.
function AnimatedObject:replayAnimation(name, row, index)
  name = name or self.animName
  local data = self.animationData[name]
  assert(data, "Animation does not exist: " .. tostring(name))
  self.animName = name
  local anim = data.animation
  self.sprite.quad = data.quad
  self.sprite:setTexture(data.texture)
  self:refreshTransform(data.transform)
  self.animation = anim
  anim.sprite = self.sprite
  if row then
    anim:setRow(row)
  end
  if index then
    anim:setIndex(index)
  end
  anim.paused = false
  self.sprite.renderer.needsRedraw = true
  return anim
end
--- Resets the sprite transform.
-- @tparam[opt] table transform The initial transform table (usually, from animation data).
function AnimatedObject:refreshTransform(transform)
  if transform then
    self.sprite:setTransformation(transform)
    self.sprite:applyTransformation(self.transform)
  else
    self.sprite:setTransformation(self.transform)
  end
end
--- Overrides `Transformable:update`. Updates animation.
-- @override
function AnimatedObject:update(dt)
  TransformableObject.update(self, dt)
  if self.animation then
    self.animation:update(dt)
  end
  if self.sprite then
    self.sprite:update(dt)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Animation Sets
-- ------------------------------------------------------------------------------------------------

--- Changes the animations in the current set.
-- @tparam string name The name of the set.
function AnimatedObject:setAnimations(name)
  assert(self.animationSets[name], 'Animation set does not exist: ' .. tostring(name))
  for k, v in pairs(self.animationSets[name]) do
    self.animationData[k] = v
  end
end

return AnimatedObject
