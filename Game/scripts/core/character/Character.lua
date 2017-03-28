
--[[===========================================================================

Character
-------------------------------------------------------------------------------
This class provides general functions to be called by callbacks. 
The [COUROUTINE] functions must ONLY be called from a callback.

=============================================================================]]

-- Imports
local CharacterBase = require('core/character/CharacterBase')
local Callback = require('core/callback/Callback')
local Vector = require('core/math/Vector')
local Stack = require('core/algorithm/Stack')
local Sprite = require('core/graphics/Sprite')

-- Alias
local mathf = math.field
local abs = math.abs
local max = math.max
local min = math.min
local sqrt = math.sqrt
local time = love.timer.getDelta

-- Constants
local dashSpeed = Config.player.dashSpeed
local pph = Config.grid.pixelsPerHeight
local castStep = 6

local Character = CharacterBase:inherit()

-------------------------------------------------------------------------------
-- Direction
-------------------------------------------------------------------------------

-- Turns on a vector's direction (in pixel coordinates).
-- @param(x : number) vector's x
-- @param(y : number) vector's y
function Character:turnToVector(x, y)
  if abs(x) > 0.1 or abs(y) > 0.1 then
    local angle = math.coord2Angle(x * mathf.tg, y)
    self:setDirection(angle)
  end
end

-- Turns to a pixel point.
-- @param(x : number) the pixel x
-- @param(y : number) the pixel y
function Character:turnToPoint(x, y)
  self:turnToVector(x - self.position.x, y - self.position.z)
end

-- Turns to a grid point.
-- @param(x : number) the tile x
-- @param(y : number) the tile y
function Character:turnToTile(x, y)
  local destx, desty, destz = mathf.tile2Pixel(x, y, 0)
  self:turnToVector(destx - self.position.x, destz - self.position.z)
end

-------------------------------------------------------------------------------
-- Movement
-------------------------------------------------------------------------------

-- [COUROUTINE] Walks to the given pixel point (x, y, d).
-- @param(x : number) coordinate x of the point
-- @param(y : number) coordinate y of the point
-- @param(z : number) the depth of the point
-- @param(collisionCheck : boolean) if it should check collisions
-- @ret(boolean) true if the movement was completed, false otherwise
function Character:walkToPoint(x, y, z, collisionCheck, walkAnim, idleAnim)
  idleAnim = idleAnim or "Idle"
  if not walkAnim then
    if self.speed >= dashSpeed then
      walkAnim = "Dash"
    else
      walkAnim = "Walk"
    end
  end
  z = z or self.position.z
  self.moving = true
  local dest = Vector(x, y, z)
  dest:round()
  if self.autoAnim then
    self:playAnimation(walkAnim)
  end
  if self.autoTurn then
    self:turnToPoint(dest.x, dest.z)
  end
  local origin = self.position:clone()
  local d = (dest - origin):len2D()
  local t = self.speed * time() / d
  while true do
    local collision = self:instantMoveTo(origin:lerp(dest, min(1, t)), collisionCheck)
    if collision ~= nil and self.stopOnCollision == true then
      if self.autoAnim then
        self:playAnimation(idleAnim)
      end
      self.moving = false
      print('Interruped walk.')
      return false
    end
    if t >= 1 then
      break
    end
    coroutine.yield()
    t = t + self.speed * time() / d
  end
  if self.autoAnim then
    self:playAnimation(idleAnim)
  end
  self.moving = false
  self:setPosition(dest)
  return true
end

function Character:walkDistance(dx, dy, dz, collisionCheck, walkAnim, idleAnim)
  local pos = self.position
  self:walkToPoint(pos.x + dx, pos.y + dy, pos.z + dz,
    collisionCheck, walkAnim, idleAnim)
end

