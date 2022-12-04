
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
  return true
end
-- [COROUTINE] Moves to the given tile.
-- @param(tile : ObjectTile) The destination tile.
-- @ret(number) Returns false if path was blocked, true otherwise.
function Character:applyTileMovement(tile)
  local input = ActionInput(MoveAction(mathf.centerMask, 2), self, tile)
  local path, fullPath = input.action:calculatePath(input)
  if path and fullPath then
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

-- [COROUTINE] Play load animation.
-- @param(skill : table) Skill data from database.
-- @ret(number) The duration of the animation.
function Character:loadSkill(skill)
  -- Load animation (user)
  local minTime = 0
  if skill.userLoadAnim ~= '' then
    local anim = self:playAnimation(skill.userLoadAnim)
    anim:reset()
    local waitTime = tonumber(anim.tags and anim.tags.skillTime)
    if waitTime then
      _G.Fiber:wait(waitTime)
      return math.max(anim.duration, waitTime) - waitTime
    end
  end
  return 0
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
    local waitTime = tonumber(anim.tags and anim.tags.skillTime)
    if waitTime then
      minTime = math.max(anim.duration, waitTime) - waitTime
    end
    _G.Fiber:wait(waitTime)
  end
  return minTime
end
-- [COROUTINE] Returns to original tile and stays idle.
-- @param(origin : ObjectTile) The original tile of the character.
-- @param(skill : table) Skill data from database.
function Character:finishSkill(origin, skill)
  if skill.stepOnCast then
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

return Character
