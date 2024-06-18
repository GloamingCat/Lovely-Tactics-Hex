
-- ================================================================================================

--- An instance of a character from `Database`.
-- The instance details are defined by the character instance in a field.
---------------------------------------------------------------------------------------------------
-- @fieldmod Character
-- @extend AnimatedInteractable

-- ================================================================================================

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local BattleAnimations = require('core/battle/BattleAnimations')
local AnimatedInteractable = require('core/objects/AnimatedInteractable')
local MoveAction = require('core/battle/action/MoveAction')

-- Alias
local mathf = math.field
local max = math.max

-- Class table.
local Character = class(AnimatedInteractable)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor. Overrides `AnimatecInteractable:init`.
-- @tparam table instData The character's instance data from field file.
-- @tparam table save The instance's save data.
function Character:init(instData, save)
  -- Character data
  local charID = save and save.charID or instData.charID
  local charData = Database.characters[charID]
  assert(charData, "Character data not found: " .. tostring(charID))
  -- General properties from character data
  instData.name = charData.name
  instData.collisionTiles = charData.tiles
  instData.animations = charData.animations
  instData.shadowID = charData.shadowID
  instData.transform = charData.transform
  self.id = charData.id
  self.charData = charData
  AnimatedInteractable.init(self, instData, save)
  if not save then
    self:addScripts(charData.scripts, charData.repeatCollisions)
  end
  -- Add to character list
  FieldManager.characterList:add(self)
  FieldManager.characterList[self.key] = self
  -- Battle info
  self.party = instData.party or -1
  self.battlerID = instData.battlerID or -1
  if self.battlerID == -1 then
    self.battlerID = charData.battlerID or -1
  end
end
--- Overrides `AnimatedInteractable:initGraphics`. Creates the portrait list.
-- @override
function Character:initGraphics(instData, save)
  self.portraits = {}
  for _, p in ipairs(self.charData.portraits) do
    self.portraits[p.name] = p
  end
  AnimatedInteractable.initGraphics(self, instData, save)
end
--- Overrides `AnimatedInteractable:initProperties`. Sets damage/KO animation names.
-- @override
function Character:initProperties(instData, save)
  AnimatedInteractable.initProperties(self, instData, save)
  self.collisionTiles = save and save.collisionTiles or instData.collisionTiles 
    or {{ dx = 0, dy = 0, height = 1 }}
  self.damageAnim = 'Damage'
  self.koAnim = 'KO'
end

-- ------------------------------------------------------------------------------------------------
-- Collision
-- ------------------------------------------------------------------------------------------------

--- Overrides `Object:getHeight`. 
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
-- Animation
-- ------------------------------------------------------------------------------------------------

--- Plays animation for when character is knocked out.
-- @treturn Animation The animation that started playing.
function Character:playKOAnimation()
  if self.party == TroopManager.playerParty then
    if Config.sounds.allyKO then
      AudioManager:playSFX(Config.sounds.allyKO)
    end
  else
    if Config.sounds.enemyKO then
      AudioManager:playSFX(Config.sounds.enemyKO)
    end
  end
  return self:playAnimation(self.koAnim)
end

-- ------------------------------------------------------------------------------------------------
-- Movement
-- ------------------------------------------------------------------------------------------------

--- Tries to move in a given angle.
-- @coroutine
-- @tparam number angle The angle in degrees to move.
-- @treturn boolean Returns false if the next angle must be tried, a number to stop trying.
--  If 0, then the path was free. If 1, there was a character in this tile.
function Character:tryAngleMovement(angle)  
  local frontTiles = self:getFrontTiles(angle)
  if #frontTiles == 0 then
    return false
  end
  for i = 1, #frontTiles do
    local result = self:tryTileMovement(frontTiles[i])
    if result ~= false then
      return result
    end
  end
  return false
end
--- Tries to move to the given tile.
-- @coroutine
-- @tparam ObjectTile tile The destination tile.
-- @treturn number Returns false if the next angle must be tried, a number to stop trying.
--  If 0, then the path was free. If 1, there was a character in this tile.
function Character:tryTileMovement(tile)
  local ox, oy, oh = self:tileCoordinates()
  local dx, dy, dh = tile:coordinates()
  if self.autoTurn then
    self:turnToTile(dx, dy)
  end
  local collision = FieldManager.currentField:collisionXYZ(self,
    ox, oy, oh, dx, dy, dh)
  if collision == nil then
    -- Free path
    if self:applyTileMovement(tile) then
      return 0
    end
  end
  if self.autoAnim then
    self:playIdleAnimation()
  end
  if collision == 3 then 
    -- Character collision
    if not self:collideTile(tile) then
      if self:applyTileMovement(tile) then
        return 0
      end
    end
    return 1
  end
  return false
