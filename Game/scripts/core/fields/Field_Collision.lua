
--[[===========================================================================

Field - Collision
-------------------------------------------------------------------------------
Implements functions to detect collisions in the field's layers.

=============================================================================]]

local Field_Collision = require('core/class'):new()

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

function Field_Collision:collisionXYZ(obj, origx, origy, origh, destx, desty, desth)
  if self:exceedsBorder(destx, desty) then
    return 0
  end
  if self:collidesTerrain(destx, desty, desth) then
    return 1
  end
  local layer = self.objectLayers[desth]
  if layer == nil then
    return 0
  end
  local tile = self:getObjectTile(destx, desty, desth)
  if tile:collidesObstacleFrom(obj, origx, origy, origh) then
    return 2
  elseif tile:collidesCharacter(obj) then
    return 3
  else
    return nil
  end
end

-- Checks if an object collides with something in the given point.
-- @param(object : Object) the object to check
-- @param(origCoord : Vector) the origin coordinates in tiles
-- @param(destCoord : Vector) the destination coordinates in tiles
-- @ret(number) the collision type. 
--  nil => none, 0 => border, 1 => terrain, 2 => obstacle, 3 => character
function Field_Collision:collision(object, origCoord, destCoord)
  local ox, oy, oz = origCoord:coordinates()
  return self:collision(object, ox, oy, oz, destCoord:coordinates())
end

-------------------------------------------------------------------------------
-- Collision types
-------------------------------------------------------------------------------

-- Check a position exceeds border limits
-- @param(x : number) tile x
-- @param(y : number) tile y
-- @ret(boolean) true if exceeds, false otherwise
function Field_Collision:exceedsBorder(x, y)
  return x < 1 or y < 1 or x > self.sizeX or y > self.sizeY
end

-- Check if collides with terrains in the given coordinates.
-- @param(tilePos : Vector) the coordinates of the tile
-- @ret(boolean) true if collides, false otherwise
function Field_Collision:collidesTerrain(x, y, z)
  local layerList = self.terrainLayers[z]
  if layerList == nil then
    return true
  end
  local n = #layerList
  local noGround = true
  for i = 1, n do
    local layer = layerList[i]
    local tile = layer.grid[x][y]
    if tile.terrainData ~= nil then
      if tile.terrainData.passable == false then
        return true
      else
        noGround = false
      end
    end
  end
  return noGround
end

-- Check if collides with obstacles.
-- @param(object : Object) the object to check collision
-- @param(origin : Vector) the object's origin coordinates in tiles
-- @param(tile : ObjectTile) the destination tile
-- @ret(boolean) true if collides, false otherwise
function Field_Collision:collidesObstacle(object, origx, origy, origh, tile)
  return tile:collidesObstacle(origx, origy, object)
end

return Field_Collision
