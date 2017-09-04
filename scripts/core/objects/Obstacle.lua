
--[[===============================================================================================

Obstacle
---------------------------------------------------------------------------------------------------
An Obstacle is a static object stored in the tile. 
It may be passable or not, and have an image or not.

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local Object = require('core/objects/Object')

-- Alias
local tile2Pixel = math.field.tile2Pixel

-- Constants
local pph = Config.grid.pixelsPerHeight

local Obstacle = class(Object)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(data : table) the obstacle's data from tileset file
-- @param(tileData : table) the data about ramp and collision
-- @param(initTile : ObjectTile) the object this tile is in
-- @param(group : table) the group this obstacle is part of
function Obstacle:init(data, tileData, initTile, group)
  local x, y, z = tile2Pixel(initTile:coordinates())
  Object.init(self, data, Vector(x, y, z))
  self.type = 'obstacle'
  self.group = group
  self.sprite = group.sprite
  self.collisionHeight = tileData.height
  initTile.obstacleList:add(self)
  self:initializeNeighbors(tileData.neighbors)
  self:setXYZ(x, y, z)
  self:addToTiles()
end
-- Creates neighborhood.
-- @param(neighbors : table) the table of booleans indicating passability
function Obstacle:initializeNeighbors(neighbors)
  self.neighbors = {}
  local function addNeighbor(x, y, i)
    if self.neighbors[x] == nil then
      self.neighbors[x] = {}
    end
    self.neighbors[x][y] = neighbors[i]
  end
  local neighborShift = math.field.fullNeighborShift
  for i, n in ipairs(neighborShift) do
    addNeighbor(n.x, n.y, i)
  end
  addNeighbor(0, 0, #neighborShift + 1)
end

---------------------------------------------------------------------------------------------------
-- Collision
---------------------------------------------------------------------------------------------------

-- Checks if the object is passable from the given direction.
-- @param(dx : number) the direction in axis x
-- @param(dy : number) the direction in axis y
-- @param(obj : Object) the object which is trying to pass through this obstacle (optional)
function Obstacle:isPassable(dx, dy, obj)
  if self == obj then
    return true
  end
  if self.neighbors[dx] == nil then
    return false
  end
  return self.neighbors[dx][dy] == true
end
-- Override.
function Obstacle:getHeight(x, y)
  return self.collisionHeight
end

---------------------------------------------------------------------------------------------------
-- Tiles
---------------------------------------------------------------------------------------------------

-- Overrides Object:addToTiles.
function Obstacle:addToTiles()
  self:getTile().obstacleList:add(self)
end
-- Overrides Object:removeFromTiles.
function Obstacle:removeFromTiles()
  self:getTile().obstacleList:removeElement(self)
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Converting to string.
function Obstacle:__tostring()
  return 'Obstacle ' .. self.name .. ' ' .. tostring(self.position)
end

return Obstacle
