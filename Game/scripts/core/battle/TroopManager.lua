
--[[===============================================================================================

TroopManager
---------------------------------------------------------------------------------------------------
Creates and manages battle troops.

=================================================================================================]]

-- Imports
local List = require('core/datastruct/List')
local Character = require('core/objects/Character')
local Battler = require('core/battle/Battler')
local Troop = require('core/battle/Troop')

-- Alias
local rand = love.math.random
local mathf = math.field

-- Constants
local charSpeed = (Config.player.dashSpeed + Config.player.walkSpeed) / 2

local TroopManager = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function TroopManager:init()
  self.characterList = List()
  self.troopDirections = {}
  self.troopAI = {}
end

---------------------------------------------------------------------------------------------------
-- Troop creation
---------------------------------------------------------------------------------------------------

-- Creates all battle characters based on field's tile data.
function TroopManager:createTroops()
  local parties = FieldManager.currentField.battleData.parties
  -- Player's party ID
  local playerID = FieldManager.currentField.battleData.playerParty
  if playerID == -1 then
    playerID = rand(#parties)
  else
    playerID = playerID + 1
  end
  self.playerParty = playerID
  self.partyCount = #parties
  -- Create parties
  for i = 1, #parties do
    if i == playerID then
      local troop = SaveManager.current.partyTroop:clone()
      self:createTroop(troop, parties[i], i)
    elseif #parties[i].troops > 0 then
      local r = rand(#parties[i].troops)
      local troopID = parties[i].troops[r]
      self:createTroop(Troop.fromData(troopID), parties[i], i)
    end
  end
end
-- Creates the troop's characters.
-- @param(troop : TroopManager)
function TroopManager:createTroop(troop, partyInfo, partyID)
  local field = FieldManager.currentField
  local sizeX = troop.grid.width
  local sizeY = troop.grid.height
  troop:setRotation(partyInfo.rotation)
  local dir = troop:getCharacterDirection()
  self.troopDirections[partyID] = dir
  self.troopAI[partyID] = troop.AI
  for i = 1, sizeX do
    for j = 1, sizeY do
      local battlerID = troop.grid:get(i, j)
      local tile = field:getObjectTile(i + partyInfo.x - sizeX, j + partyInfo.y, partyInfo.h)
      tile.gui.party = partyID
      if battlerID >= 0 then
        if tile and not tile:collides(0, 0) then
          local battler = Battler(battlerID, partyID)
          self:createBattleCharacter(tile, battler)
        end
      end
    end
  end
end
-- Creates a new battle character.
-- @param(tile : ObjectTile) the initial tile of the character
-- @param(battlerData : table) the battler's data from file
-- @param(field : Field) the current field
-- @ret(BattleCharacter) the newly created character
function TroopManager:createBattleCharacter(tile, battler)
  local dir = self.troopDirections[battler.party]
  local charData = {
    type = 1,
    id = -1,
    charID = battler.data.battleCharID,
    animID = 0,
    direction = dir,
    tags = {}
  }
  charData.x, charData.y, charData.h = tile:coordinates()
  local character = Character(charData, tile)
  character.battler = battler
  character.speed = charSpeed
  self.characterList:add(character)
  return character
end

---------------------------------------------------------------------------------------------------
-- Remove
---------------------------------------------------------------------------------------------------

-- Erases battlers and clears list.
function TroopManager:clear()
  for bc in self.characterList:iterator() do
    bc.battler = nil
  end
  self.characterList = List()
  self.troopDirections = {}
end
-- Removes the given character.
function TroopManager:removeCharacter(char)
  self.characterList:removeElement(char)
  char:destroy()
end

---------------------------------------------------------------------------------------------------
-- Search Functions
---------------------------------------------------------------------------------------------------

-- Searches for the Character with the given Battler.
-- @param(battler : Battler) the battler to search for
-- @ret(Character) the character with the battler (nil of not found)
function TroopManager:getBattlerCharacter(battler)
  for bc in self.characterList:iterator() do 
    if bc.battler == battler then
      return bc
    end
  end
end
-- Searches for the Character with the given battler ID.
-- @param(id : number) the battler ID to search for
-- @ret(Character) the character with the battler ID (nil of not found)
function TroopManager:getBattlerIDCharacter(id)
   for bc in self.characterList:iterator() do 
    if bc.battler.id == id then
      return bc
    end
  end
end
-- Counts the number of characters that have the given battler.
-- @param(battler : table) the data of the battler
-- @ret(number) the number of characters
function TroopManager:getBattlerCount(battler)
  local c = 0
  for char in self.characterList:iterator() do
    if char.battler.data == battler then
      c = c + 1
    end
  end
  return c
end
-- Gets the number of characters in the given party.
-- @param(party : number) party of the character (optional, player's party by default)
-- @ret(number) the number of battler in the party
function TroopManager:getMemberCount(party)
  party = party or self.playerParty
  local count = 0
  for bc in self.characterList:iterator() do
    if bc.battler.party == party then
      count = count + 1
    end
  end
  return count
end

---------------------------------------------------------------------------------------------------
-- Parties
---------------------------------------------------------------------------------------------------

-- Searchs for a winner party (when all alive characters belong to the same party).
-- @ret(number) the number of the party (returns nil if no one won yet, -1 if there's a draw)
function TroopManager:winnerParty()
  local currentParty = -1
  for bc in self.characterList:iterator() do
    if bc.battler:isAlive() then
      if currentParty == -1 then
        currentParty = bc.battler.party
      else
        if currentParty ~= bc.battler.party then
          return nil
        end
      end
    end
  end
  return currentParty
end
-- Gets the pixel center of each party.
-- @ret(table) array of vectors
function TroopManager:getPartyCenters()
  local centers = {}
  for bc in self.characterList:iterator() do
    local party = bc.battler.party
    local center = centers[party]
    if center then
      center.vector:add(bc.position)
      center.count = centers[party].count + 1
    else
      centers[party] = {
        vector = bc.position:clone(),
        count = 1
      }
    end
  end
  for i = 1, #centers do
    local c = centers[i]
    if c then
      c.vector:mul(1 / c.count)
      centers[i] = c.vector
    end
  end
  return centers
end

return TroopManager
