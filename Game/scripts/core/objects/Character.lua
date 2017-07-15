
--[[===============================================================================================

Character
---------------------------------------------------------------------------------------------------
This class provides general functions to be called by fibers. 
The [COUROUTINE] functions must ONLY be called from a fiber.

=================================================================================================]]

-- Imports
local CharacterBase = require('core/objects/CharacterBase')
local Vector = require('core/math/Vector')
local Stack = require('core/datastruct/Stack')
local Sprite = require('core/graphics/Sprite')
local PopupText = require('core/battle/PopupText')

-- Alias
local abs = math.abs
local max = math.max
local min = math.min
local round = math.round
local sqrt = math.sqrt
local time = love.timer.getDelta
local angle2Coord = math.angle2Coord
local coord2Angle = math.coord2Angle
local tile2Pixel = math.field.tile2Pixel
local pixel2Tile = math.field.pixel2Tile
local len2D = math.len2D

-- Constants
local speedLimit = (Config.player.dashSpeed + Config.player.walkSpeed) / 2
local castStep = 6

local Character = class(CharacterBase)

---------------------------------------------------------------------------------------------------
-- General Movement
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Walks to the given pixel point (x, y, d).
-- @param(x : number) coordinate x of the point
-- @param(y : number) coordinate y of the point
-- @param(z : number) the depth of the point
-- @param(collisionCheck : boolean) if it should check collisions
-- @ret(boolean) true if the movement was completed, false otherwise
function Character:walkToPoint(x, y, z, collisionCheck)
  local anim = self.walkAnim
  if self.speed >= speedLimit then
    anim = self.dashAnim
  end
  z = z or self.position.z
  x, y, z = round(x), round(y), round(z)
  if self.autoAnim then
    self:playAnimation(anim)
  end
  if self.autoTurn then
    self:turnToPoint(x, z)
  end
  local distance = len2D(self.position.x - x, self.position.y - y, self.position.z - z)
  self.collisionCheck = collisionCheck
  self:moveTo(x, y, z, self.speed / distance, true)
  if self.autoAnim then
    self:playAnimation(self.idleAnim)
  end
  return self.position:almostEquals(x, y, z)
end
-- Walks a given distance in each axis.
-- @param(dx : number) the distance in axis x (in pixels)
-- @param(dy : number) the distance in axis y (in pixels)
-- @param(dz : number) the distance in depth (in pixels)
-- @param(collisionCheck : boolean) if it should check collisions
-- @ret(boolean) true if the movement was completed, false otherwise
function Character:walkDistance(dx, dy, dz, collisionCheck)
  local pos = self.position
  return self:walkToPoint(pos.x + dx, pos.y + dy, pos.z + dz, collisionCheck)
end
-- Walks the given distance in the given direction.
-- @param(d : number) the distance to be walked
-- @param(angle : number) the direction angle
-- @param(dz : number) the distance in depth
-- @param(collisionCheck : boolean) if it should check collisions
-- @ret(boolean) true if the movement was completed, false otherwise
function Character:walkInAngle(d, angle, dz, collisionCheck)
  local dx, dy = angle2Coord(angle or self.direction)
  dz = dz or dy
  return self:walkDistance(dx * d, -dy * d, dz * d, collisionCheck)
end
-- [COROUTINE] Walks to the center of the tile (x, y).
-- @param(x : number) coordinate x of the tile
-- @param(y : number) coordinate y of the tile
-- @param(h : number) the height of the tile
-- @param(collisionCheck : boolean) if it should check collisions
-- @ret(boolean) true if the movement was completed, false otherwise
function Character:walkToTile(x, y, h, collisionCheck)
  x, y, h = tile2Pixel(x, y, h or self:getTile().layer.height)
  return self:walkToPoint(x, y, h, collisionCheck)
end
-- [COROUTINE] Walks a distance in tiles defined by (dx, dy)
-- @param(dx : number) the x-axis distance
-- @param(dy : number) the y-axis distance
-- @param(h : number) the height of the tile
-- @param(collisionCheck : boolean) if it should check collisions
-- @ret(boolean) true if the movement was completed, false otherwise
function Character:walkTiles(dx, dy, dh, collisionCheck)
  local pos = self.position
  local x, y, h = pixel2Tile(pos.x, pos.y, pos.z)
  return self:walkToTile(x + dx, y + dy, h + (dh or 0), collisionCheck)
