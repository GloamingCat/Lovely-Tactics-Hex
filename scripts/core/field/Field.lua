
--[[===============================================================================================

Field
---------------------------------------------------------------------------------------------------
A class that stores the layers of tiles in the field and provides general grid information.

=================================================================================================]]

-- Imports
local FiberList = require('core/fiber/FiberList')
local ObjectLayer = require('core/field/ObjectLayer')

-- Alias
local copyTable = util.table.deepCopy
local isCollinear = math.field.isCollinear
local max = math.max
local pixelCenter = math.field.pixelCenter
local pixelBounds = math.field.pixelBounds

local Field = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(id : number) Field ID.
-- @param(name : string) Field name.
-- @param(sizeX : number) Field width.
-- @param(sizeY : number) Field length.
-- @param(maxH : number) Field's maximum tile height.
function Field:init(id, name, sizeX, sizeY, maxH)
  self.id = id
  self.name = name
  self.sizeX = sizeX
  self.sizeY = sizeY
  self.terrainLayers = {}
  self.objectLayers = {}
  for i = 1, maxH do
    self.terrainLayers[i] = {}
    self.objectLayers[i] = ObjectLayer(sizeX, sizeY, i)
  end
  self.minh, self.maxh = 1, maxH
  self.centerX, self.centerY = pixelCenter(sizeX, sizeY)
  self.minx, self.miny, self.maxx, self.maxy = pixelBounds(self)
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

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
-- Gets field prefs data that are saved.
-- @ret(table)
function Field:getPersistentData()
  local script = self.loadScript
  if script then
      script = {
        name = script.name,
        global = script.global,
        block = script.block,
        wait = script.wait,
        tags = script.tags,
        vars = script.vars }
  end
  return {
    images = FieldManager.renderer:getImageData(),
    loadScript = script,
    bgm = self.bgm,
    vars = self.vars }
end
-- Gets size in tiles.
-- @ret(number) Size X of field.
-- @ret(number) Size Y of field.
-- @ret(number) Maximum height of field.
function Field:getSize()
  return self.sizeX, self.sizeY, self.maxh
end

---------------------------------------------------------------------------------------------------
-- Object Tile Access
---------------------------------------------------------------------------------------------------

-- Return the Object Tile given the coordinates.
-- @param(x : number) The x coordinate.
-- @param(y : number) The y coordinate.
-- @param(z : number) The layer's height.
-- @ret(ObjectTile) The tile in the coordinates (nil of out of bounds).
function Field:getObjectTile(x, y, z)
  if self.objectLayers[z] and self.objectLayers[z].grid[x] then
    return self.objectLayers[z].grid[x][y]
  end
  return nil
end
-- Returns a iterator that navigates through all object tiles.
-- @ret(function) The grid iterator.
function Field:gridIterator()
  local maxl = self.maxh
  local i, j, l = 1, 0, self.minh
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
      j, i = 1, i + 1
      if i <= self.sizeX then
        return layer.grid[i][j]
      else
        i, l = 1, l + 1
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
-- @param(x : number) The x in tiles.
-- @param(y : number) The y in tiles.
-- @param(height : number) The layer height.
-- @ret(number) The max of the move costs.
function Field:getMoveCost(x, y, height)
  local cost = 0
  local layers = self.terrainLayers[height]
  for _, layer in ipairs(layers) do
    cost = max(cost, layer.grid[x][y].moveCost)
  end
  return cost
