
--[[===========================================================================

Obstacle
-------------------------------------------------------------------------------
An Obstacle is a static object stored in the tile. 
It may be passable or not, and have an image or not.

=============================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')
local Object = require('core/fields/Object')

-- Constants
local pph = Config.grid.pixelsPerHeight

local Obstacle = Object:inherit()

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------

-- @param(data : table) the obstacle's data from tileset file
-- @param(tileData : table) the data about ramp and collision
-- @param(group : table) the group this obstacle is part of
local old_init = Obstacle.init
function Obstacle:init(data, tileData, group)
  old_init(self, data)
  self.type = 'obstacle'
  self.group = group
  if data.quad.imagePath ~= '' then
    local texture = love.graphics.newImage('images/' .. data.quad.imagePath)
    local x, y = data.quad.x, data.quad.y
    local w, h = data.quad.width, data.quad.height
    local quad = love.graphics.newQuad(x, y, w, h, texture:getWidth(), texture:getHeight())
    self.sprite = Sprite(FieldManager.renderer, texture, quad)
    self.sprite:setTransformation(data.transform)
  end
  self:initializeNeighbors(tileData.neighbors)
  if tileData.rampID >= 0 then
    local rampData = Database.ramps[tileData.rampID + 1]
    self.ramp = Ramp(rampData)
  end
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
-- @ret(string) a string representation
function Obstacle:toString()
  return 'Obstacle ' .. self.name
end

-------------------------------------------------------------------------------
-- Tiles
-------------------------------------------------------------------------------

-- Gets all tiles this object is occuping.
-- @ret(table) the list of tiles
function Obstacle:getAllTiles()
  return { self:getTile() }
end

-- Adds this object from to tiles it's occuping.
-- @param(tiles : table) the list of occuped tiles (optional)
function Obstacle:addToTiles(tiles)
  tiles = tiles or self:getTiles()
  tiles[1].obstacleList:add(self)
end

-- Removes this object from the tiles it's occuping.
-- @param(tiles : table) the list of occuped tiles (optional)
function Obstacle:removeFromTiles(tiles)
  tiles = tiles or self:getTiles()
  tiles[1].obstacleList:removeElement(self)
end

return Obstacle
