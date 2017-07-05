
--[[===============================================================================================

ObjectTile
---------------------------------------------------------------------------------------------------
An ObjectTile stores a list of static obstacles and a list of dynamic characters.
There's only one ObjectTile for each (i, j, height) in the field.

=================================================================================================]]

-- Imports
local List = require('core/algorithm/List')

-- Constants
local overpassAllies = Battle.overpassAllies
local overpassDeads = Battle.overpassDeads
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
  self.party = nil
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
end

---------------------------------------------------------------------------------------------------
-- Collision
---------------------------------------------------------------------------------------------------

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
-- @ret(boolean) true is collides with any of the characters, false otherwise
function ObjectTile:collidesCharacter(char)
  if char.battler then
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
-- @ret(boolean)
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
-- Troop
---------------------------------------------------------------------------------------------------

-- Returns the list of battlers that are suitable for this tile.
-- @ret(List) the list of battler IDs
function ObjectTile:getBattlerList()
  local battlers = nil
  if self.party == 0 then
    battlers = PartyManager:backupBattlersIDs()
    --battlers = PartyManager:currentBattlerIDs()
  else
    battlers = List()
    for regionID in self.regionList:iterator() do
      local data = Config.regions[regionID + 1]
      for i = 1, #data.battlers do
        local id = data.battlers[i]
        battlers:add(id)
      end
    end
  end
  battlers:conditionalRemove(function(battlerID) 
      local battler = Database.battlers[battlerID + 1]
      return not self.battlerTypeList:contains(battler.typeID)
    end)
  return battlers
end

-- Checks if any of types in a table are in this tile.
-- @ret(boolean) true if contains one or more types, falsa otherwise
function ObjectTile:containsBattleType(types)
  for i = 1, #types do
    local typeID = types[i]
    if self.battlerTypeList:contains(typeID) then
      return true
    end
  end
  return false
end

---------------------------------------------------------------------------------------------------
-- Parties
---------------------------------------------------------------------------------------------------

-- Checks if this tile os in control zone for given party.
-- @param(you : Battler) the battler of the current character
-- @ret(boolean) true if it's control zone, false otherwise
function ObjectTile:isControlZone(you, noneighbours)
  local containsAlly, containsEnemy = false, false
  for char in self.characterList:iterator() do
    if char.battler and char.battler:isAlive() then
      if char.battler.party == you.party then
        containsAlly = true
      else
        containsEnemy = true
      end
    end
  end
  if containsEnemy then
    return true
  elseif containsAlly then
    return false
  end
  if noneighbours then
    return false
  end
  for n in self.neighborList:iterator() do
    if n:isControlZone(you, true) then
      return true
    end
  end
  return false
end

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
