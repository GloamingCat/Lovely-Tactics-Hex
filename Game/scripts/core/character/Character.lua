
local Vector = require('core/math/Vector')
local Stack = require('core/algorithm/Stack')
local Sprite = require('core/graphics/Sprite')
local CharacterBase = require('core/character/CharacterBase')
local mathf = math.field
local abs = math.abs
local min = math.min
local dashSpeed = Config.player.dashSpeed
local time = love.timer.getDelta

--[[===========================================================================

This class provides general functions to be called
by callbacks. The [COUROUTINE] functions must ONLY
be called from a callback.

=============================================================================]]

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

-- [COUROUTINE] Walks to the center of the tile (x, y).
-- @param(x : number) coordinate x of the tile
-- @param(y : number) coordinate y of the tile
-- @param(h : number) the height of the tile
-- @param(collisionCheck : boolean) if it shoudl check collisions
-- @ret(boolean) true if the movement was successfully completed, false otherwise
function Character:walkToTile(x, y, h, collisionCheck, walkAnim, idleAnim)
  idleAnim = idleAnim or "Idle"
  if not walkAnim then
    if self.speed >= dashSpeed then
      walkAnim = "Dash"
    else
      walkAnim = "Walk"
    end
  end
  h = h or self:getTile().layer.height
  self.moving = true
  local dest = Vector(mathf.tile2Pixel(x, y, h))
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

-- [COUROUTINE] Walks a distance in tiles defined by (dx, dy)
-- @param(dx : number) the x-axis distance
-- @param(dy : number) the y-axis distance
-- @param(h : number) the height of the tile
-- @param(collisionCheck : boolean) if it shoudl check collisions
-- @ret(boolean) true if the movement was successfully completed, false otherwise
function Character:walkTiles(dx, dy, dh, collisionCheck)
  local x, y, h = mathf.pixel2Tile(self.position.x, self.position.y, self.position.z)
  return self:walkToTile(x + dx, y + dy, h + (dh or 0), collisionCheck)
end

-------------------------------------------------------------------------------
-- Path
-------------------------------------------------------------------------------

function Character:walkPath(path, collisionCheck)
  local stack = Stack()
  for step in path:iterator() do
    stack:push(step)
  end
  local currentTile = stack:pop()
  local field = FieldManager.currentField
  while not stack:isEmpty() do
    local nextTile = stack:pop()
    local dx, dy, dh = currentTile:coordinates()
    --[[while stack.size > 1 and field:isCollinear(currentTile, nextTile, stack:peek()) do
      currentTile = nextTile
      nextTile = stack:pop()
    end]]
    dx = nextTile.x - dx
    dy = nextTile.y - dy
    dh = nextTile.layer.height - dh
    self:walkTiles(dx, dy, dh, false)
    currentTile = nextTile
  end
end

return Character
