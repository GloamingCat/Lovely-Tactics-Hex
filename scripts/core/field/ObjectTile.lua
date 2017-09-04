
--[[===============================================================================================

ObjectTile
---------------------------------------------------------------------------------------------------
An ObjectTile stores a list of static obstacles and a list of dynamic characters.
There's only one ObjectTile for each (i, j, height) in the field.

=================================================================================================]]

-- Imports
local List = require('core/datastruct/List')

-- Constants
local overpassAllies = Config.battle.overpassAllies
local overpassDeads = Config.battle.overpassDeads
local neighborShift = math.field.neighborShift

local ObjectTile = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
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
  self.parties = {}
  self.neighborList = nil
  if defaultRegion then
    self.regionList:add(defaultRegion)
  end
end
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

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Generates a unique character ID for a character in this tile.
-- @ret(string) new ID
function ObjectTile:generateCharacterID()
  local h, x, y = self:coordinates()
  return '' .. h .. '.' .. x .. '.' .. y .. '.' .. self.characterList.size
end
-- Converts to string.
function ObjectTile:__tostring()
  return 'ObjectTile (' .. self.x .. ', ' ..  self.y .. ', ' .. self.layer.height .. ')' 
end
-- Tile's coordinates.
-- @ret(number) tile's grid x
-- @ret(number) tile's grid y
-- @ret(number) tile's height
function ObjectTile:coordinates()
  return self.x, self.y, self.layer.height
end
-- Gets the terrain move cost in this tile.
-- @ret(number) the move cost
function ObjectTile:getMoveCost()
  return FieldManager.currentField:getMoveCost(self.x, self.y, 
    self.layer.height)
end
-- Updates graphics animation.
function ObjectTile:update()
  if self.gui then
    self.gui:update()
  end
  for i = 1, #self.obstacleList do
    if self.obstacleList[i].animation then
      self.obstaclesList[i].animation:update()
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Collision
---------------------------------------------------------------------------------------------------

-- Checks if this tile is passable from the given direction.
-- @param(dx : number) the x difference in tiles
-- @param(dy : number) the y difference in tiles
-- @param(object : Object) the object that is trying to access this tile (optional)
-- @ret(boolean) true if collides, false otherwise
function ObjectTile:collides(dx, dy, object)
  return self:collidesObstacle(dx, dy, object) or self:collidesCharacter(object)
end
-- Checks if this tile is passable from the given direction.
-- @param(dx : number) the x difference in tiles
-- @param(dy : number) the y difference in tiles
-- @param(object : Object) the object that is trying to access this tile (optional)
-- @ret(boolean) true if collides, false otherwise
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
-- @ret(boolean) true if collides, false otherwise
function ObjectTile:collidesObstacleFrom(obj, x, y, h)
  return self:collidesObstacle(self.x - x, self.y - y, obj)
end
-- Checks collision with characters.
-- @param(char : Character) the character to check collision with (optional)
-- @ret(boolean) true if collides with any of the characters, false otherwise
function ObjectTile:collidesCharacter(char)
  if not char then
    return not self.characterList:isEmpty()
  elseif char.battler then
    -- Battle characters.
    local party = char.battler.party
    for other in self.characterList:iterator() do
      if self:collidesCharacters(char, other) then
        return true
      end
    end
    return false
  else
    -- Normal characters.
    if self.characterList.size > 1 then
      return true
    elseif self.characterList.size == 1 then
      return self.characterList[1] ~= char
    else
      return false
    end
  end
end
-- Checks if two characters in this tiles collide.
-- @param(char : Character) the character to walk to this tile
-- @param(other : Character) the character currently in this tile
-- @ret(boolean) true if collide, false otherwise
function ObjectTile:collidesCharacters(char, other)
  if char == other then
    return false
  end
  if not other.battler then
    return true
  end
  if not other.battler:isAlive() and overpassDeads then
    return false
  end
  if char.battler.party == other.battler.party and overpassAllies then
    return false
  end
  return true
end

---------------------------------------------------------------------------------------------------
-- Parties
---------------------------------------------------------------------------------------------------

-- Gets the party of the current character in the tile.
-- @ret(number) the party number (nil if more than one character with different parties)
function ObjectTile:getCurrentParty()
  local party = nil
  for c in self.characterList:iterator() do
    if c.battler then
      if party == nil then
        party = c.battler.party
      elseif c.battler.party ~= party then
        return nil
      end
    end
  end
  return party
end
-- Checks if there are any enemies in this tile (character with a different party number)
-- @param(yourPaty : number) the party number to check
-- @ret(boolean) true if there's at least one enemy, false otherwise
function ObjectTile:hasEnemy(yourParty)
  for c in self.characterList:iterator() do
    if c.battler and c.battler.party ~= yourParty then
      return true
    end
  end
end
-- Checks if there are any allies in this tile (character with the same party number)
-- @param(yourPaty : number) the party number to check
-- @ret(boolean) true if there's at least one ally, false otherwise
function ObjectTile:hasAlly(yourParty)
  for c in self.characterList:iterator() do
    if c.party == yourParty then
      return true
    end
  end
end

return ObjectTile
