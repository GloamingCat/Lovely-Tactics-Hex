
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
local Vector = require('core/math/Vector')

-- Alias
local tile2Pixel = math.field.tile2Pixel

-- Class table.
local AnimatedInteractable = class(Interactable, JumpingObject)

-- ------------------------------------------------------------------------------------------------
-- Inititialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam table instData The character's instance data from field file.
-- @tparam table save The instance's save data.
function AnimatedInteractable:init(instData, save)
  assert(not (save and save.deleted), 'Deleted object.')
  -- Position
  local pos = Vector(0, 0, 0)
  if save then
    pos.x, pos.y, pos.z = save.x, save.y, save.z
  else
    pos.x, pos.y, pos.z = tile2Pixel(instData.x, instData.y, instData.h)
  end
  -- Object:init
  JumpingObject.init(self, instData, pos)
  self.saveData = save
  FieldManager.updateList:add(self)
  -- Initialize properties
  self:initProperties(instData, save)
  self:initGraphics(instData, save)
  self:initScripts(instData, save)
  -- Initial position
  self:setPosition(pos)
  self:addToTiles()
end
--- Sets generic properties, like collision, speed, and other properties from `JumpingObject:initProperties`.
-- @tparam table instData The info about the object's instance.
-- @tparam[opt] table save The instance's save data.
function AnimatedInteractable:initProperties(instData, save)
  Interactable.initProperties(self, instData, save)
  JumpingObject.initProperties(self)
  self.name = instData.name or self.key
  self.autoAnim = not instData.fixedAnimation
  self.autoTurn = not instData.fixedDirection
  self.speed = (instData.defaultSpeed or 100) / 100 * Config.player.walkSpeed
  if save then
    self.speed = save.speed or (save.defaultSpeed or 100) * Config.player.walkSpeed / 100
    if save.autoAnim ~= nil then
      self.autoAnim = save.autoAnim
      self.autoTurn = save.autoTurn
    end
  end
end
--- Sets shadow, visibility and other graphic properties from `AnimatedObject:initGraphics`.
-- @tparam table instData The info about the object's instance.
-- @tparam[opt] table save The instance's save data.
function AnimatedInteractable:initGraphics(instData, save)
  local shadowID = save and save.shadowID or instData.shadowID
  if shadowID and shadowID >= 0 then
    local shadowData = Database.animations[shadowID]
    self.shadow = ResourceManager:loadSprite(shadowData, FieldManager.renderer)
  end
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

-- ------------------------------------------------------------------------------------------------
-- Shadow
-- ------------------------------------------------------------------------------------------------

--- Overrides `Object:setXYZ`. Updates shadow's position.
-- @override
function AnimatedInteractable:setXYZ(x, y, z)
  z = z or self.position.z
  JumpingObject.setXYZ(self, x, y, z)
  if self.shadow then
    self.shadow:setXYZ(x, y, z + 1)
  end
end
--- Overrides `Object:setVisible`. Updates shadow's visibility.
-- @override
function AnimatedInteractable:setVisible(value)
  JumpingObject.setVisible(self, value)
  if self.shadow then
    self.shadow:setVisible(value)
  end
end
--- Overrides `Object:setRGBA`. Updates shadow's color.
-- @override
function AnimatedInteractable:setRGBA(...)
  JumpingObject.setRGBA(self, ...)
  if self.sprite then
    self.sprite:setRGBA(...)
  end
  if self.shadow then
    self.shadow:setRGBA(nil, nil, nil, self.color.a)
  end
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Overrides `AnimatedObject:update`. Updates fibers.
-- @override
function AnimatedInteractable:update(dt)
  if self.paused then
    return
  end
  JumpingObject.update(self, dt)
  Interactable.update(self, dt)
end
--- Removes from draw and update list.
function AnimatedInteractable:destroy(permanent)
  if self.shadow then
    self.shadow:destroy()
  end
  FieldManager.characterList:removeElement(self)
  FieldManager.characterList[self.key] = false
  JumpingObject.destroy(self)
  Interactable.destroy(self, permanent)
end
--- Changes character's key.
-- @tparam string key New key.
function AnimatedInteractable:setKey(key)
  FieldManager.characterList[self.key] = nil
  FieldManager.characterList[key] = self
  self.key = key
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
  data.passable = self.passable
  data.autoTurn = self.autoTurn
  data.autoAnim = self.autoAnim
  return data
end
-- For debugging.
function AnimatedInteractable:__tostring()
  return 'AnimatedInteractable ' .. self.name .. ' (' .. self.key .. ')'
end

return AnimatedInteractable
