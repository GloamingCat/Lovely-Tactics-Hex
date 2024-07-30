
-- ================================================================================================

--- An instance of a character from `Database`.
-- The instance details are defined by the character instance in a field.
---------------------------------------------------------------------------------------------------
-- @fieldmod Character
-- @extend AnimatedInteractable

-- ================================================================================================

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local AnimatedInteractable = require('core/objects/AnimatedInteractable')
local MoveAction = require('core/battle/action/MoveAction')

-- Alias
local mathf = math.field
local max = math.max

-- Class table.
local Character = class(AnimatedInteractable)

-- ------------------------------------------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------------------------------------------

--- Indicates the next action after a collision.
-- @enum Action
-- @field MOVE Code to proceed with movement. Equals 1.
-- @field INTERACT Code to interact with tile. Equals 2.
Character.Action = {
  MOVE = 1,
  INTERACT = 2
}

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor. Overrides `AnimatedInteractable:init`.
-- Stores id, character data and adds character-specific properties to the instance data.
-- @override
function Character:init(instData, save)
  local charID = save and save.charID or instData.charID
  local charData = Database.characters[charID]
  assert(charData, "Character data not found: " .. tostring(charID))
  self.id = charData.id
  self.charData = charData
  if not instData.name then
    instData.name = charData.name
    instData.collisionTiles = charData.tiles
    instData.animations = charData.animations
    instData.shadowID = charData.shadowID
    instData.transform = charData.transform
    util.array.addAll(instData.scripts, charData.scripts)
  end
  AnimatedInteractable.init(self, instData, save)
  self.fiberList:addScripts(charData.scripts)
end
--- Overrides `AnimatedInteractable:initGraphics`. Creates the portrait list and shadow.
-- @override
function Character:initGraphics(instData, save)
  self.portraits = {}
  for _, p in ipairs(self.charData.portraits) do
    self.portraits[p.name] = p
  end
  local shadowID = save and save.shadowID or instData.shadowID
  if self.shadow then
    self.shadow:destroy()
  end
  if shadowID and shadowID >= 0 then
    local shadowData = Database.animations[shadowID]
    self.shadow = ResourceManager:loadSprite(shadowData, FieldManager.renderer)
    self.shadow:setXYZ(self.position:coordinates())
  else
    self.shadow = nil
  end
  AnimatedInteractable.initGraphics(self, instData, save)
end
--- Overrides `AnimatedInteractable:initProperties`.
-- Sets collision tiles and autoanim/autoturn properties.
-- @override
function Character:initProperties(instData, save)
  AnimatedInteractable.initProperties(self, instData, save)
  self.autoAnim = not instData.fixedAnimation
  self.autoTurn = not instData.fixedDirection
  self.collisionTiles = instData.collisionTiles
end

-- ------------------------------------------------------------------------------------------------
-- Collision
-- ------------------------------------------------------------------------------------------------

--- Overrides `TransformableObject:getHeight`. 
-- @override
function Character:getHeight(dx, dy)
  dx, dy = dx or 0, dy or 0
  for i = 1, #self.collisionTiles do
    local tile = self.collisionTiles[i]
    if tile.dx == dx and tile.dy == dy then
      return tile.height
    end
  end
  return 0
end

-- ------------------------------------------------------------------------------------------------
-- Transform
-- ------------------------------------------------------------------------------------------------

--- Overrides `AnimatedObject:refreshTransform`.
-- Does not apply transform if not indicated in the character data.
-- Applies status transform, if any.
-- @override
function Character:refreshTransform(transform)
  self.sprite:setTransformation(transform)
  if self.charData.transformAnimations then
    self.sprite:applyTransformation(self.transform)
  end
  if self.statusTransform then
    self.sprite:applyTransformation(self.statusTransform)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Shadow
-- ------------------------------------------------------------------------------------------------

--- Overrides `AnimatedInteractable:setXYZ`. Updates shadow's position.
-- @override
function Character:setXYZ(x, y, z)
  z = z or self.position.z
  AnimatedInteractable.setXYZ(self, x, y, z)
  if self.shadow then
    self.shadow:setXYZ(x, y, z + 1)
  end
end
--- Overrides `AnimatedInteractable:setVisible`. Updates shadow's visibility.
-- @override
function Character:setVisible(value)
  AnimatedInteractable.setVisible(self, value)
  if self.shadow then
    self.shadow:setVisible(value)
  end
end
--- Overrides `AnimatedInteractable:setRGBA`. Updates shadow's color.
-- @override
function Character:setRGBA(...)
  AnimatedInteractable.setRGBA(self, ...)
  if self.shadow then
    self.shadow:setRGBA(nil, nil, nil, self.color.a)
  end
end
--- Overrides `AnimatedInteractable:update`. Updates shadow.
-- @override
function Character:update(dt)
  AnimatedInteractable.update(self, dt)
  if self.shadow then
    self.shadow:update(dt)
  end
end
--- Overrides `AnimatedInteractable:destroy`. Destroys shadow.
-- @override
function Character:destroy(permanent)
  if self.shadow then
    self.shadow:destroy()
  end
  AnimatedInteractable.destroy(self, permanent)
end

-- ------------------------------------------------------------------------------------------------
-- Tiles
-- ------------------------------------------------------------------------------------------------

