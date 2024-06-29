
-- ================================================================================================

--- A class that stores the layers of tiles and provides general grid information.
---------------------------------------------------------------------------------------------------
-- @fieldmod Field

-- ================================================================================================

-- Imports
local FiberList = require('core/fiber/FiberList')
local List = require('core/datastruct/List')
local ObjectLayer = require('core/field/ObjectLayer')

-- Alias
local copyTable = util.table.deepCopy
local isCollinear = math.field.isCollinear
local max = math.max
local pixelCenter = math.field.pixelCenter
local pixelBounds = math.field.pixelBounds

-- Class table.
local Field = class()

-- ------------------------------------------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------------------------------------------

--- Collision types.
-- @enum Collision
-- @field BORDER Code for when a character collides with the field's borders. Equals to 0.
-- @field TERRAIN Code for when a character collides with a non-passable terrain. Equals to 1.
-- @field OBSTACLE Code for when a character collides with a non-passable object. Equals to 2.
-- @field CHARACTER Code for when a character collides with another character. Equals to 3.
Field.Collision = {
  BORDER = 0,
  TERRAIN = 1,
  OBSTACLE = 2,
  CHARACTER = 3
}

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam number id Field ID.
-- @tparam string name Field name.
-- @tparam number sizeX Field width.
-- @tparam number sizeY Field length.
-- @tparam number maxH Field's maximum tile height.
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
  self.fiberList = FiberList()
  self.blockingFibers = List()
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Called when this interactable is created.
-- @coroutine
-- @tparam boolean loading True if the field was loaded now, false if loaded from save.
-- @treturn boolean Whether the load scripts were executed or not.
function Field:onLoad(loading)
  local script = self.loadScript
  if not script or script.name == '' then
    return false
  end
  if script.vars.loading or loading then
    script.vars.loading = script.vars.loading or loading
    local fiberList = (script.global and FieldManager or self).fiberList
    local fiber = fiberList:forkFromScript(script)
    if script.wait then
      fiber:waitForEnd()
    end
  end
  return true
end
--- Called when this interactable is created.
-- @coroutine
-- @tparam[opt] string exit The key of the object that originated the exit transition.
-- @treturn boolean Whether the exit scripts were executed or not.
function Field:onExit(exit)
  local script = self.exitScript
  if not script or script.name == '' then
    return false
  end
  if script.vars.exit or exit then
    local fiberList = (script.global and FieldManager or self).fiberList
    local fiber = fiberList:forkFromScript(script)
    script.vars.exit = script.vars.exit or exit
    if script.wait then
      fiber:waitForEnd()
    end
  end
  return true
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Updates all ObjectTiles and TerrainTiles in field's layers.
-- @tparam number dt The duration of the previous frame.
function Field:update(dt)
  self.fiberList:update(dt)
  for l = self.minh, self.maxh do
    local layer = self.objectLayers[l]
    for i = 1, self.sizeX do
      for j = 1, self.sizeY do
        layer.grid[i][j]:update(dt)
      end
    end
    local layerList = self.terrainLayers[l]
    for k = 1, #layerList do
      layer = layerList[k]
      for i = 1, self.sizeX do
        for j = 1, self.sizeY do
          layer.grid[i][j]:update(dt)
        end
      end
    end
  end
end
--- Gets field prefs data that are saved.
-- No deep copy is made.
-- @treturn table A new table containing the field's persistent data.
function Field:getPersistentData()
  local script = self.loadScript
  if script then
      script = {
        name = script.name,
        global = script.global,
        block = script.block,
        wait = script.wait,
        tags = script.tags,
        args = script.args,
        vars = script.vars }
  end
  return {
    images = FieldManager.renderer:getImageData(),
    loadScript = script,
    bgm = self.bgm,
    vars = self.vars }
end
--- Gets size in tiles.
-- @treturn number Size X of field.
-- @treturn number Size Y of field.
-- @treturn number Maximum height of field.
function Field:getSize()
  return self.sizeX, self.sizeY, self.maxh
end
--- Destroys fiber list and tiles.
function Field:destroy()
  self.fiberList:destroy()
  for l = self.minh, self.maxh do
    local layer = self.objectLayers[l]
    for i = 1, self.sizeX do
      for j = 1, self.sizeY do
        layer.grid[i][j]:destroy()
      end
    end
    local layerList = self.terrainLayers[l]
    for k = 1, #layerList do
      layer = layerList[k]
      for i = 1, self.sizeX do
        for j = 1, self.sizeY do
          layer.grid[i][j]:destroy()
        end
      end
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Object Tile Access
-- ------------------------------------------------------------------------------------------------

--- Return the Object Tile given the coordinates.
-- @tparam number x The x coordinate.
-- @tparam number y The y coordinate.
-- @tparam number z The layer's height.
-- @treturn ObjectTile The tile in the coordinates (nil of out of bounds).
function Field:getObjectTile(x, y, z)
  if self.objectLayers[z] and self.objectLayers[z].grid[x] then
    return self.objectLayers[z].grid[x][y]
  end
  return nil
