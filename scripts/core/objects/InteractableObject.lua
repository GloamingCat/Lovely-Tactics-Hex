
-- ================================================================================================

--- Minimal interactable object.
-- It is created from a instance data table, which contains (x, y, h) coordinates, scripts, and 
-- passable and persistent properties.
-- The `Player` may also interact with this.
---------------------------------------------------------------------------------------------------
-- @fieldmod InteractableObject
-- @extend Object

-- ================================================================================================

-- Imports
local Interactable = require('core/field/Interactable')
local Object = require('core/objects/Object')

-- Alias
local copyTable = util.table.deepCopy
local tileDistance = math.field.tileDistance

-- Class table.
local InteractableObject = class(Object, Interactable)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor. Extends `Object:init` and initialize variables, scripts, and adds the object to
-- `FieldManager`'s `updateList` and `characterList`.
-- @tparam table instData Instance data from field file.
-- @tparam[opt] table save Persistent data from save file. 
function InteractableObject:init(instData, save)
  local tile = FieldManager.currentField:getObjectTile(instData.x, instData.y, instData.h)
  Object.init(self, instData, tile, save)
  Interactable.init(self, instData.scripts, instData.vars, save)
  FieldManager.updateList:add(self)
  FieldManager.characterList:add(self)
  FieldManager.characterList[self.key] = self
end
--- Extends `Object:initProperties`.
-- Sets generic properties, like key, passability, activeness, and persistency.
-- @override
function InteractableObject:initProperties(instData, save)
  Object.initProperties(self, instData, save)
  if save and save.passable ~= nil then
    self.passable = save.passable
  else
    self.passable = instData.passable
  end
  if save and save.active ~= nil then
    self.active = save.active
  else
    self.active = instData.active
  end
  self.persistent = instData.persistent
end
--- Overrides `Interactable:initScripts`.
-- @override
function InteractableObject:initScripts(scripts, save)
  Interactable.initScripts(self, scripts, save)
  self.faceToInteract = false
  self.approachToInteract = true
end

-- ------------------------------------------------------------------------------------------------
-- Tile
-- ------------------------------------------------------------------------------------------------

--- Looks for collisions with characters in the given tile.
-- @tparam ObjectTile tile The tile that the player is in or is trying to go.
-- @treturn boolean True if there was any blocking collision, false otherwise.
function InteractableObject:collideTile(tile)
  if not tile then
    return false
  end
  local blocking = false
  for char in tile.characterList:iterator() do
    if char ~= self  then
      self:trigger('onCollide', char.key, self.key)
      char:trigger('onCollide', char.key, self.key)
      if not char.passable then
        blocking = true
      end
    end
  end
  return blocking
end
--- Implements `Object:addToTiles`.
-- @override
function InteractableObject:addToTiles()
  self:getTile().characterList:add(self)
end
--- Implements `Object:removeFromTiles`.
-- @override
function InteractableObject:removeFromTiles()
  self:getTile().characterList:removeElement(self)
end

-- ------------------------------------------------------------------------------------------------
-- Interaction
-- ------------------------------------------------------------------------------------------------

--- Tries to interact with any character in the given tile.
-- @tparam ObjectTile tile The tile where the interactable is.
-- @tparam boolean fromPath Flag to tell whether the interaction ocurred while following a Path.
-- @treturn boolean True if the character interacted with something, false otherwise.
function InteractableObject:interactTile(tile, fromPath)
  if not tile then
    return false
  end
  local isFront = true
  local currentTile = self:getTile()
  if currentTile ~= tile then
    local frontTile = self:getFrontTile()
    isFront = frontTile and tileDistance(tile.x, tile.y, frontTile.x, frontTile.y) <= 1
  end
  local dir = self:shiftToRow(tile.x, tile.y) * 45
  isFront = self:getRoundedDirection() - dir
  local interacted = false
  for i = #tile.characterList, 1, -1 do
    local char = tile.characterList[i]
    if char ~= self 
        and not (char.approachToInteract and fromPath)
        and (not char.faceToInteract or isFront)
        and char:trigger('onInteract', true) then
      interacted = true
    end
  end
  return interacted
end
--- Interacts with whoever the character is looking at (if any).
-- @treturn boolean True if the character interacted with someone, false otherwise.
function InteractableObject:interact()
  self:playIdleAnimation()
  local angle = self:getRoundedDirection()
  local interacted = self:interactTile(self:getTile()) or self:interactAngle(angle)
    or self:interactAngle(angle - 45) or self:interactAngle(angle + 45)
  return interacted
end
--- Tries to interact with any character in the tile looked by the given direction.
-- @treturn boolean True if the character interacted with someone, false otherwise.
function InteractableObject:interactAngle(angle)
  local frontTiles = self:getFrontTiles(angle)
  for i = 1, #frontTiles do
    if self:interactTile(frontTiles[i]) then
      return true
    end
  end
  return false
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Overrides `Object:destroy` and `Interactable:destroy`.
-- @override
function InteractableObject:destroy(permanent)
  Object.destroy(self)
  Interactable.destroy(self)
  FieldManager.updateList:removeElement(self)
  FieldManager.characterList:removeElement(self)
  FieldManager.characterList[self.key] = false
  if permanent then
    self.deleted = true
  end
  if self.persistent then
    FieldManager:storeCharData(FieldManager.currentField.id, self)
  end
  print(self, 'destroyed')
end
--- Check if the character in still present in the current field's character list.
-- @treturn boolean Whether this character was removed from the field.
function InteractableObject:wasDestroyed()
  return not FieldManager.characterList:contains(self)
end
--- Overrides `Interactable:getPersistentData`. Saves `deleted` and `passable` flags.
-- @override
function InteractableObject:getPersistentData()
  local save = Interactable.getPersistentData(self)
  save.deleted = self.deleted
  save.passable = self.passable
  return save
end
-- For debugging.
function InteractableObject:__tostring()
  return 'InteractableObject (' .. self.key .. ')'
end  return InteractableObject