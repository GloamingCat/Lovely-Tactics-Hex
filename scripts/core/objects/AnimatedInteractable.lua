
-- ================================================================================================

--- An `Interactable` with graphics and animation. It's any field object instance that does not
-- contain a `charID`, but contains an animation.  
-- Optional additional fields in the instance data include: `name`, `transform`,
-- `shadowID`. These fields need code to be defined.
---------------------------------------------------------------------------------------------------
-- @fieldmod AnimatedInteractable
-- @extend JumpingObject
-- @extend Interactable

-- ================================================================================================

-- Imports
local Interactable = require('core/objects/Interactable')
local JumpingObject = require('core/objects/JumpingObject')

-- Alias
local tile2Pixel = math.field.tile2Pixel

-- Class table.
local AnimatedInteractable = class(Interactable, JumpingObject)

-- ------------------------------------------------------------------------------------------------
-- Inititialization
-- ------------------------------------------------------------------------------------------------

--- Constructor. Extends `Interactable:init`. Combines with `TransformableObject:init` and
-- `AnimatedObject:initGraphics`
-- @tparam table instData The character's instance data from field file.
-- @tparam table save The instance's save data.
function AnimatedInteractable:init(instData, save)
  JumpingObject.init(self, instData, nil, save)
  Interactable.init(self, instData, save)
  self:initGraphics(instData, save)
end
--- Combines `Interactable:initProperties` and `JumpingObject:initProperties`.
-- @override
function AnimatedInteractable:initProperties(instData, save)
  Interactable.initProperties(self, instData, save)
  JumpingObject.initProperties(self, instData)
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

--- Combines `JumpingObject:update` with `Interactable:update`.
-- @override
function AnimatedInteractable:update(dt)
  JumpingObject.update(self, dt)
  Interactable.update(self, dt)
end
--- Combines `Interactable:destroy` and `JumpingObject:destroy`.
-- @override
function AnimatedInteractable:destroy(permanent)
  JumpingObject.destroy(self)
  Interactable.destroy(self, permanent)
end

-- ------------------------------------------------------------------------------------------------
-- Persistent Data
-- ------------------------------------------------------------------------------------------------

--- Overrides `Interactable:getPersistentData`. Includes position, direction and animation.
-- @override
function AnimatedInteractable:getPersistentData()
  local data = Interactable.getPersistentData(self)
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
