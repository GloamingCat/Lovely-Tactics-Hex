
--[[===============================================================================================

TerrainLayer
---------------------------------------------------------------------------------------------------
A TerrainLayer is a matrix of TerrainTiles.
There may be more then one TerrainLayer in the field per height.

=================================================================================================]]

-- Imports
local TerrainTile = require('core/fields/TerrainTile')

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
      local id = self.grid[i][j].id
      self.grid[i][j].id = -1
      self.grid[i][j]:setTerrain(id)
    end
  end
end

return TerrainLayer