end
--- Tries to walk a path to the given tile.
-- @coroutine
-- @tparam ObjectTile tile Destination tile.
-- @tparam number pathLength Maximum length of path.
-- @treturn boolean True if the character walked the full path.
function Character:tryPathMovement(tile, pathLength)
  local input = ActionInput(MoveAction(mathf.neighborMask, pathLength), self, tile)
  local path = input.action:calculatePath(input)
  if not (path and path.full) then
    return false
  end
  self.path = path:addStep(tile, 1):toStack()
  return true
end
--- Moves to the given tile.
-- @coroutine
-- @tparam ObjectTile tile The destination tile.
-- @treturn number Returns false if path was blocked, true otherwise.
function Character:applyTileMovement(tile)
  local input = ActionInput(MoveAction(mathf.centerMask, 2), self, tile)
  local path = input.action:calculatePath(input)
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
--- Walks the next tile of the path.
-- @coroutine
-- @treturn boolean True if character walked to the next tile, false if collided.
-- @treturn ObjectTile The next tile in the path:
--  If passable, it's the current tile;
--  If not, it's the front tile;
--  If path was empty, then nil.
function Character:consumePath()
  local tile = nil
  if not self.path:isEmpty() then
    tile = self.path:pop()
    if self:tryTileMovement(tile) == 0 then
      return true, tile
    end
  end
  self.path = nil
  return false, tile
end

-- ------------------------------------------------------------------------------------------------
-- Skill (user)
-- ------------------------------------------------------------------------------------------------

--- Play load animation.
-- @coroutine
-- @tparam table skill Skill data from database.
-- @treturn number The duration of the animation.
function Character:loadSkill(skill)
  -- Load animation (user)
  local minTime = 0
  if skill.animInfo.userLoad ~= '' then
    local anim = self:playAnimation(skill.animInfo.userLoad)
    anim:reset()
    local waitTime = tonumber(anim.tags and anim.tags.skillTime)
    if waitTime then
      _G.Fiber:wait(waitTime)
      return math.max(anim.duration, waitTime) - waitTime
    end
  end
  return 0
end
--- Plays cast animation.
-- @coroutine
-- @tparam table skill Skill's data.
-- @tparam number dir The direction of the cast.
-- @tparam ObjectTile target Target of the skill.
-- @treturn number The duration of the animation.
function Character:castSkill(skill, dir, target)
  -- Forward step
  if skill.animInfo.stepOnCast then
    self:playMoveAnimation()
    self:walkInAngle(self.castStep or 6, dir)
    self:playIdleAnimation()
  end
  -- Cast animation (user)
  local minTime = 0
  if skill.animInfo.userCast ~= '' then
    local anim = self:playAnimation(skill.animInfo.userCast)
    anim:reset()
    local waitTime = tonumber(anim.tags and anim.tags.skillTime)
    if waitTime then
      minTime = math.max(anim.duration, waitTime) - waitTime
    end
    _G.Fiber:wait(waitTime)
  end
  return minTime
end
--- Returns to original tile and stays idle.
-- @coroutine
-- @tparam ObjectTile origin The original tile of the character.
-- @tparam table skill Skill data from database.
function Character:finishSkill(origin, skill)
  if skill.animInfo.stepOnCast then
    local x, y, z = origin.center:coordinates()
    if self.position:almostEquals(x, y, z) then
      return
    end
    if self.autoAnim then
      self:playMoveAnimation()
    end
    self:walkToPoint(x, y, z)
    self:setXYZ(x, y, z)
  end
  if self.autoAnim then
    self:playIdleAnimation()
  end
end

-- ------------------------------------------------------------------------------------------------
-- Skill (target)
-- ------------------------------------------------------------------------------------------------

--- Plays damage and KO (if died) animation.
-- @coroutine
-- @tparam Skill skill The skill used.
-- @tparam ObjectTile origin The tile of the skill user.
-- @tparam table results Results of the skill.
function Character:skillDamage(skill, origin, results)
  local currentTile = self:getTile()
  if currentTile ~= origin then
    self:turnToTile(origin.x, origin.y)
  end
  local anim = self:playAnimation(self.damageAnim)
  anim:reset()
  _G.Fiber:wait(anim.duration)
  if self.battler:isAlive() then
    self:playIdleAnimation()
  else
    self:playKOAnimation()
    BattleAnimations.dieEffect(self)
    if self.charData.koFadeout and self.charData.koFadeout >= 0 then
      self:colorizeTo(nil, nil, nil, 0, 60 / self.charData.koFadeout, true)
      local troop = TroopManager.troops[self.party]
      local member = troop:moveMember(self.key, 1)
      TroopManager:deleteCharacter(self)
    end
  end
end
-- For debugging.
function Character:__tostring()
  return 'Character ' .. self.name .. ' (' .. self.key .. ')'
end

return Character
