
--[[===========================================================================

DirectedObject
-------------------------------------------------------------------------------
An object with a direction.

=============================================================================]]

-- Imports
local AnimatedObject = require('core/character/AnimatedObject')

-- Alias
local angle2Row = math.angle2Row
local coord2Angle = math.coord2Angle
local nextCoordDir = math.field.nextCoordDir
local tile2Pixel = math.field.tile2Pixel
local abs = math.abs

local DirectedObject = AnimatedObject:inherit()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides AnimatedObject:initializeGraphics.
-- @param(direction : number) the initial direction
local old_initializeGraphics = DirectedObject.initializeGraphics
function DirectedObject:initializeGraphics(animations, direction, animID, transform)
  self.direction = direction
  old_initializeGraphics(self, animations, animID, transform)
  self:setDirection(direction)
end

---------------------------------------------------------------------------------------------------
-- Direction
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Plays an animation by name.
-- @param(name : string) animation's name
-- @param(wait : boolean) true to wait until first loop finishes (optional)
-- @param(row : number) the row of the animation (optional)
local old_playAnimation = DirectedObject.playAnimation
function DirectedObject:playAnimation(name, wait, row)
  row = row or angle2Row(self.direction)
  return old_playAnimation(self, name, wait, row)
end

-- Set's character direction
-- @param(angle : number) angle in degrees
function DirectedObject:setDirection(angle)
  self.direction = angle
  self.animation:setRow(angle2Row(angle))
end

-- The tile on front of the character, considering character's direction.
-- @ret(ObjectTile) the front tile (nil if exceeds field border)
function DirectedObject:frontTile(angle)
  angle = angle or self.direction
  local dx, dy = nextCoordDir(angle)
  local tile = self:getTile()
  if FieldManager.currentField:exceedsBorder(tile.x + dx, tile.y + dy) then
    return nil
  else
    return tile.layer.grid[tile.x + dx][tile.y + dy]
  end
end

-------------------------------------------------------------------------------
-- Rotate
-------------------------------------------------------------------------------

-- Turns on a vector's direction (in pixel coordinates).
-- @param(x : number) vector's x
-- @param(y : number) vector's y
-- @ret(number) the angle to the given vector
function DirectedObject:turnToVector(x, y)
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
function DirectedObject:turnToPoint(x, y)
  return self:turnToVector(x - self.position.x, y - self.position.z)
end

-- Turns to a grid point.
-- @param(x : number) the tile x
-- @param(y : number) the tile y
-- @ret(number) the angle to the given tile
function DirectedObject:turnToTile(x, y)
  local h = self:getTile().layer.height
  local destx, desty, destz = tile2Pixel(x, y, h)
  return self:turnToVector(destx - self.position.x, destz - self.position.z)
end

return DirectedObject
