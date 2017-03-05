
local TerrainTile = require('core/fields/TerrainTile')

--[[
@module

A TerrainLayer is a matrix of TerrainTiles.
There may be more then one TerrainLayer in the field per height.

]]

local TerrainLayer = require('core/class'):new()

-- @param(data : table) the layer's data from field's file
-- @param(sizeX : number) the field's width
-- @param(sizeY : number) the field's length
-- @param(tilesetData : table) the data of the field's tileset
-- @param(order : number) the rendering order for the layer 
--  (used specially when there are more than one layer with same height)
function TerrainLayer:init(data, sizeX, sizeY, order, tileset)
  self.grid = {}
  self.order = order
  self.height = data.info.height
  -- Initializes all tiles
  for i = 1, sizeX do
    self.grid[i] = {}
    for j = 1, sizeY do
      local id = data.grid[i][j]
      if id >= 0 then
        id = tileset.terrains[id + 1].id
      end
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