-- Walks the given distance in the given direction.
-- @param(d : number) the distance to be walked
-- @param(angle : number) the direction angle
-- @param(dz : number) the distance in depth
-- @param(collisionCheck : boolean) if it should check collisions
-- @ret(boolean) true if the movement was completed, false otherwise
function Character:walkInAngle(d, angle, dz, collisionCheck, walkAnim, idleAnim)
  dz = dz or 0
  local dx, dy = math.angle2Coord(angle)
  self:walkDistance(dx * d, dy * d, dz, collisionCheck, walkAnim, idleAnim)
end

-- [COUROUTINE] Walks to the center of the tile (x, y).
-- @param(x : number) coordinate x of the tile
-- @param(y : number) coordinate y of the tile
-- @param(h : number) the height of the tile
-- @param(collisionCheck : boolean) if it should check collisions
-- @ret(boolean) true if the movement was completed, false otherwise
function Character:walkToTile(x, y, h, collisionCheck, walkAnim, idleAnim)
  x, y, h = mathf.tile2Pixel(x, y, h or self:getTile().layer.height)
  return self:walkToPoint(x, y, h, collisionCheck, walkAnim, idleAnim)
end

-- [COUROUTINE] Walks a distance in tiles defined by (dx, dy)
-- @param(dx : number) the x-axis distance
-- @param(dy : number) the y-axis distance
-- @param(h : number) the height of the tile
-- @param(collisionCheck : boolean) if it should check collisions
-- @ret(boolean) true if the movement was completed, false otherwise
function Character:walkTiles(dx, dy, dh, collisionCheck)
  local pos = self.position
  local x, y, h = mathf.pixel2Tile(pos.x, pos.y, pos.z)
  return self:walkToTile(x + dx, y + dy, h + (dh or 0), collisionCheck)
end

-------------------------------------------------------------------------------
-- Path
-------------------------------------------------------------------------------

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
    self:walkToTile(nextTile.x, nextTile.y, h, collisionCheck)
  end
end

-------------------------------------------------------------------------------
-- Battle
-------------------------------------------------------------------------------

-- Executes the intro animation for skill use.
-- @param(target : ObjectTile) the target of the skill
-- @param(skill : table) skill data from database
function Character:startSkill(target, skill)
  local x, y = mathf.tile2Pixel(target:coordinates())
  local dir = math.coord2Angle(x * mathf.tg, y)
  if skill.stepOnCast and dir == dir then
    self:walkInAngle(castStep, dir)
  end
  local time = 0
  if skill.userLoadAnim ~= '' then
    local anim = self:playAnimation(skill.userLoadAnim)
    time = anim.duration
  end
  if skill.loadAnimID >= 0 then
    local mirror = skill.mirror and dir > 90 and dir <= 270
    local pos = self.position
    local anim = BattleManager:playAnimation(skill.loadAnimID, 
      pos.x, pos.y, pos.z - 1, mirror)
    time = max(time, anim.duration)
  end
  Callback.current:wait(time)
end

-- Returns to original tile and stays idle.
-- @param(origin : ObjectTile) the original tile of the character
-- @param(skill : table) skill data from database
function Character:finishSkill(origin, skill)
  local x, y, z = mathf.tile2Pixel(origin:coordinates())
  if skill.stepOnCast and dir == dir then
    local autoTurn = self.autoTurn
    self.autoTurn = false
    self:walkToPoint(x, y, z)
    self.autoTurn = autoTurn
  end
  self:playAnimation("Idle")
end

function Character:damage(skill, result, origin)
  local previousSpeed = self.speed;
  local speed = previousSpeed * 0.75;
  if skill.damageType == 0 then -- on HP
    -- Damage HP
  else
    -- Damage SP
  end
  local currentTile = self:getTile()
  if currentTile ~= origin then
    self:turnToTile(origin)
  end
  local time = self:playAnimation("Damage").duration
  if skill.individualAnimID >= 0 then
    local mirror = self.direction > 90 and self.direction <= 270
    local pos = self.position
    BattleManager:playAnimation(skill.individualAnimID, 
      pos.x, pos.y, pos.z - 1, mirror)
  end
end

return Character
