
--[[===========================================================================

ObjectTile - Battle
-------------------------------------------------------------------------------
Implements functions that are only used in battle.

=============================================================================]]

-- Imports
local List = require('core/algorithm/List')

-- Constants
local overpassAllies = Battle.overpassAllies

local ObjectTile_Battle = require('core/class'):new()

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

-- Gets the terrain move cost in this tile.
-- @ret(number) the move cost
function ObjectTile_Battle:getMoveCost()
  return FieldManager.currentField:getMoveCost(self.x, self.y, 
    self.layer.height)
end

-- Updates graphics animation.
function ObjectTile_Battle:update()
  if self.gui then
    self.gui:update()
  end
end

-------------------------------------------------------------------------------
-- Troop
-------------------------------------------------------------------------------

-- Returns the list of battlers that are suitable for this tile.
-- @ret(List) the list of battlers
function ObjectTile_Battle:getBattlerList()
  local battlers = nil
  if self.party == 0 then
    battlers = PartyManager:backupBattlers()
  else
    battlers = List()
    for regionID in self.regionList:iterator() do
      local data = Config.regions[regionID + 1]
      for i = 1, #data.battlers do
        local id = data.battlers[i]
        local battlerData = Database.battlers[id + 1]
        battlers:add(battlerData)
      end
    end
  end
  battlers:conditionalRemove(function(battler) 
      return not self.battlerTypeList:contains(battler.typeID)
    end)
  return battlers
end

-- Checks if any of types in a table are in this tile.
-- @ret(boolean) true if contains one or more types, falsa otherwise
function ObjectTile_Battle:containsBattleType(types)
  for i = 1, #types do
    local typeID = types[i]
    if self.battlerTypeList:contains(typeID) then
      return true
    end
  end
  return false
end

-------------------------------------------------------------------------------
-- Parties
-------------------------------------------------------------------------------

-- Checks collision with characters.
-- @param(char : Character) the character to check collision with
-- @ret(boolean) true is collides with any of the characters, false otherwise
function ObjectTile_Battle:collidesCharacter(char)
  local party = char.battler.party
  for other in self.characterList:iterator() do
    if char ~= other and (not other.battler or not overpassAllies or 
        other.battler.party ~= party or not other.battler:isAlive()) then
      return true
    end
  end
  return false
end

-- Checks if this tile os in control zone for given party.
-- @param(you : Battler) the battler of the current character
-- @ret(boolean) true if it's control zone, false otherwise
function ObjectTile_Battle:isControlZone(you, noneighbours)
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
function ObjectTile_Battle:getCurrentParty()
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
function ObjectTile_Battle:hasEnemy(yourParty)
  for c in self.characterList:iterator() do
    if c.battler and c.battler.party ~= yourParty then
      return true
    end
  end
end

-- Checks if there are any allies in this tile (character with the same party number)
-- @param(yourPaty : number) the party number to check
-- @ret(boolean) true if there's at least one ally, false otherwise
function ObjectTile_Battle:hasAlly(yourParty)
  for c in self.characterList:iterator() do
    if c.party == yourParty then
      return true
    end
  end
end

return ObjectTile_Battle