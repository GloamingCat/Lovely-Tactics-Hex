
--[[===============================================================================================

@classmod ObjectTile
---------------------------------------------------------------------------------------------------
-- An ObjectTile stores a list of static obstacles and a list of dynamic characters.
-- There's only one ObjectTile for each (i, j, height) in the field.

=================================================================================================]]

-- Imports
local List = require('core/datastruct/List')
local Vector = require('core/math/Vector')

-- Class table.
local ObjectTile = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam ObjectLayer layer The layer that this tile is in.
-- @tparam number x The tile's x coordinate.
-- @tparam number y The tile's y coordinate.
function ObjectTile:init(layer, x, y)
  self.layer = layer
  self.x = x
  self.y = y
  self.obstacleList = List()
  self.characterList = List()
  self.regionList = List()
  self.battlerTypeList = List()
  self.parties = {}
  self.neighborList = nil
  self.rampNeighbors = List()
  self.center = Vector(math.field.tile2Pixel(self:coordinates()))
end
--- Stores the list of neighbor tiles.
function ObjectTile:createNeighborList()
  self.neighborList = List()
  -- Create neighbors from the same layer.
  for _, n in ipairs(math.field.neighborShift) do
    if not FieldManager.currentField:exceedsBorder(self.x + n.x, self.y + n.y) then
      self.neighborList:add(self.layer.grid[self.x + n.x][self.y + n.y])
    end
  end
  for n in self.rampNeighbors:iterator() do
    self.neighborList:add(n)
  end
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Generates a unique character ID for a character in this tile.
-- @treturn string New ID.
function ObjectTile:generateCharacterID()
  local x, y, h = self:coordinates()
  return '' .. x .. '.' .. y .. '.' .. h .. '.' .. self.characterList.size
end
--- Converts to string.
function ObjectTile:__tostring()
  return 'ObjectTile (' .. self.x .. ', ' ..  self.y .. ', ' .. self.layer.height .. ')' 
end
--- Tile's coordinates.
-- @treturn number Tile's grid x.
-- @treturn number Tile's grid y.
-- @treturn number Tile's height.
function ObjectTile:coordinates()
  return self.x, self.y, self.layer.height
end
--- Gets the terrain move cost in this tile.
-- @treturn number The move cost.
function ObjectTile:getMoveCost(char)
  return FieldManager.currentField:getMoveCost(char, self:coordinates())
end
--- Updates graphics animation.
function ObjectTile:update(dt)
  if self.gui then
    self.gui:update(dt)
  end
  for i = 1, #self.obstacleList do
    if self.obstacleList[i].animation then
      self.obstaclesList[i].animation:update(dt)
    end
  end
end
--- Destroy graphics and obstacles.
function ObjectTile:destroy()
  if self.gui then
    self.gui:destroy()
  end
  for i = #self.obstacleList, 1, -1 do
    self.obstacleList[i]:destroy()
  end
end

-- ------------------------------------------------------------------------------------------------
-- Collision
-- ------------------------------------------------------------------------------------------------

--- Checks if this tile is passable from the given direction.
-- @tparam number dx The x difference in tiles.
-- @tparam number dy The y difference in tiles.
-- @tparam Object object The object that is trying to access this tile (optional).
-- @treturn boolean True if collides, false otherwise.
function ObjectTile:collides(dx, dy, object)
  return self:collidesObstacle(dx, dy, object) or self:collidesCharacter(object)
end
--- Checks if this tile is passable from the given direction.
-- @tparam number dx The x difference in tiles.
-- @tparam number dy The y difference in tiles.
-- @tparam Object object The object that is trying to access this tile (optional).
-- @treturn boolean True if collides, false otherwise.
function ObjectTile:collidesObstacle(dx, dy, object)
  for obj in self.obstacleList:iterator() do
    if not obj:isPassable(dx, dy, object) or obj.ramp then
      return true
    end
  end
  return false
end
--- Checks if this tile is passable from the given tile.
-- @tparam Object obj The object that is trying to access this tile (optional).
-- @tparam number x The x in tiles.
-- @tparam number y The y in tiles.
-- @tparam number h The height in tiles.
-- @treturn boolean True if collides, false otherwise.
function ObjectTile:collidesObstacleFrom(obj, x, y, h)
  return self:collidesObstacle(self.x - x, self.y - y, obj)
end
--- Checks collision with characters.
-- @tparam Character char The character to check collision with (optional).
-- @treturn boolean True if collides with any of the characters, false otherwise.
function ObjectTile:collidesCharacter(char)
  if char and char.battler then
    -- Battle characters.
    local party = char.party
    for other in self.characterList:iterator() do
      if self:collidesCharacters(char, other) then
        return true
      end
    end
    return false
  else
    -- Normal characters.
    for other in self.characterList:iterator() do
      if other ~= char and not other.passable then
        return true
      end
    end
    return false
  end
end
--- Checks if two characters in this tiles collide.
-- @tparam Character char The character to walk to this tile.
-- @tparam Character other The character currently in this tile.
-- @treturn boolean True if collide, false otherwise.
function ObjectTile:collidesCharacters(char, other)
  if char == other then
    return false
  end
  if not other.battler then
    return not char.passable
  end
  if not other.battler:isActive() and Config.grid.overpassDeads then
    return false
  end
  if char.party == other.party and Config.grid.overpassAllies then
    return false
  end
  return not char.passable
end
--- Checks if there is a bridge object that connects given tile to this tile.
-- @tparam Object obj The object that is trying to access this tile (optional).
-- @tparam number x The x in tiles.
-- @tparam number y The y in tiles.
-- @tparam number h The h in tiles.
-- @treturn boolean True if connects, false otherwise.
function ObjectTile:hasBridgeFrom(obj, x, y, h)
  local dx = self.x - x
  local dy = self.y - y
  for obj in self.obstacleList:iterator() do
    if obj.bridge and obj:isPassable(dx, dy, obj) then
      return true
    end
  end
  return false
end

-- ------------------------------------------------------------------------------------------------
-- Parties
-- ------------------------------------------------------------------------------------------------

--- Gets the party of the current character in the tile.
-- @treturn number The party number (nil if more than one character with different parties).
function ObjectTile:getCurrentParty()
  local party = nil
  for c in self.characterList:iterator() do
    if c.battler then
      if party == nil then
        party = c.party
      elseif c.party ~= party then
        return nil
      end
    end
  end
  return party
end
-- Checks if there are any enemies in this tile (character with a different party number).
-- @tparam number yourPaty The party number to check.
-- @treturn boolean True if there's at least one enemy, false otherwise.
function ObjectTile:hasEnemy(yourParty)
  for c in self.characterList:iterator() do
    if c.battler and c.party ~= yourParty then
      return true
    end
  end
end
-- Checks if there are any allies in this tile (character with the same party number).
-- @tparam number yourPaty The party number to check.
-- @treturn boolean True if there's at least one ally, false otherwise.
function ObjectTile:hasAlly(yourParty)
  for c in self.characterList:iterator() do
    if c.party == yourParty then
      return true
    end
  end
end
--- Gets the first character in the list that contains battler info.
-- @treturn Character First battle character or nil if there is no battle character.
function ObjectTile:getFirstBattleCharacter()
  for c in self.characterList:iterator() do
    if c.battler then
      return c
    end
  end
end

return ObjectTile
