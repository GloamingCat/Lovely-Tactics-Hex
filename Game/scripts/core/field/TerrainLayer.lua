
--[[===============================================================================================

TerrainLayer
---------------------------------------------------------------------------------------------------
A TerrainLayer is a matrix of TerrainTiles.
There may be more then one TerrainLayer in the field per height.

=================================================================================================]]

-- Imports
local TerrainTile = require('core/field/TerrainTile')

local TerrainLayer = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(data : table) the layer's data from field's file
-- @param(sizeX : number) the field's width
-- @param(sizeY : number) the field's length
-- @param(order : number) the rendering order for the layer 
--  (used specially when there are more than one layer with same height)
function TerrainLayer:init(data, sizeX, sizeY, order)
  self.grid = {}
  self.order = order
  self.height = data.info.height
  -- Initializes all tiles
  for i = 1, sizeX do
    self.grid[i] = {}
    for j = 1, sizeY do
      local id = data.grid[i][j]
      self.grid[i][j] = TerrainTile(self, i, j, order, id)
    end
  end
  -- Sets tiles' terrains
  for i = 1, sizeX do
    for j = 1, sizeY do
      local id = data.grid[i][j]
      self.grid[i][j].data = nil
      self.grid[i][j]:setTerrain(id)
    end
  end
end

---------------------------------------------------------------------------
-- Auto Tile
---------------------------------------------------------------------------

function TerrainLayer:sameType(i1, j1, i2, j2)
  if (i1 < 1 or i1 > #self.grid or i2 < 1 or i2 > #self.grid) then
    return true
  end
  if (j1 < 1 or j1 > #self.grid[i1] or j2 < 1 or j2 > #self.grid[i2]) then
    return true
  end
  local tile1 = self.grid[i1][j1].data
  local tile2 = self.grid[i2][j2].data
  if tile1 and tile2 then
    return tile1.id == tile2.id
  else
    return false
  end
end

return TerrainLayer
