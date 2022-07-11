
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

-- Constructor.
-- @param(data : table) The layer's data from field's file.
-- @param(sizeX : number) The field's grid width.
-- @param(sizeY : number) The field's grid height.
-- @param(order : number) The rendering order for the layer
--  (used for correct depth when there are more than one layer with same height).
function TerrainLayer:init(data, sizeX, sizeY, order)
  self.grid = {}
  self.order = order
  self.height = data.info.height
  self.sizeX = sizeX
  self.sizeY = sizeY
  self.noAuto = data.info.noAuto
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

-- Checks if two grid cells have the same terrain type (for auto tiling).
-- @param(i1 : number) Grid x of first cell.
-- @param(j1 : number) Grid y of first cell.
-- @param(i2 : number) Grid x of second cell.
-- @param(j2 : number) Grid y of second cell.
-- @ret(boolean) True if two tiles must be connected with auto tiling.
function TerrainLayer:sameType(i1, j1, i2, j2)
  if self.noAuto then
    return true
  end
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
