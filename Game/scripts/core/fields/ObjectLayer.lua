
--[[===============================================================================================

ObjectLayer
---------------------------------------------------------------------------------------------------
An ObjectLayer is a matrix of ObjectTiles.
There's only one ObjectLayer in the field per height.

=================================================================================================]]

-- Imports
local ObjectTile = require('core/fields/ObjectTile')
local Obstacle = require('core/objects/Obstacle')
local Sprite = require('core/graphics/Sprite')

-- Alias
local floor = math.floor
local newQuad = love.graphics.newQuad

local ObjectLayer = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(sizeX : number) the field's width
-- @param(sizeY : number) the field's length
-- @param(height : number) the layer's height
function ObjectLayer:init(sizeX, sizeY, height, defaultRegion)
  self.sizeX = sizeX
  self.sizeY = sizeY
  self.height = height
  self.grid = {}
  for i = 1, sizeX do
    self.grid[i] = {}
    for j = 1, sizeY do
      self.grid[i][j] = ObjectTile(self, i, j, defaultRegion)
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Merge
---------------------------------------------------------------------------------------------------

-- Creates all obstacles in data and adds them to the tiles.
-- @param(layerData : table) the layer's data from field's file
-- @param(tileset : table) the tileset's data from file
function ObjectLayer:mergeObstacles(layerData, tileset)
  for i = 1, self.sizeX do
    for j = 1, self.sizeY do
      local id = layerData.grid[i][j]
      if id >= 0 then
        local obstacleData = Database.obstacles[id + 1]
        local group = {}
        -- Graphics
        if obstacleData.quad.imagePath ~= '' then
          local texture = love.graphics.newImage('images/' .. obstacleData.quad.imagePath)
          local x, y = obstacleData.quad.x, obstacleData.quad.y
          local w, h = obstacleData.quad.width, obstacleData.quad.height
          local quad = newQuad(x, y, w, h, texture:getWidth(), texture:getHeight())
          group.sprite = Sprite(FieldManager.renderer, texture, quad)
          group.sprite:setTransformation(obstacleData.transform)
        end
        -- Collision tiles
        for k = 1, #obstacleData.tiles do
          local tileData = obstacleData.tiles[k]
          local tile = self.grid[i + tileData.dx][j + tileData.dy]
          local obstacle = Obstacle(obstacleData, tileData, tile, group)
          group[k] = obstacle
        end
      end
    end
  end
end
-- Add all regions IDs to the tiles.
-- @param(layerData : table) the layer's data from field's file
-- @param(tileset : table) the tileset's data from file
function ObjectLayer:mergeRegions(layerData, tileset)
  for i = 1, self.sizeX do
    for j = 1, self.sizeY do
      local id = layerData.grid[i][j]
      if id >= 0 then
        self.grid[i][j].regionList:add(id)
      end
    end
  end
end

return ObjectLayer