end
-- Gets the list of all terrain tiles with status effects in the given coordinates.
-- @param(x : number) The x in tiles.
-- @param(y : number) The y in tiles.
-- @param(height : number) The layer height.
-- @ret(table) Array of terrain tiles.
function Field:getTerrainStatus(x, y, height)
  local s = {}
  local layers = self.terrainLayers[height]
  for _, layer in ipairs(layers) do
    local t = layer.grid[x][y]
    if t.data and t.data.statusID >= 0 then
      s[#s + 1] = t.data
    end
  end
  return s
end
-- Gets the list of sounds of the top terrain with the given coordinates.
-- @param(x : number) The x in tiles.
-- @param(y : number) The y in tiles.
-- @param(height : number) The layer height.
-- @ret(table) Array of sounds.
function Field:getTerrainSounds(x, y, height)
  local layers = self.terrainLayers[height]
  for l = #layers, 1, -1 do
    local tile = layers[l].grid[x][y]
    if tile.data then
      return tile.data.sounds
    end
  end
  return nil
end
-- Checks if three given tiles are collinear.
-- @param(tile1 ... tile3 : ObjectTile) The tiles to check.
-- @ret(boolean) True if collinear, false otherwise.
function Field:isCollinear(tile1, tile2, tile3)
  return tile1.layer.height - tile2.layer.height == tile2.layer.height - tile3.layer.height and 
    isCollinear(tile1.x, tile1.y, tile2.x, tile2.y, tile3.x, tile3.y)
end

---------------------------------------------------------------------------------------------------
-- Collision
---------------------------------------------------------------------------------------------------

-- Checks if an object collides with something in the given point.
-- @param(object : Object) The object to check.
-- @param(origx : number) The origin x in tiles.
-- @param(origy : number) The origin y in tiles.
-- @param(origh : number) The origin height in tiles.
-- @param(destx : number) The destination x in tiles.
-- @param(desty : number) The destination y in tiles.
-- @param(desth : number) The destination height in tiles.
-- @ret(number) The collision type: 
--  nil => none, 0 => border, 1 => terrain, 2 => obstacle, 3 => character
function Field:collisionXYZ(obj, origx, origy, origh, destx, desty, desth)
  if self:exceedsBorder(destx, desty) then
    return 0
  end
  local layer = self.objectLayers[desth]
  if layer == nil then
    return 0
  end
  local tile = self:getObjectTile(destx, desty, desth)
  if not tile:hasBridgeFrom(obj, origx, origy, origh) and 
      self:collidesTerrain(destx, desty, desth) then
    return 1
  end
  if tile:collidesObstacleFrom(obj, origx, origy, origh) then
    return 2
  elseif tile:collidesCharacter(obj) then
    return 3
  end
  return nil
end
-- Checks if an object collides with something in the given point.
-- @param(object : Object) The object to check.
-- @param(origCoord : Vector) The origin coordinates in tiles.
-- @param(destCoord : Vector) The destination coordinates in tiles.
-- @ret(number) The collision type:
--  nil => none, 0 => border, 1 => terrain, 2 => obstacle, 3 => character
function Field:collision(object, origCoord, destCoord)
  local ox, oy, oh = origCoord:coordinates()
  return self:collisionXYZ(object, ox, oy, oh, destCoord:coordinates())
end

---------------------------------------------------------------------------------------------------
-- Especific Collisions
---------------------------------------------------------------------------------------------------

-- Check a position exceeds border limits.
-- @param(x : number) The tile x.
-- @param(y : number) The tile y.
-- @ret(boolean) True if exceeds, false otherwise.
function Field:exceedsBorder(x, y)
  return x < 1 or y < 1 or x > self.sizeX or y > self.sizeY
end
-- Check if collides with terrains in the given coordinates.
-- @param(x : number) The coordinate x of the tile.
-- @param(y : number) The coordinate y of the tile.
-- @param(h : number) The height of the tile.
-- @ret(boolean) True if collides, false otherwise.
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
    if tile.data ~= nil then
      if tile.data.passable == false then
        return true
      else
        noGround = false
      end
    end
  end
  return noGround
end
-- Check if collides with obstacles.
-- @param(object : Object) The object to check collision.
-- @param(origx : number) The object's origin x in tiles.
-- @param(origy : number) The object's origin y in tiles.
-- @param(origh : number) The object's origin height in tiles.
-- @param(tile : ObjectTile) The destination tile.
-- @ret(boolean) True if collides, false otherwise.
function Field:collidesObstacle(object, origx, origy, origh, tile)
  return tile:collidesObstacle(origx, origy, object)
end
-- Checks if there's any terrain in the given coordinates.
-- @param(x : number) Tile x coordinate.
-- @param(y : number) Tile y coordinate.
-- @param(h : number) Layer's height.
-- @ret(boolean) True if there is a ground to step over, false otherwise.
function Field:isGrounded(x, y, h)
  local layerList = self.terrainLayers[h]
  if layerList ~= nil then
    for i = 1, #layerList do
      local layer = layerList[i]
      local tile = layer.grid[x][y]
      if tile.data ~= nil then
        return true
      end
    end
  end
  return false
end

return Field
