
--[[===========================================================================

Field
-------------------------------------------------------------------------------
The class implements methods to check collisions.

=============================================================================]]

-- Imports
local Field_Layers = require('core/fields/Field_Layers')
local Field_Collision = require('core/fields/Field_Collision')

-- Alias
local max = math.max
local mathf = math.field

local Field = Field_Layers:inherit(Field_Collision)

-------------------------------------------------------------------------------
-- Object Tile Access
-------------------------------------------------------------------------------

-- Return the Object Tile given the coordinates.
-- @param(x : number) the x coordinate
-- @param(y : number) the y coordinate
-- @param(z : number) the layer's height
-- @ret(ObjectTile) the tile in the coordinates (nil of out of bounds)
function Field:getObjectTile(x, y, z)
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
function Field:getObjectTileFromTransition(t)
  return self:getObjectTile(t.tileX + 1, t.tileY + 1, t.height)
end

-- Returns a iterator that navigates through all object tiles.
-- @ret(function) the grid iterator
function Field:gridIterator()
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
-- Tile Properties
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

-- Checks if three given tiles are collinear.
-- @param(tile1 ... tile3 : ObjectTile) the tiles to check
-- @ret(boolean) true if collinear, false otherwise
function Field:isCollinear(tile1, tile2, tile3)
  return tile1.layer.height - tile2.layer.height == tile2.layer.height - tile3.layer.height and 
    mathf.isCollinear(tile1.x, tile1.y, tile2.x, tile2.y, tile3.x, tile3.y)
end

return Field
