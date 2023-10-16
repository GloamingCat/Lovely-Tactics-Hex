
--[[===============================================================================================

@classmod Obstacle
---------------------------------------------------------------------------------------------------
An Obstacle is a static object stored in the tile. 
It may be passable or not, and have an image or not.

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local Object = require('core/objects/Object')

-- Constants
local neighborShift = math.field.fullNeighborShift

-- Class table.
local Obstacle = class(Object)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

-- @tparam table data The obstacle's data from tileset file.
-- @tparam table tileData The data about ramp and collision.
-- @tparam ObjectTile initTile The object this tile is in.
-- @tparam table group The group this obstacle is part of.
function Obstacle:init(data, tileData, initTile, sprite, group)
  local x, y, z = initTile.center:coordinates()
  Object.init(self, data, Vector(x, y, z))
  self.type = 'obstacle'
  self.group = group
  self.sprite = sprite
  self.collisionHeight = tileData.height
  self.ramp = tileData.mode == 1
  self.bridge = tileData.mode == 2
  self:initNeighbors(tileData.neighbors)
  self:addToTiles()
end
--- Creates neighborhood.
-- @tparam table neighbors The table of booleans indicating passability.
function Obstacle:initNeighbors(neighbors)
  self.passability = {}
  self.passability[0] = {}
  self.passability[0][0] = false
  for i, n in ipairs(neighborShift) do
    if self.passability[n.x] == nil then
      self.passability[n.x] = {}
    end
    self.passability[n.x][n.y] = neighbors[i]
  end
end

-- ------------------------------------------------------------------------------------------------
-- Collision
-- ------------------------------------------------------------------------------------------------

--- Checks if the object is passable from the given direction.
-- @tparam number dx The direction in axis x.
-- @tparam number dy The direction in axis y.
-- @tparam Object obj The object which is trying to pass through this obstacle (optional).
function Obstacle:isPassable(dx, dy, obj)
  if self == obj then
    return true
  end
  if self.passability[dx] == nil then
    return false
  end
  return self.passability[dx][dy] == true
end
--- Overrides Object:getHeight.
function Obstacle:getHeight(x, y)
  return self.collisionHeight
end

-- ------------------------------------------------------------------------------------------------
-- Tiles
-- ------------------------------------------------------------------------------------------------

--- Overrides Object:addToTiles.
function Obstacle:addToTiles(tiles)
  local tile = tiles and tiles[1] or self:getTile()
  tile.obstacleList:add(self)
  if not self.ramp or self.collisionHeight == 0 then
    return
  end
  local layerNeighbors = self:getPassableNeighbors(tile)
  local topTile = self:getTopTile(tile)
  for r = 1, #layerNeighbors do
    topTile.rampNeighbors:add(layerNeighbors[r])
    layerNeighbors[r].rampNeighbors:add(topTile)
  end
end
--- Overrides Object:removeFromTiles.
function Obstacle:removeFromTiles(tiles)
  local tile = tiles and tiles[1] or self:getTile()
  tile.obstacleList:removeElement(self)
  if not self.ramp then
    return
  end
  local layerNeighbors = self:getPassableNeighbors(tile)
  local topTile = self:getTopTile(tile)
  for r = 1, #layerNeighbors do
    topTile.rampNeighbors:removeElement(layerNeighbors[r])
    layerNeighbors[r].rampNeighbors:removeElement(topTile)
  end
end
--- Gets an array of tiles to each the obstacle's ramp transits.
-- @treturn table Array of tiles if the obstacle is a ramp, nil if it's not.
function Obstacle:getPassableNeighbors(tile)
  tile = tile or self:getTile()
  local field = FieldManager.currentField
  local height = tile.layer.height
  local neighbors = {}
  for _, n in ipairs(neighborShift) do
    local t = field:getObjectTile(n.x + tile.x, n.y + tile.y, height)
    if t and self:isPassable(n.x, n.y) then
      neighbors[#neighbors + 1] = t
    end
  end
  return neighbors
end
--- Gets the tile on the top on the obstacle, according to its collision height.
-- @treturn ObjectTile
function Obstacle:getTopTile(tile)
  return FieldManager.currentField:getObjectTile(tile.x, tile.y, 
    self.collisionHeight + tile.layer.height)
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

-- @treturn string String representation (for debugging).
function Obstacle:__tostring()
  return 'Obstacle ' .. self.name .. ' ' .. tostring(self.position)
end

return Obstacle
