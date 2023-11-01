
-- ================================================================================================

--- A matrix of `TerrainTile`s.
-- There may be more than one TerrainLayer in the field per height.
---------------------------------------------------------------------------------------------------
-- @fieldmod TerrainLayer

-- ================================================================================================

-- Imports
local TerrainTile = require('core/field/TerrainTile')

-- Class table.
local TerrainLayer = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam table data The layer's data from field's file.
-- @tparam number sizeX The field's grid width.
-- @tparam number sizeY The field's grid height.
-- @tparam number order The rendering order for the layer
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

-- ------------------------------------------------------------------------
-- Auto Tile
-- ------------------------------------------------------------------------

--- Checks if two grid cells have the same terrain type (for auto tiling).
-- @tparam number i1 Grid x of first cell.
-- @tparam number j1 Grid y of first cell.
-- @tparam number i2 Grid x of second cell.
-- @tparam number j2 Grid y of second cell.
-- @treturn boolean True if two tiles must be connected with auto tiling.
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
