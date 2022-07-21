
--[[===============================================================================================

Character
---------------------------------------------------------------------------------------------------
This class provides general functions to be called by fibers. 
The [COUROUTINE] functions must ONLY be called from a fiber.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local CharacterBase = require('core/objects/CharacterBase')
local MoveAction = require('core/battle/action/MoveAction')

-- Alias
local mathf = math.field
local max = math.max
local tile2Pixel = math.field.tile2Pixel

local Character = class(CharacterBase)

---------------------------------------------------------------------------------------------------
-- Animation
---------------------------------------------------------------------------------------------------

-- Plays animation for when character is knocked out.
-- @ret(Animation) The animation that started playing.
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

---------------------------------------------------------------------------------------------------
-- Movement
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Tries to move in a given angle.
-- @param(angle : number) The angle in degrees to move.
-- @ret(boolean) Returns false if the next angle must be tried, a number to stop trying.
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
-- [COROUTINE] Tries to move to the given tile.
-- @param(tile : ObjectTile) The destination tile.
-- @ret(number) Returns false if the next angle must be tried, a number to stop trying.
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
    local input = ActionInput(MoveAction(mathf.centerMask, 2), self, tile)
    local path, fullPath = input.action:calculatePath(input)
    if path and fullPath then
      if self.autoAnim then
        self:playMoveAnimation()
      end
      local previousTiles = self:getAllTiles()
      self:onTerrainExit(previousTiles)
      self:removeFromTiles(previousTiles)
      self:addToTiles(self:getAllTiles(dx, dy, dh))
      self:walkToTile(dx, dy, dh)
      self:onTerrainEnter(self:getAllTiles())
      self:collideTile(tile)
      return 0
    end
  end
  if self.autoAnim then
    self:playIdleAnimation()
  end
  if collision == 3 then 
    -- Character collision
    self:collideTile(tile)
    return 1
  end
  return false
end
-- [COROUTINE] Tries to walk a path to the given tile.
-- @param(tile : ObjectTile) Destination tile.
-- @param(pathLength : number) Maximum length of path.
-- @ret(boolean) True if the character walked the full path.
function Character:tryPathMovement(tile, pathLength)
  local input = ActionInput(MoveAction(mathf.neighborMask, pathLength), self, tile)
  local path, fullPath = input.action:calculatePath(input)
  if not (path and fullPath) then
    return false
  end
  self.path = path:addStep(tile, 1):toStack()
  return self:consumePath()
end
-- [COROUTINE] Walks the next tile of the path.
-- @ret(boolean) True if character walked to the next tile, false if collided.
-- @ret(ObjectTile) The next tile in the path:
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

---------------------------------------------------------------------------------------------------
-- Skill (user)
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Executes the intro animations (load and cast) for skill use.
-- @param(target : ObjectTile) The target tile of the skill.
-- @param(skill : table) Skill data from database.
-- @ret(number) The duration of the animation.
function Character:loadSkill(skill, dir)
  local minTime = 0
  -- Load animation (user)
  if skill.userLoadAnim ~= '' then
    local anim = self:playAnimation(skill.userLoadAnim)
    anim:setIndex(1)
    anim.time = 0
    minTime = anim.duration
  end
  -- Load animation (effect on tile)
  if skill.loadAnimID >= 0 then
    local mirror = skill.mirror and dir > 90 and dir <= 270
    local pos = self.position
    local anim = BattleManager:playBattleAnimation(skill.loadAnimID, 
      pos.x, pos.y, pos.z - 1, mirror)
    minTime = max(minTime, anim.duration)
  end
  return minTime
end
-- [COROUTINE] Plays cast animation.
-- @param(skill : table) Skill's data.
-- @param(dir : number) The direction of the cast.
-- @param(tile : ObjectTile) Target of the skill.
-- @ret(number) The duration of the animation.
function Character:castSkill(skill, dir, target)
  -- Forward step
  if skill.stepOnCast then
    self:playMoveAnimation()
    self:walkInAngle(self.castStep or 6, dir)
    self:playIdleAnimation()
  end
  -- Cast animation (user)
  local minTime = 0
  if skill.userCastAnim ~= '' then
    local anim = self:playAnimation(skill.userCastAnim)
    anim:reset()
    minTime = anim.duration
  end
  -- Cast animation (effect on tile)
  if skill.castAnimID >= 0 then
    local mirror = skill.mirror and dir > 90 and dir <= 270
    local x, y, z = tile2Pixel(target:coordinates())
    local anim = BattleManager:playBattleAnimation(skill.castAnimID,
      x, y, z - 1, mirror)
    minTime = max(minTime, anim.duration)
  end
  return minTime
end
-- [COROUTINE] Returns to original tile and stays idle.
-- @param(origin : ObjectTile) The original tile of the character.
-- @param(skill : table) Skill data from database.
function Character:finishSkill(origin, skill)
  if skill.stepOnCast then
    local x, y, z = tile2Pixel(origin:coordinates())
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

---------------------------------------------------------------------------------------------------
-- Skill (target)
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Plays damage animation and shows the result in a pop-up.
-- @param(skill : Skill) The skill used.
-- @param(origin : ObjectTile) The tile of the skill user.
-- @param(results : table) Results of the skill.
function Character:damage(skill, origin, results)
  local currentTile = self:getTile()
  if currentTile ~= origin then
    self:turnToTile(origin.x, origin.y)
  end
  local anim = self:playAnimation(self.damageAnim)
  anim:reset()
  _G.Fiber:wait(anim.duration)
  if self.battler:isAlive() then
    self:playAnimation(self.idleAnim)
  else
    self:playKOAnimation()
  end
end

---------------------------------------------------------------------------------------------------
-- Turn callbacks
---------------------------------------------------------------------------------------------------

-- Callback for when a new turn begins.
function Character:onTurnStart(partyTurn)
  if self.AI and self.AI.onTurnStart then
    self.AI:onTurnStart(partyTurn)
  end
  self.battler.statusList:onTurnStart(self, partyTurn)
  if partyTurn then
    self.steps = self.battler.maxSteps()
  else
    self.steps = 0
  end
end
-- Callback for when a turn ends.
function Character:onTurnEnd(partyTurn)
  if self.AI and self.AI.onTurnEnd then
    self.AI:onTurnEnd(partyTurn)
  end
  self.battler.statusList:callback('TurnEnd', self, partyTurn)
end
-- Callback for when this battler's turn starts.
function Character:onSelfTurnStart()
  self.battler.statusList:callback('SelfTurnStart', self)
end
-- Callback for when this battler's turn ends.
function Character:onSelfTurnEnd(result)
  self.battler.statusList:callback('SelfTurnEnd', self, result)
end

---------------------------------------------------------------------------------------------------
-- Other callbacks
---------------------------------------------------------------------------------------------------

-- Callback for when the character moves.
-- @param(path : Path) The path that the battler just walked.
function Character:onMove(path)
  self.steps = self.steps - path.totalCost
  self.battler.statusList:callback('Move', self, path)
end
-- Callback for when the character enters the given tiles.
-- Adds terrain status.
-- @param(tiles : table) Array of terrain tiles.
function Character:onTerrainEnter(tiles)
  if self.battler then
    for t = 1, #tiles do
      local data = FieldManager.currentField:getTerrainStatus(tiles[t]:coordinates())
      for s = 1, #data do
        self.battler.statusList:addStatus(data[s].statusID, nil, self)
      end
    end
  end
end
-- Callback for when the character exits the given tiles.
-- Removes terrain status.
-- @param(tiles : table) Array of terrain tiles.
function Character:onTerrainExit(tiles)
  if self.battler then
    for i = 1, #tiles do
      local data = FieldManager.currentField:getTerrainStatus(tiles[i]:coordinates())
      for s = 1, #data do
        if data[s].removeOnExit then
          self.battler.statusList:removeStatus(data[s].statusID, self)
        end
      end
    end
  end
end

return Character