end

---------------------------------------------------------------------------------------------------
-- Path
---------------------------------------------------------------------------------------------------

-- Walks along the given path.
-- @param(path : Path) a path of tiles
-- @param(collisionCheck : boolean) if it shoudl check collisions
-- @ret(boolean) true if the movement was completed, false otherwise
function Character:walkPath(path, collisionCheck)
  local stack = Stack()
  for step in path:iterator() do
    stack:push(step)
  end
  stack:pop()
  local field = FieldManager.currentField
  while not stack:isEmpty() do
    local nextTile = stack:pop()
    local h = nextTile.layer.height
    if not self:walkToTile(nextTile.x, nextTile.y, h, collisionCheck) and collisionCheck then
      break
    end
  end
  self:moveToTile(path.lastStep)
end

---------------------------------------------------------------------------------------------------
-- Skill (user)
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Executes the intro animations (load and cast) for skill use.
-- @param(target : ObjectTile) the target of the skill
-- @param(skill : table) skill data from database
function Character:loadSkill(skill, dir)
  local minTime = 0
  -- Load animation (user)
  if skill.userLoadAnim ~= '' then
    local anim = self:playAnimation(skill.userLoadAnim)
    minTime = anim.duration
  end
  -- Load animation (effect on tile)
  if skill.loadAnimID >= 0 then
    local mirror = skill.mirror and dir > 90 and dir <= 270
    local pos = self.position
    local anim = BattleManager:playAnimation(skill.loadAnimID, 
      pos.x, pos.y, pos.z - 1, mirror)
    minTime = max(minTime, anim.duration)
  end
  _G.Fiber:wait(minTime)
end
-- [COROUTINE] Plays cast animation.
-- @param(skill : Skill)
-- @param(dir : number) the direction of the cast
function Character:castSkill(skill, dir)
  local minTime = 0
  -- Forward step
  if skill.stepOnCast then
    local oldAutoTurn = self.autoTurn
    self.autoTurn = false
    self:walkInAngle(castStep, dir)
    self.autoTurn = oldAutoTurn
  end
  -- Cast animation (user)
  if skill.userCastAnim ~= '' then
    local anim = self:playAnimation(skill.userCastAnim)
    minTime = anim.duration
  end
  -- Cast animation (effect on tile)
  if skill.castAnimID >= 0 then
    local mirror = skill.mirror and dir > 90 and dir <= 270
    local pos = self.position
    local anim = BattleManager:playAnimation(skill.castAnimID, 
      pos.x, pos.y, pos.z - 1, mirror)
    minTime = max(minTime, anim.duration)
  end
  if wait then
    _G.Fiber:wait(minTime)
  end
end
-- [COROUTINE] Returns to original tile and stays idle.
-- @param(origin : ObjectTile) the original tile of the character
-- @param(skill : table) skill data from database
function Character:finishSkill(origin, skill)
  local x, y, z = tile2Pixel(origin:coordinates())
  if skill.stepOnCast then
    local autoTurn = self.autoTurn
    self.autoTurn = false
    self:walkToPoint(x, y, z)
    self.autoTurn = autoTurn
    self:setXYZ(x, y, z)
  end
  self:playAnimation(self.idleAnim)
end

---------------------------------------------------------------------------------------------------
-- Skill (target)
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Plays damage animation and shows the result in a pop-up.
-- @param(skill : Skill) the skill used
-- @param(result : number) the the damage caused
-- @param(origin : ObjectTile) the tile of the skill user
function Character:damage(skill, results, origin)
  local currentTile = self:getTile()
  self:turnToTile(origin.x, origin.y)
  self:playAnimation(self.damageAnim, true)
  self:playAnimation(self.idleAnim)
  if not self.battler:isAlive() then
    self:playAnimation(self.koAnim, true)
  end
end

return Character
