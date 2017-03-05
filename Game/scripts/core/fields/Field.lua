
local FieldBase = require('core/fields/FieldBase')
local max = math.max
local mathf = math.field

--[[===========================================================================

The class implements methods to check collisions.

=============================================================================]]

local Field = FieldBase:inherit()

-------------------------------------------------------------------------------
-- Object Tile Access
-------------------------------------------------------------------------------

-- Return the Object Tile given the coordinates.
-- @param(x : number) the x coordinate
-- @param(y : number) the y coordinate
-- @param(z : number) the layer's height
-- @ret(ObjectTile) the tile in the coordinates (nil of out of bounds)
function FieldBase:getObjectTile(x, y, z)
  if self.objectLayers[z] == nil then
    return nil
  end
  if self.objectLayers[z].grid[x] == nil then
    return nil
  end
  return self.objectLayers[z].grid[x][y]
end

-- Return the Object Tile given the coordinates in a transition table.
-- @param(t : table) the transition with (tileX, tileY, height)
-- @ret(ObjectTile) the tile in the coordinates (nil of out of bounds)
function FieldBase:getObjectTileFromTransition(t)
  return self:getObjectTile(t.tileX + 1, t.tileY + 1, t.height)
end

-- Returns a iterator that navigates through all object tiles.
-- @ret(function) the grid iterator
function FieldBase:gridIterator()
  local maxl = table.maxn(self.objectLayers)
  local i, j, l = 1, 0, 0
  local layer = self.objectLayers[l]
  while layer == nil do
    l = l + 1
    if l > maxl then
      return function() end
    end
    layer = self.objectLayers[l]
  end
  return function()
    j = j + 1
    if j <= self.sizeY then 
      return layer.grid[i][j]
    else
      j = 1
      i = i + 1
      if i <= self.sizeX then
        return layer.grid[i][j]
      else
        i = 1
        l = l + 1
        if l <= maxl then
          layer = self.objectLayers[l]
          return layer.grid[i][j]
        end
      end
    end
  end
end

-------------------------------------------------------------------------------
-- Collision
-------------------------------------------------------------------------------

function Field:collisionXYZ(obj, origx, origy, origh, destx, desty, desth)
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
  if self:collidesObstacle(obj, origx, origy, origh, tile) then
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
function Field:collision(object, origCoord, destCoord)
  return self:collision(object, origCoord:coordinates(), destCoord:coordiantes())
end

-- Check a position exceeds border limits
-- @param(x : number) tile x
-- @param(y : number) tile y
-- @ret(boolean) true if exceeds, false otherwise
function Field:exceedsBorder(x, y)
  return x < 1 or y < 1 or x > self.sizeX or y > self.sizeY
end

-- Check if collides with terrains in the given coordinates.
-- @param(tilePos : Vector) the coordinates of the tile
-- @ret(boolean) true if collides, false otherwise
function Field:collidesTerrain(x, y, z)
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
function Field:collidesObstacle(object, origx, origy, origh, tile)
  return not tile:isPassableFrom(origx, origy, object)
end

-------------------------------------------------------------------------------
-- Terrains
-------------------------------------------------------------------------------

-- Gets the move cost in the given coordinates.
-- @param(x : number) the x in tiles
-- @param(y : number) the y in tiles
-- @param(height : number) the layer height
-- @ret(number) the max of the move costs
function Field:getMoveCost(x, y, height)
  local cost = 0
  local layers = self.terrainLayers[height]
  for i, layer in ipairs(layers) do
    cost = max(cost, layer.grid[x][y].moveCost)
  end
  return cost
end

-------------------------------------------------------------------------------
-- Grid
-------------------------------------------------------------------------------

function Field:isCollinear(tile1, tile2, tile3)
  return tile1.layer.height - tile2.layer.height == tile2.layer.height - tile3.layer.height and 
    mathf.isCollinear(tile1.x, tile1.y, tile2.x, tile2.y, tile3.x, tile3.y)
end

return Field
