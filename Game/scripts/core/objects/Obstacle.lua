
--[[===========================================================================

Obstacle
-------------------------------------------------------------------------------
An Obstacle is a static object stored in the tile. 
It may be passable or not, and have an image or not.

=============================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local Object = require('core/objects/Object')

-- Alias
local tile2Pixel = math.field.tile2Pixel

-- Constants
local pph = Config.grid.pixelsPerHeight

local Obstacle = class(Object)

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------

-- @param(data : table) the obstacle's data from tileset file
-- @param(tileData : table) the data about ramp and collision
-- @param(group : table) the group this obstacle is part of
local old_init = Obstacle.init
function Obstacle:init(data, tileData, initTile, group)
  local x, y, z = tile2Pixel(initTile:coordinates())
  old_init(self, data, Vector(x, y, z))
  self.type = 'obstacle'
  self.group = group
  self.sprite = group.sprite
  initTile.obstacleList:add(self)
  self:initializeNeighbors(tileData.neighbors)
  if tileData.rampID >= 0 then
    local rampData = Database.ramps[tileData.rampID + 1]
    --self.ramp = Ramp(rampData)
  end
  self:setXYZ(x, y, z)
  self:addToTiles()
end

-- Creates neighborhood.
-- @param(neighbors : table) the table of booleans indicating passability
function Obstacle:initializeNeighbors(neighbors)
  self.neighbors = {}
  for i, n in ipairs(math.field.fullNeighborShift) do
    if self.neighbors[n.x] == nil then
      self.neighbors[n.x] = {}
    end
    self.neighbors[n.x][n.y] = neighbors[i]
  end
end

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

-- Overrides Object:setXYZ.
local old_setXYZ = Obstacle.setXYZ
function Obstacle:setXYZ(x, y, z)
  old_setXYZ(self, x, y, z)
  if self.ramp then
    local h = -(y + z) / pph
    self.ramp:setPosition(x, y)
    self.ramp:setHeight(h)
  end
end

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

-- Converting to string.
function Obstacle:__tostring()
  return 'Obstacle ' .. self.name
end

-------------------------------------------------------------------------------
-- Tiles
-------------------------------------------------------------------------------

-- Overrides Object:addToTiles.
function Obstacle:addToTiles()
  self:getTile().obstacleList:add(self)
end

-- Overrides Object:removeFromTiles.
function Obstacle:removeFromTiles()
  self:getTile().obstacleList:removeElement(self)
end

return Obstacle
