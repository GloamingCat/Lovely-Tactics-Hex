
--[[===========================================================================

Character
-------------------------------------------------------------------------------
This class provides general functions to be called by callbacks. 
The [COUROUTINE] functions must ONLY be called from a callback.

=============================================================================]]

-- Imports
local Character_Base = require('core/character/Character_Base')
local Character_Battle = require('core/character/Character_Battle')
local Callback = require('core/callback/Callback')
local Vector = require('core/math/Vector')
local Stack = require('core/algorithm/Stack')
local Sprite = require('core/graphics/Sprite')

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

-- Constants
local speedLimit = (Config.player.dashSpeed + Config.player.walkSpeed) / 2

local Character = Character_Base:inherit(Character_Battle)

-------------------------------------------------------------------------------
-- Direction
-------------------------------------------------------------------------------

-- Turns on a vector's direction (in pixel coordinates).
-- @param(x : number) vector's x
-- @param(y : number) vector's y
-- @ret(number) the angle to the given vector
function Character:turnToVector(x, y)
  if abs(x) > 0.01 or abs(y) > 0.01 then
    local angle = coord2Angle(x, y)
    self:setDirection(angle)
    return angle
  else
    return self.direction
  end
end

-- Turns to a pixel point.
-- @param(x : number) the pixel x
-- @param(y : number) the pixel y
-- @ret(number) the angle to the given point
function Character:turnToPoint(x, y)
  return self:turnToVector(x - self.position.x, y - self.position.z)
end

-- Turns to a grid point.
-- @param(x : number) the tile x
-- @param(y : number) the tile y
-- @ret(number) the angle to the given tile
function Character:turnToTile(x, y)
  local h = self:getTile().layer.height
  local destx, desty, destz = tile2Pixel(x, y, h)
  return self:turnToVector(destx - self.position.x, destz - self.position.z)
end

-------------------------------------------------------------------------------
-- Movement
-------------------------------------------------------------------------------

-- Overrides Transform:updatePosition to check collision.
function Character:updatePosition()
  if self.moveTime < 1 then
    self.moveTime = self.moveTime + self.moveSpeed * time() / self.moveDistance
    if self.moveTime >= 1 then
      self:setXYZ(self.moveDestX, self.moveDestY, self.moveDestZ)
      self.moveTime = 1
    else
      local x = self.moveOrigX * (1 - self.moveTime) + self.moveDestX * self.moveTime
      local y = self.moveOrigY * (1 - self.moveTime) + self.moveDestY * self.moveTime
      local z = self.moveOrigZ * (1 - self.moveTime) + self.moveDestZ * self.moveTime
      if self:instantMoveTo(x, y, z, self.collisionCheck) and self.stopOnCollision then
        self.moveTime = 1
      end
    end
  end
end

-- [COUROUTINE] Walks to the given pixel point (x, y, d).
-- @param(x : number) coordinate x of the point
-- @param(y : number) coordinate y of the point
-- @param(z : number) the depth of the point
-- @param(collisionCheck : boolean) if it should check collisions
-- @ret(boolean) true if the movement was completed, false otherwise
function Character:walkToPoint(x, y, z, collisionCheck)
  local anim = self.walkAnim
  if self.moveSpeed >= speedLimit then
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
  self.collisionCheck = collisionCheck
  self:moveTo(x, y, z, true)
    if self.autoAnim then
      self:playAnimation(self.idleAnim)
    end
  return self.position.x == x and self.position.y == y and self.position.z == z
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
  dz = dz or -dy
  return self:walkDistance(dx * d, dy * d, dz, collisionCheck)
end

-- [COUROUTINE] Walks to the center of the tile (x, y).
-- @param(x : number) coordinate x of the tile
-- @param(y : number) coordinate y of the tile
-- @param(h : number) the height of the tile
-- @param(collisionCheck : boolean) if it should check collisions
-- @ret(boolean) true if the movement was completed, false otherwise
function Character:walkToTile(x, y, h, collisionCheck)
  x, y, h = tile2Pixel(x, y, h or self:getTile().layer.height)
  return self:walkToPoint(x, y, h, collisionCheck)
end

-- [COUROUTINE] Walks a distance in tiles defined by (dx, dy)
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
    if not self:walkToTile(nextTile.x, nextTile.y, h, collisionCheck) then
      break
    end
  end
end

return Character
