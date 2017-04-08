
--[[===========================================================================

TroopManager
-------------------------------------------------------------------------------
Creates and manages battle troops.

=============================================================================]]

-- Imports
local List = require('core/algorithm/List')
local Character = require('core/character/Character')
local Battler = require('core/battle/Battler')

-- Alias
local Random = love.math.random
local mathf = math.field
local charSpeed = (Config.player.dashSpeed + Config.player.walkSpeed) / 2

local TroopManager = require('core/class'):new()

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

function TroopManager:init()
  self.characterList = List()
end

-------------------------------------------------------------------------------
-- Character creation
-------------------------------------------------------------------------------

-- Creates all battle characters based on field's tile data.
function TroopManager:createTroops()
  local field = FieldManager.currentField
  local battleTypes = Config.battleTypes
  for tile in field:gridIterator() do
    local battlerData = self:chooseBattler(tile)
    if battlerData then
      self:createBattleCharacter(tile, battlerData, field)
    end
  end
end

-- Chooses randomly a battler to be in the given tile.
-- @param(tile : ObjectTile) the tile of the battler
-- @ret(table) the data of the chosen battler, nil if no battler was avaiable
function TroopManager:chooseBattler(tile)
  if tile.battlerTypeList.size == 0 then
    return
  end
  local battlers = tile:getBattlerList()
  if battlers.size > 0 then
    local r = Random(battlers.size)
    return battlers[r]
  else
    return nil
  end
end

-- Creates a new battle character.
-- @param(tile : ObjectTile) the initial tile of the character
-- @param(battlerData : table) the battler's data from file
-- @param(field : Field) the current field
-- @ret(BattleCharacter) the newly created character
function TroopManager:createBattleCharacter(tile, battlerData, field)
  local charID = tile:generateCharacterID()
  local characterData = {
    id = battlerData.battleCharID,
    type = 1,
    direction = 0,
    animID = 0,
    tags = {}
  }
  local character = Character(charID, characterData)
  character:setPositionToTile(tile)
  character:addToTiles()
  character.battler = Battler(battlerData, tile.party)
  character:turnToTile(field.sizeX / 2, field.sizeY / 2)
  character.speed = charSpeed
  self.characterList:add(character)
  return character
end

-------------------------------------------------------------------------------
-- Auxiliary Functions
-------------------------------------------------------------------------------

-- Searches for the Character with the given Battler.
-- @param(battler : Battler) the battler to search for
-- @ret(Character) the character with the battler (nil of not found)
function TroopManager:getCharacter(battler)
  for bc in self.characterList:iterator() do 
    if bc.battler == battler then
      return bc
    end
  end
end

-- Increments all character's turn count.
--@ret(Character) the character that reached turn limit (nil if none did)
function TroopManager:incrementTurnCount(turnLimit)
  local current = nil
  for bc in self.characterList:iterator() do
    if bc.battler:isAlive() then
      if bc.battler:incrementTurnCount(turnLimit) then
        if current == nil or current.battler.turnCount < bc.battler.turnCount then
          current = bc
        end
      end
    end
  end
  return current
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
-- @ret(number) the number of the party. Returns nil if no one won yet
function TroopManager:winnerParty()
  local currentParty = nil
  for bc in self.characterList:iterator() do
    if bc.battler and bc.battler:isAlive() then
      if currentParty == nil then
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

return TroopManager
