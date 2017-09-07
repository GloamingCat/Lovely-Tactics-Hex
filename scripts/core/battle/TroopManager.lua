
--[[===============================================================================================

TroopManager
---------------------------------------------------------------------------------------------------
Creates and manages battle troops.

=================================================================================================]]

-- Imports
local Animation = require('core/graphics/Animation')
local List = require('core/datastruct/List')
local Character = require('core/objects/Character')
local Battler = require('core/battle/Battler')
local Troop = require('core/battle/Troop')

-- Alias
local rand = love.math.random
local mathf = math.field
local angle2row = math.angle2Row

-- Constants
local charSpeed = (Config.player.dashSpeed + Config.player.walkSpeed) / 2

local TroopManager = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function TroopManager:init()
  self.characterList = List()
  self.troops = {}
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
  for i = 1, self.partyCount do
    if i == playerID then
      self:createTroop(SaveManager.current.playerTroopID, parties[i], i)
    elseif #parties[i].troops > 0 then
      local r = rand(#parties[i].troops)
      self:createTroop(parties[i].troops[r], parties[i], i)
    end
  end
  for char in FieldManager.characterList:iterator() do
    self:createBattler(char)
  end
end
-- Creates the troop's characters.
-- @param(troop : TroopManager)
function TroopManager:createTroop(troopID, partyInfo, party)
  local troop = Troop(Database.troops[troopID], party)
  local field = FieldManager.currentField
  local sizeX = troop.grid.width
  local sizeY = troop.grid.height
  troop:setRotation(partyInfo.rotation)
  local dir = troop:getCharacterDirection()
  self.troops[party] = troop
  for i = 1, sizeX do
    for j = 1, sizeY do
      local slot = troop.grid:get(i, j)
      if slot then
        local tile = field:getObjectTile(i + partyInfo.x - sizeX, j + partyInfo.y, partyInfo.h)
        if tile and not tile:collides(0, 0) then
          self:createCharacter(tile, dir, slot, party)
        end
      end
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Battle characters
---------------------------------------------------------------------------------------------------

-- Creates a new battle character.
-- @param(tile : ObjectTile) the initial tile of the character
-- @param(dir : number) the initial direction of the character
-- @param(member : table) the troop member which this character represents
-- @param(party : number) the number of the field's party spot this character belongs to
-- @ret(BattleCharacter) the newly created character
function TroopManager:createCharacter(tile, dir, member, party)
  local charData = {
    key = member.key,
    charID = member.charID,
    battlerID = member.battlerID,
    party = party,
    anim = 'Idle',
    direction = dir,
    tags = {} }
  charData.x, charData.y, charData.h = tile:coordinates()
  local character = Character(charData)
  character.speed = charSpeed
  return character
end
-- Creates the battler of the character and add the character to the battle character list.
-- @param(character : Character)
-- @param(partyID : number)
function TroopManager:createBattler(character)
  if character.battlerID >= 0 and character.party >= 0 then
    local battlerData = Database.battlers[character.battlerID]
    local troop = self.troops[character.party]
    local save = troop.persistent and troop:getMemberData(character.key)
    character.battler = Battler(battlerData, character, save)
    local balloonAnim = Database.animations[Config.animations.statusBalloonID]
    character.balloon = ResourceManager:loadAnimation(balloonAnim, FieldManager.renderer)
    character.balloon.sprite:setTransformation(balloonAnim.transform)
    character:setPosition(character.position)
    self.characterList:add(character)
    character:setAnimations('battle')
    character:replayAnimation(character.idleAnim, false, angle2row(character.direction))
  end
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

-- Gets the troop controlled by the player.
-- @ret(Troop)
function TroopManager:getPlayerTroop()
  return self.troops[self.playerParty]
end
-- Searchs for a winner party (when all alive characters belong to the same party).
-- @ret(number) the number of the party (returns nil if no one won yet, -1 if there's a draw)
function TroopManager:winnerParty()
  local currentParty = -1
  for bc in self.characterList:iterator() do
    if bc.battler:isActive() then
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
    local party = bc.party
    local center = centers[party]
    if center then
      center.vector:add(bc.position)
      center.count = centers[party].count + 1
    else
      centers[party] = {
        vector = bc.position:clone(),
        count = 1 }
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

---------------------------------------------------------------------------------------------------
-- Save
---------------------------------------------------------------------------------------------------

function TroopManager:saveTroops()
  -- Store member data in troops
  for char in self.characterList:iterator() do
    local troop = self.troops[char.party]
    if troop.data.persistent then
      troop:setMemberData(char.key, char.battler:createPersistentData())
    end
  end
  -- Store troop data in save
  for i = 1, #self.troops do
    local troop = self.troops[i]
    if troop.data.persistent then
      SaveManager.current.troops[troop.data.id] = troop:createPersistentData()
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Clear
---------------------------------------------------------------------------------------------------

-- Erases battlers and clears list.
function TroopManager:clear()
  for bc in self.characterList:iterator() do
    bc.battler = nil
    bc.troopSlot = nil
  end
  self.characterList = List()
  self.troopDirections = {}
end

return TroopManager
