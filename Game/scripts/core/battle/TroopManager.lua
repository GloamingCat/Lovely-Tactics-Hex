
--[[===============================================================================================

TroopManager
---------------------------------------------------------------------------------------------------
Creates and manages battle troops.

=================================================================================================]]

-- Imports
local List = require('core/algorithm/List')
local Character = require('core/objects/Character')
local Battler = require('core/battle/Battler')
local Troop = require('core/battle/Troop')
local PriorityQueue = require('core/algorithm/PriorityQueue')

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
  -- Create parties
  for i = 1, #parties do
    if i == playerID then
      local troop = SaveManager.current.partyTroop:clone()
      self:createTroop(troop, parties[i], i - 1)
    elseif #parties[i].troops > 0 then
      local r = rand(#parties[i].troops)
      local troopID = parties[i].troops[r]
      self:createTroop(Troop.fromData(troopID), parties[i], i - 1)
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
  for i = 1, sizeX do
    for j = 1, sizeY do
      local battlerID = troop.grid:get(i, j)
      local tile = field:getObjectTile(i + partyInfo.x - sizeX, j + partyInfo.y, partyInfo.h)
      tile.gui.party = partyID
      if battlerID >= 0 then
        if tile and not tile:collides(0, 0) then
          local dir = troop:getCharacterDirection()
          self:createBattleCharacter(field, tile, battlerID, partyID, dir)
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
function TroopManager:createBattleCharacter(field, tile, battlerID, partyID, dir)
  local battlerData = Database.battlers[battlerID + 1]
  local charData = {
    type = 1,
    id = -1,
    charID = battlerData.battleCharID,
    animID = 0,
    direction = dir,
    tags = {}
  }
  charData.x, charData.y, charData.h = tile:coordinates()
  local character = Character(charData, tile)
  character.battler = Battler(character, battlerID, partyID)
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
end
-- Removes the given character.
function TroopManager:removeCharacter(char)
  self.characterList:removeElement(char)
  char:destroy()
end

---------------------------------------------------------------------------------------------------
-- Auxiliary Functions
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
    if bc.battler.battlerID == id then
      return bc
    end
  end
end
-- Increments all character's turn count.
-- @param(time : number) the number of time iterations (1 by default)
-- @ret(Character) the character that reached turn limit (nil if none did)
function TroopManager:incrementTurnCount(time)
  time = time or 1
  for bc in self.characterList:iterator() do
    if bc.battler:isAlive() then
      bc.battler:incrementTurnCount(time)
    end
  end
end
-- Sorts the characters according to which one's turn will star first.
-- @param(turnLimit : number) the turn count to start the turn
-- @ret(PriorityQueue) the queue where which element is a character 
--  and each key is the remaining turn count until it's the character's turn
function TroopManager:getTurnQueue(turnLimit)
  local queue = PriorityQueue()
  for char in self.characterList:iterator() do
    if char.battler:isAlive() then
      local time = char.battler:remainingTurnCount()
      queue:enqueue(char, time)
    end
  end
  return queue
end
-- Counts the number of characters that have the given battler.
-- @param(battler : table) the data of the battler
-- @ret(number) the number of characters
function TroopManager:battlerCount(battler)
  local c = 0
  for char in self.characterList:iterator() do
    if char.battler.data == battler then
      c = c + 1
    end
  end
  return c
end
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
  for i = 0, #centers do
    local c = centers[i]
    if c then
      c.vector:mul(1 / c.count)
      centers[i] = c.vector
    end
  end
  return centers
end

return TroopManager