--- Gets all tiles this object is occuping.
-- @treturn table The list of tiles.
function Character:getAllTiles(i, j, h)
  if not (i and j and h) then
    i, j, h = self:tileCoordinates()
  end
  local tiles = { }
  local last = 0
  for t = #self.collisionTiles, 1, -1 do
    local n = self.collisionTiles[t]
    local tile = FieldManager.currentField:getObjectTile(i + n.dx, j + n.dy, h)
    if tile ~= nil then
      last = last + 1
      tiles[last] = tile
    end
  end
  return tiles
end
--- Adds this object from to tiles it's occuping.
-- @tparam[opt] table tiles The list of occuped tiles.
function Character:addToTiles(tiles)
  tiles = tiles or self:getAllTiles()
  for i = #tiles, 1, -1 do
    tiles[i].characterList:add(self)
  end
end
--- Removes this object from the tiles it's occuping.
-- @tparam[opt] table tiles The list of occuped tiles.
function Character:removeFromTiles(tiles)
  tiles = tiles or self:getAllTiles()
  for i = #tiles, 1, -1 do
    tiles[i].characterList:removeElement(self)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Movement
-- ------------------------------------------------------------------------------------------------

--- Tries to move in a given angle.
-- @coroutine
-- @tparam number angle The angle in degrees to move.
-- @treturn Action Returns nil if the next angle must be tried, a number to stop trying.
--  If MOVE, then the path was free. If INTERACT, there was a character in this tile.
function Character:tryAngleMovement(angle)  
  local frontTiles = self:getFrontTiles(angle)
  if #frontTiles == 0 then
    return nil
  end
  for i = 1, #frontTiles do
    local result = self:tryTileMovement(frontTiles[i])
    if result then
      return result
    end
  end
  return nil
end
--- Tries to move to the given tile.
-- @coroutine
-- @tparam ObjectTile tile The destination tile.
-- @treturn Action Returns nil if the next angle must be tried, a number to stop trying.
--  If MOVE, then the path was free. If INTERACT, there was a character in this tile.
function Character:tryTileMovement(tile)
  local collision = self:collisionXYZ(tile)
  if self.autoTurn then
    self:turnToTile(tile.x, tile.y)
  end
  if collision == nil then
    -- Free path
    if self:applyTileMovement(tile) then
      return self.Action.MOVE
    end
  end
  if self.autoAnim then
    self:playIdleAnimation()
  end
  if collision == FieldManager.currentField.Collision.CHARACTER then 
    -- Character collision
    if not self:collideTile(tile) then
      -- Passable character
      if self:applyTileMovement(tile) then
        return self.Action.MOVE
      end
    end
    self:adjustToTile()
    return self.Action.INTERACT
  end
  self:adjustToTile()
  return nil
end
--- Tries to walk a path to the given tile.
-- @coroutine
-- @tparam ObjectTile tile Destination tile.
-- @tparam[opt=-1] number pathLength Maximum length of path. If -1, there's no limit.
-- @treturn boolean Whether a full path to the destination tile could be found.
function Character:computePathTo(tile, pathLength)
  if pathLength == -1 then
    pathLength = math.huge
  end
  local input = ActionInput(MoveAction(mathf.neighborMask, pathLength), self, tile)
  local path = input.action:computePath(input)
  if not (path and path.full) then
    return false
  end
  self.path = path:addStep(tile, 1):toStack()
  return true
end
--- Walks the next tile of the path.
-- @coroutine
-- @tparam[opt=1] number limit The maximum number of steps to walk. If -1, there's no limit.
-- @treturn Action Nil if blocked, MOVE if the character walked, and INTERACT encountered a character.
-- @treturn ObjectTile The next tile in the path:
--  If blocked, it's the front tile; If not, it's the current tile.
function Character:tryPathMovement(limit)
  limit = limit or 1
  if limit == -1 then
    limit = math.huge
  end
  local tile = nil
  local action = self.Action.MOVE
  while limit > 0 and not self.path:isEmpty() do
    tile = self.path:pop()
    action = self:tryTileMovement(tile)
    if action ~= self.Action.MOVE then
      break
    end
    limit = limit - 1
  end
  return action, tile
end
--- Moves to the given tile.
-- @coroutine
-- @tparam ObjectTile tile The destination tile.
-- @treturn boolean Returns false if path was blocked, true otherwise.
function Character:applyTileMovement(tile)
  local input = ActionInput(MoveAction(mathf.centerMask, 2), self, tile)
  local path = input.action:computePath(input)
  if path and path.full then
    if self.autoAnim then
      self:playMoveAnimation()
    end
    local dx, dy, dh = tile:coordinates()
    local previousTiles = self:getAllTiles()
    if self.battler then
      self.battler:onTerrainExit(self, previousTiles)
    end
    self:removeFromTiles(previousTiles)
    self:addToTiles(self:getAllTiles(dx, dy, dh))
    self:walkToTile(dx, dy, dh)
    if self.battler then
      self.battler:onTerrainEnter(self, self:getAllTiles())
    end
    self:collideTile(tile)
    return true
  end
  return false
end

-- ------------------------------------------------------------------------------------------------
-- Persistent Data
-- ------------------------------------------------------------------------------------------------

--- Overrides `AnimatedInteractable:getPersistentData`. Includes autoturn/autoanim.
-- @override
function Character:getPersistentData()
  local data = AnimatedInteractable.getPersistentData(self)
  data.autoTurn = self.autoTurn
  data.autoAnim = self.autoAnim
  return data
end
-- For debugging.
function Character:__tostring()
  return 'Character ' .. self.name .. ' (' .. self.key .. ')'
end

return Character
