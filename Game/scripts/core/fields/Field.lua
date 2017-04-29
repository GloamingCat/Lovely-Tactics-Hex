
--[[===============================================================================================

Field
---------------------------------------------------------------------------------------------------
The class implements methods to check collisions.

=================================================================================================]]

-- Imports
local TerrainLayer = require('core/fields/TerrainLayer')
local ObjectLayer = require('core/fields/ObjectLayer')

-- Alias
local max = math.max
local min = math.min
local mathf = math.field

local Field = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(data : table) the data from file
function Field:init(data)
  self.id = data.id
  self.sizeX = data.sizeX
  self.sizeY = data.sizeY
  if data.prefs.onStart.path ~= nil then
    self.startScript = data.prefs.onStart
  end
  self.terrainLayers = {}
  self.objectLayers = {}
  if data.prefs.defaultRegion >= 0 then
    self.defaultRegion = data.prefs.defaultRegion
  end
  self.minh = 100
  self.maxh = 0
  self.tileset = Database.tilesets[data.prefs.tilesetID + 1]
  for i, layerData in ipairs(data.layers) do
    self.maxh = max(layerData.info.height, self.maxh)
    self.minh = min(layerData.info.height, self.minh)
  end
  for i = self.minh, self.maxh do
    self.terrainLayers[i] = {}
    self.objectLayers[i] = ObjectLayer(self.sizeX, self.sizeY, i, self.defaultRegion)
  end
  self.centerX, self.centerY = math.field.pixelCenter(self)
  self.minx, self.miny, self.maxx, self.maxy = math.field.pixelBounds(self)
end

-- Updates all ObjectTiles and TerrainTiles in field's layers.
function Field:update()
  for l = self.minh, self.maxh do
    local layer = self.objectLayers[l]
    for i = 1, self.sizeX do
      for j = 1, self.sizeY do
        layer.grid[i][j]:update()
      end
    end
    local layerList = self.terrainLayers[l]
    for k = 1, #layerList do
      layer = layerList[k]
      for i = 1, self.sizeX do
        for j = 1, self.sizeY do
          layer.grid[i][j]:update()
        end
      end
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Object Tile Access
---------------------------------------------------------------------------------------------------

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

---------------------------------------------------------------------------------------------------
-- Tile Properties
---------------------------------------------------------------------------------------------------

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

---------------------------------------------------------------------------------------------------
-- Layers
---------------------------------------------------------------------------------------------------

-- Merges layers' data.
-- @param(layers : table) an array of layer data
function Field:mergeLayers(layers)
  for i,layerData in ipairs(layers) do
    local t = layerData.info.type
    if t == 0 then
      self:addTerrainLayer(layerData)
    elseif t == 1 then
      self:addObstacleLayer(layerData)
    elseif t == 2 then
      self:addCharacterLayer(layerData)
    elseif t == 3 then
      self:addRegionLayer(layerData)
    elseif t == 4 then
      self:addBattleTypeLayer(layerData)
    elseif t == 5 then
      self:addPartyLayer(layerData)
    end
  end
end

-- Creates a new TerrainLayer. 
-- All layers are stored by height.
-- @param(layerData : table) the data from field's file
-- @param(tileset : table) the tileset's data from file
function Field:addTerrainLayer(layerData)
  local list = self.terrainLayers[layerData.info.height]
  local order = #list
  local layer = TerrainLayer(layerData, self.sizeX, self.sizeY, order, self.tileset)
  list[order + 1] = layer
end

-- Merges the obstacle layers. If there's no layer in that height, creates a new one.
-- All layers are stored by height.
-- @param(layerData : table) the data from field's file
function Field:addObstacleLayer(layerData)
  self.objectLayers[layerData.info.height]:mergeObstacles(layerData, self.tileset)
end

-- Merges the character layers. If there's no layer in that height, creates a new one.
-- All layers are stored by height.
-- @param(layerData : table) the data from field's file
function Field:addCharacterLayer(layerData)
  self.objectLayers[layerData.info.height]:mergeCharacters(layerData, self.tileset)
end

-- Merges the region layers. If there's no layer in that height, creates a new one.
-- All layers are stored by height.
-- @param(layerData : table) the data from field's file
function Field:addRegionLayer(layerData)
  self.objectLayers[layerData.info.height]:mergeRegions(layerData, self.tileset)
end

-- Merges the battle tile layers. If there's no layer in that height, creates a new one.
-- All layers are stored by height.
-- @param(layerData : table) the data from field's file
function Field:addBattleTypeLayer(layerData)
  self.objectLayers[layerData.info.height]:mergeBattleTypes(layerData)
end

-- Merges the party layers. If there's no layer in that height, creates a new one.
-- All layers are stored by height.
-- @param(layerData : table) the data from field's file
function Field:addPartyLayer(layerData)
  self.objectLayers[layerData.info.height]:mergeParties(layerData)
end

---------------------------------------------------------------------------------------------------
-- Collision
---------------------------------------------------------------------------------------------------

-- Checks if an object collides with something in the given point.
-- @param(object : Object) the object to check
-- @param(origx : number) the origin x in tiles
-- @param(origy : number) the origin y in tiles
-- @param(origh : number) the origin height in tiles
-- @param(destx : number) the destination x in tiles
-- @param(desty : number) the destination y in tiles
-- @param(desth : number) the destination height in tiles
-- @ret(number) the collision type. 
--  nil => none, 0 => border, 1 => terrain, 2 => obstacle, 3 => character
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
function Field:collision(object, origCoord, destCoord)
  local ox, oy, oz = origCoord:coordinates()
  return self:collision(object, ox, oy, oz, destCoord:coordinates())
end

---------------------------------------------------------------------------------------------------
-- Especific Collisions
---------------------------------------------------------------------------------------------------

-- Check a position exceeds border limits.
-- @param(x : number) tile x
-- @param(y : number) tile y
-- @ret(boolean) true if exceeds, false otherwise
function Field:exceedsBorder(x, y)
  return x < 1 or y < 1 or x > self.sizeX or y > self.sizeY
end

-- Check if collides with terrains in the given coordinates.
-- @param(x : number) the coordinate x of the tile
-- @param(y : number) the coordinate y of the tile
-- @param(h : number) the height of the tile
-- @ret(boolean) true if collides, false otherwise
function Field:collidesTerrain(x, y, h)
  local layerList = self.terrainLayers[h]
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
-- @param(origx : number) the object's origin x in tiles
-- @param(origy : number) the object's origin y in tiles
-- @param(origh : number) the object's origin height in tiles
-- @param(tile : ObjectTile) the destination tile
-- @ret(boolean) true if collides, false otherwise
function Field:collidesObstacle(object, origx, origy, origh, tile)
  return tile:collidesObstacle(origx, origy, object)
end

return Field
