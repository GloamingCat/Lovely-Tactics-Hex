
-- ================================================================================================

--- An `InteractableObject` with graphics and animation. It's any field object instance that does
-- not contain a `charID`, but contains an animation.  
-- Optional additional fields in the instance data include: `name`, `transform`,
-- `shadowID`. These fields need code to be defined.
---------------------------------------------------------------------------------------------------
-- @fieldmod AnimatedInteractable
-- @extend JumpingObject
-- @extend InteractableObject

-- ================================================================================================

-- Imports
local InteractableObject = require('core/objects/InteractableObject')
local JumpingObject = require('core/objects/JumpingObject')

-- Alias
local tile2Pixel = math.field.tile2Pixel

-- Class table.
local AnimatedInteractable = class(InteractableObject, JumpingObject)

-- ------------------------------------------------------------------------------------------------
-- Inititialization
-- ------------------------------------------------------------------------------------------------

--- Constructor. Extends `InteractableObject:init`. Combines with `TransformableObject:init` and
-- `AnimatedObject:initGraphics`
-- @tparam table instData The character's instance data from field file.
-- @tparam table save The instance's save data.
function AnimatedInteractable:init(instData, save)
  JumpingObject.init(self, instData, nil, save)
  InteractableObject.init(self, instData, save)
  self:initGraphics(instData, save)
end
--- Combines `InteractableObject:initProperties` and `JumpingObject:initProperties`.
-- @override
function AnimatedInteractable:initProperties(instData, save)
  InteractableObject.initProperties(self, instData, save)
  assert(save == self.saveData, tostring(save) .. ' ' .. tostring(self))
  JumpingObject.initProperties(self, instData, save)
end
--- Overrides `AnimatedObject:initGraphics`.
-- Sets visibility and other graphic properties from `AnimatedObject:initGraphics`.
-- @override
function AnimatedInteractable:initGraphics(instData, save)
  local animName = save and save.animName or instData.animation
  local direction = save and save.direction or instData.direction
  local transform = save and save.transform or instData.transform
  if instData.animations then
    JumpingObject.initGraphics(self, direction, instData.animations, animName, transform, true)
  else
    local animations = {{ name = animName, id = animName }}
    JumpingObject.initGraphics(self, direction, animations, animName, transform, false)
  end
  if save and save.visible == false or (not save or save.visible == nil) and instData.visible == false then
    self:setVisible(false)
  end
  local frame = save and save.animIndex or instData.frame
  if frame then
    self.animation:setIndex(frame)
  end
end
--- Overrides `Object:moves`. Returns true.
-- @override
function AnimatedInteractable:moves() 
  return true
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Combines `JumpingObject:update` with `InteractableObject:update`.
-- @override
function AnimatedInteractable:update(dt)
  JumpingObject.update(self, dt)
  InteractableObject.update(self, dt)
end
--- Combines `InteractableObject:destroy` and `JumpingObject:destroy`.
-- @override
function AnimatedInteractable:destroy(permanent)
  JumpingObject.destroy(self)
  InteractableObject.destroy(self, permanent)
end

-- ------------------------------------------------------------------------------------------------
-- Persistent Data
-- ------------------------------------------------------------------------------------------------

--- Overrides `InteractableObject:getPersistentData`. Includes position, direction and animation.
-- @override
function AnimatedInteractable:getPersistentData()
  local data = InteractableObject.getPersistentData(self)
  data.x = self.position.x
  data.y = self.position.y
  data.z = self.position.z
  data.direction = self.direction
  data.animName = self.animName
  data.speed = self.speed
  data.visible = self.visible
  data.autoTurn = self.autoTurn
  data.autoAnim = self.autoAnim
  return data
end
-- For debugging.
function AnimatedInteractable:__tostring()
  return 'AnimatedInteractable ' .. self.name .. ' (' .. self.key .. ')'
end

return AnimatedInteractable
