
--[[===========================================================================

ObjectTile
-------------------------------------------------------------------------------
An ObjectTile stores a list of static obstacles and a list of dynamic characters.
There's only one ObjectTile for each (i, j, height) in the field.

=============================================================================]]

-- Imports
local ObjectTile_Battle = require('core/fields/ObjectTile_Battle')
local List = require('core/algorithm/List')

-- Alias
local neighborShift = math.field.neighborShift

-- Constants
local overpassAllies = Battle.overpassAllies

local ObjectTile = ObjectTile_Battle:inherit()

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

-- @param(layer : ObjectLayer) the layer that this tile is in
-- @param(x : number) the tile's x coordinate
-- @param(y : number) the tile's y coordinate
function ObjectTile:init(layer, x, y, defaultRegion)
  self.layer = layer
  self.x = x
  self.y = y
  self.obstacleList = List()
  self.characterList = List()
  self.regionList = List()
  self.battlerTypeList = List()
  self.party = nil
  self.neighborList = nil
  if defaultRegion then
    self.regionList:add(defaultRegion)
  end
  self:createGridGUI()
end

-- Generates a unique character ID for a character in this tile.
-- @ret(string) new ID
function ObjectTile:generateCharacterID()
  local h, x, y = self:coordinates()
  return '' .. h .. '.' .. x .. '.' .. y .. '.' .. self.characterList.size
end

-------------------------------------------------------------------------------
-- Grid/neighborhood
-------------------------------------------------------------------------------

-- Stores the list of neighbor tiles.
function ObjectTile:createNeighborList()
  self.neighborList = List()
  for i, n in ipairs(neighborShift) do
    local row = self.layer.grid[n.x + self.x]
    if row then
      local tile = row[n.y + self.y]
      if tile then
        self.neighborList:add(tile)
      end
    end
  end
end

-- @ret(number) tile's grid x
-- @ret(number) tile's grid y
-- @ret(number) tile's height
function ObjectTile:coordinates()
  return self.x, self.y, self.layer.height
end

-------------------------------------------------------------------------------
-- Collision
-------------------------------------------------------------------------------

-- Checks if this tile is passable from the given direction.
-- @param(dx : number) the x difference in tiles
-- @param(dy : number) the y difference in tiles
-- @param(object : Object) the object that is trying to access this tile (optional)
-- @ret(boolean) true if passable, false otherwise
function ObjectTile:collidesObstacle(dx, dy, object)
  for obj in self.obstacleList:iterator() do
    if not obj:isPassable(dx, dy, object) then
      return true
    end
  end
  return false
end

-- Checks if this tile is passable from the given tile.
-- @param(x : number) the x in tiles
-- @param(y : number) the y in tiles
-- @param(obj : Object) the object that is trying to access this tile (optional)
-- @ret(boolean) true if passable, false otherwise
function ObjectTile:collidesObstacleFrom(obj, x, y, h)
  return self:collidesObstacle(self.x - x, self.y - y, obj)
end

-- Checks collision with characters.
-- @param(char : Character) the character to check collision with
-- @param(party : number) the character's party (if not nil, it's passable for allies)
-- @ret(boolean) true is collides with any of the characters, false otherwise
function ObjectTile:collidesCharacter(char, party)
  if party and overpassAllies then
    for c in self.characterList:iterator() do
      if char ~= c and c.party ~= party then
        return true
      end
    end
  else
    for c in self.characterList:iterator() do
      if char ~= c then
        return true
      end
    end
  end
  return false
end

-- Converts to string.
-- @ret(string) the string representation
function ObjectTile:toString()
  return 'ObjectTile (' .. self.x .. ', ' ..  self.y .. ', ' .. self.layer.height .. ')' 
end

return ObjectTile
