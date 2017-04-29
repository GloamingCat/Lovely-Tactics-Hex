
--[[===========================================================================

ObjectLayer
-------------------------------------------------------------------------------
An ObjectLayer is a matrix of ObjectTiles.
There's only one ObjectLayer in the field per height.

=============================================================================]]

-- Imports
local ObjectTile = require('core/fields/ObjectTile')
local Obstacle = require('core/fields/Obstacle')
local Character = require('core/character/Character')

-- Alias
local floor = math.floor

local ObjectLayer = class()

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

-- Creates all obstacles in data and adds them to the tiles.
-- @param(layerData : table) the layer's data from field's file
-- @param(tileset : table) the tileset's data from file
function ObjectLayer:mergeObstacles(layerData, tileset)
  for i = 1, self.sizeX do
    for j = 1, self.sizeY do
      local id = layerData.grid[i][j]
      if id >= 0 then
        id = tileset.obstacles[id + 1].id
        local obstacleData = Database.obstacles[id + 1]
        local group = {}
        for k = 1, #obstacleData.tiles do
          local tileData = obstacleData.tiles[k]
          local obstacle = Obstacle(obstacleData, tileData)
          obstacle.tile = self.grid[i][j]
          obstacle.tile.obstacleList:add(obstacle)
          obstacle:setPositionToTile(obstacle.tile)
          group[i] = obstacle
        end
      end
    end
  end
end

-- Creates all characters in data and adds them to the tiles.
-- @param(layerData : table) the layer's data from field's file
-- @param(tileset : table) the tileset's data from file
function ObjectLayer:mergeCharacters(layerData, tileset)
  for i = 1, self.sizeX do
    for j = 1, self.sizeY do
      local id = layerData.grid[i][j]
      if id >= 0 then
        local tile = self.grid[i][j]
        local charID = tile:generateCharacterID()
        local characterData = tileset.characters[id + 1]
        local character = Character(charID, characterData)
        character:setPositionToTile(tile)
        character:addToTiles()
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
        id = tileset.regions[id + 1].id
        self.grid[i][j].regionList:add(id)
      end
    end
  end
end

-- Merges battle types.
-- @param(layerData : table) the layer's data from field's file
function ObjectLayer:mergeBattleTypes(layerData)
  for i = 1, self.sizeX do
    for j = 1, self.sizeY do
      local id = layerData.grid[i][j]
      if id >= 0 then
        self.grid[i][j].battlerTypeList:add(id)
      end
    end
  end
end

-- Merges parties.
-- @param(layerData : table) the layer's data from field's file
function ObjectLayer:mergeParties(layerData)
  for i = 1, self.sizeX do
    for j = 1, self.sizeY do
      local id = layerData.grid[i][j]
      if id >= 0 then
        self.grid[i][j].party = id
      end
    end
  end
end

return ObjectLayer