end
--- Returns a iterator that navigates through all object tiles.
-- @treturn function The grid iterator.
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
--- Gets the tile that the mouse is over.
-- @treturn ObjectTile The tile which the mouse cursor is over.
function Field:getHoveredTile()
  for l = self.maxh, self.minh, -1 do
    local x, y = InputManager.mouse:fieldCoord(l)
    if not self:exceedsBorder(x, y) and self:isGrounded(x, y, l) then
      return self:getObjectTile(x, y, l)
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Tile Properties
-- ------------------------------------------------------------------------------------------------

--- Gets the move cost in the given coordinates.
-- @tparam Character char The character walking.
-- @tparam number x The x in tiles.
-- @tparam number y The y in tiles.
-- @tparam number height The layer height.
-- @treturn number The max of the move costs.
function Field:getMoveCost(char, x, y, height)
  local maxCost = 0
  local layers = self.terrainLayers[height]
  for _, layer in ipairs(layers) do
    local cost = layer.grid[x][y]:getMoveCost(char)
    maxCost = max(maxCost, cost)
  end
  return maxCost
end
--- Gets the list of all terrain tiles with status effects in the given coordinates.
-- @tparam number x The x in tiles.
-- @tparam number y The y in tiles.
-- @tparam number height The layer height.
-- @treturn table Array of terrain tiles.
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
--- Gets the list of sounds of the top terrain with the given coordinates.
-- @tparam number x The x in tiles.
-- @tparam number y The y in tiles.
-- @tparam number height The layer height.
-- @treturn table Array of sounds.
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
--- Checks if three given tiles are collinear.
-- @tparam ObjectTile tile1 First tile to check.
-- @tparam ObjectTile tile2 Second tile to check.
-- @tparam ObjectTile tile3 Third tile to check.
-- @treturn boolean True if collinear, false otherwise.
function Field:isCollinear(tile1, tile2, tile3)
  return tile1.layer.height - tile2.layer.height == tile2.layer.height - tile3.layer.height and 
    isCollinear(tile1.x, tile1.y, tile2.x, tile2.y, tile3.x, tile3.y)
end

-- ------------------------------------------------------------------------------------------------
-- Collision
-- ------------------------------------------------------------------------------------------------

--- Checks if an object collides with something in the given point.
-- @tparam Object obj The object to check.
-- @tparam number origX The origin x in tiles.
-- @tparam number origY The origin y in tiles.
-- @tparam number origH The origin height in tiles.
-- @tparam number destX The destination x in tiles.
-- @tparam number destY The destination y in tiles.
-- @tparam number destH The destination height in tiles.
-- @treturn Collision The collision type, if any.
function Field:collisionXYZ(obj, origX, origY, origH, destX, destY, destH)
  if self:exceedsBorder(destX, destY) then
    return 0
  end
  local layer = self.objectLayers[destH]
  if layer == nil then
    return 0
  end
  local tile = self:getObjectTile(destX, destY, destH)
  if not tile:hasBridgeFrom(obj, origX, origY, origH) and 
      self:collidesTerrain(destX, destY, destH) then
    return 1
  end
  if tile:collidesObstacleFrom(obj, origX, origY, origH) then
    return 2
  elseif tile:collidesCharacter(obj) then
    return 3
  end
  return nil
end
--- Checks if an object collides with something in the given point.
-- @tparam Object object The object to check.
-- @tparam Vector origCoord The origin coordinates in tiles.
-- @tparam Vector destCoord The destination coordinates in tiles.
-- @treturn Collision The collision type, if any.
function Field:collision(object, origCoord, destCoord)
  local ox, oy, oh = origCoord:coordinates()
  return self:collisionXYZ(object, ox, oy, oh, destCoord:coordinates())
end

-- ------------------------------------------------------------------------------------------------
-- Especific Collisions
-- ------------------------------------------------------------------------------------------------

--- Check a position exceeds border limits.
-- @tparam number x The tile x.
-- @tparam number y The tile y.
-- @treturn boolean True if exceeds, false otherwise.
function Field:exceedsBorder(x, y)
  return x < 1 or y < 1 or x > self.sizeX or y > self.sizeY
end
--- Check if collides with terrains in the given coordinates.
-- @tparam number x The coordinate x of the tile.
-- @tparam number y The coordinate y of the tile.
-- @tparam number h The height of the tile.
-- @treturn boolean True if collides, false otherwise.
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
--- Check if collides with obstacles.
-- @tparam Object object The object to check collision.
-- @tparam number origx The object's origin x in tiles.
-- @tparam number origy The object's origin y in tiles.
-- @tparam number origh The object's origin height in tiles.
-- @tparam ObjectTile tile The destination tile.
-- @treturn boolean True if collides, false otherwise.
function Field:collidesObstacle(object, origx, origy, origh, tile)
  return tile:collidesObstacle(origx, origy, object)
end
--- Checks if there's any terrain in the given coordinates.
-- @tparam number x Tile x coordinate.
-- @tparam number y Tile y coordinate.
-- @tparam number h Layer's height.
-- @treturn boolean True if there is a ground to step over, false otherwise.
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
-- For debugging.
function Field:__tostring()
  return 'Field: [' .. self.id .. '] ' .. self.name
end

return Field
