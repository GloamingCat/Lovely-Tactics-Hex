
-- ================================================================================================

--- Creates and manages battle troops.
-- Parties are troop slots in the field, and they are identified by a number from 0 to the total
-- number of parties minus 1.
-- A troop contains member information and can be instantied in any party.
---------------------------------------------------------------------------------------------------
-- @classmod TroopManager

-- ================================================================================================

-- Imports
local Animation = require('core/graphics/Animation')
local Battler = require('core/battle/battler/Battler')
local Character = require('core/objects/Character')
local List = require('core/datastruct/List')
local Troop = require('core/battle/Troop')

-- Alias
local rand = love.math.random
local mathf = math.field

-- Class table.
local TroopManager = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
function TroopManager:init()
  self.troopData = {}
  self.characterList = nil
  self.troops = nil
  self.troopDirections = nil
  self.centers = nil
  self:reset()
end
--- Reset party configuration.
function TroopManager:reset()
  self.chosenTroops = {}
  self.playerParty = nil
end

-- ------------------------------------------------------------------------------------------------
-- Troop creation
-- ------------------------------------------------------------------------------------------------

--- Creates all battle characters based on field's tile data.
-- @tparam table save Save data (optional).
function TroopManager:createTroops(save)
  self.characterList = List()
  self.troops = {}
  local parties = FieldManager.currentField.parties
  -- Player's party ID
  local playerID = save and save.playerParty or FieldManager.currentField.playerParty
  if playerID == -1 then
    playerID = Config.battle.keepParties and self.playerParty -- Keep previous troop
      or rand(0, #parties - 1)
  end
  local playerTroop = nil
  self.playerParty = playerID
  -- Create parties
  self.partyCount = #parties
  for i, partyInfo in ipairs(parties) do
    local id = i - 1
    local partySave = save and save[tostring(id)]
    if partySave then
      self:createTroop(partySave.id, partyInfo, id, partySave)
    elseif id == playerID then
      self:createTroop(self.playerTroopID, partyInfo, id)
    else
      playerTroop = playerTroop or Troop()
      local troopID = Config.battle.keepParties and self.chosenTroops[id] -- Keep previous troop
        or self:getRandomTroop(partyInfo.troopSpawn, playerTroop)
      if troopID >= 0 then
        self:createTroop(troopID, partyInfo, id)
      end
    end
  end
  for char in FieldManager.characterList:iterator() do
    if char.party >= 0 then
      self:createBattler(char)
    end
  end
  self.centers = self:getPartyCenters()
end
--- Gets a valid troop ID given the list of candidate troops.
-- @tparam table troops Array of troop spawn.
-- @tparam Troop playerTroop Player's troop data.
-- @treturn number Chosen troop's ID.
function TroopManager:getRandomTroop(troops, playerTroop)
  local n = 0
  local id = -1
  local level = playerTroop:getMaxLevel()
  for _, t in ipairs(troops) do
    if level <= t.maxLevel and level >= t.minLevel then
      n = n + 1
      if rand(n) == 1 then
        id = t.id
      end
    end
  end
  return id
end
--- Creates the troop's characters.
-- @tparam number troopID Troop's ID.
-- @tparam table partyInfo Table with party's members.
-- @tparam number party Party's ID.
-- @tparam table save Save data (optional).
function TroopManager:createTroop(troopID, partyInfo, party, save)
  local troop = Troop(Database.troops[troopID], party, save)
  local field = FieldManager.currentField
  troop:setRotation(partyInfo.rotation)
  troop.x = partyInfo.x
  troop.y = partyInfo.y
  troop.h = partyInfo.h
  if Config.battle.keepParties then
    self.chosenTroops[party] = troopID
  end
  self.troops[party] = troop
  if partyInfo.memberGen == 0 then
    return
  end
  local initialDirection = troop:getCharacterDirection()
  local memberSave = {}
  if save then
    for i = 1, #save.members do
      memberSave[save.members[i].key] = save.members[i]
    end
  end
  for member in troop.members:iterator() do
    local list = save and memberSave[member.key].list or member.list
    if member.list == 0 then
      if save then
        member = memberSave[member.key]
        local tile = field:getObjectTile(member.x, member.y, member.h)
        self:createCharacter(tile, member.dir, member, party)
      else
        local i, j = member.x, member.y
        local tile = field:getObjectTile(i - 1 + partyInfo.x, j - 1 + partyInfo.y, partyInfo.h)
        if tile and not tile:collides(0, 0) then
          self:createCharacter(tile, initialDirection, member, party)
        end
      end
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Battle characters
-- ------------------------------------------------------------------------------------------------

--- Creates the battler of the character and add the character to the battle character list.
-- @tparam Character character Battler's character.
function TroopManager:createBattler(character)
  local troop = self.troops[character.party]
  assert(troop, 'Party not set: ' .. tostring(character.party))
  character.battler = troop.battlers[character.key]
  assert(character.battler, 'Member ' .. tostring(character.key) .. ' not in ' .. tostring(troop))
  self.characterList:add(character)
  self.characterList[character.key] = character
  character.battler.statusList:updateGraphics(character)
  if not character.battler:isAlive() then
    character:playAnimation(character.koAnim)
  end
end
--- Creates a new battle character.
-- @tparam ObjectTile tile The initial tile of the character.
-- @tparam number dir The initial direction of the character.
-- @tparam table member The troop member that this character represents.
-- @tparam number party The number of the field's party spot this character belongs to.
-- @treturn BattleCharacter The newly created character.
function TroopManager:createCharacter(tile, dir, member, party)
  local charData = {
    key = member.key,
    charID = member.charID,
    battlerID = member.battlerID,
    party = party,
    animation = 'Idle',
    direction = dir,
    defaultSpeed = Config.battle.charSpeed,
    scripts = {},
    tags = {} }
  charData.x, charData.y, charData.h = tile:coordinates()
  return Character(charData)
end
--- Removes the given character.
function TroopManager:deleteCharacter(char)
  self.characterList:removeElement(char)
  self.characterList[char.key] = nil
  char:destroy()
end

-- ------------------------------------------------------------------------------------------------
-- Search Functions
-- ------------------------------------------------------------------------------------------------

--- Searches for the Character with the given Battler.
-- @tparam Battler battler The battler to search for.
-- @treturn Character The character with the battler (nil of not found).
function TroopManager:getBattlerCharacter(battler)
  if not self.characterList then
    return nil
  end
  for bc in self.characterList:iterator() do 
    if bc.battler == battler then
      return bc
    end
  end
end
--- Searches for the Characters with the battlers of the given ID.
-- @tparam number id The ID of the battler to search for.
-- @treturn table An array with all the characters with the given battler.
function TroopManager:getBattlerCharacters(id)
  local c = {}
  if not self.characterList then
    return c
  end
  for bc in self.characterList:iterator() do 
    if bc.battler.id == id then
      c[#c + 1] = bc
    end
  end
  return c
end
--- Counts the number of characters that have the given battler.
-- @tparam table battler The data of the battler.
-- @treturn number The number of characters.
function TroopManager:getBattlerCount(battler)
  local c = 0
  for char in self.characterList:iterator() do
    if char.battler.data == battler then
      c = c + 1
    end
  end
  return c
end
--- Gets the number of characters in the given party.
-- @tparam number party Party of the character (optional, player's party by default).
-- @treturn number The number of battler in the party.
function TroopManager:getMemberCount(party)
  party = party or self.playerParty
  local count = 0
  for bc in self.characterList:iterator() do
    if bc.party == party then
      count = count + 1
    end
  end
  return count
end
--- Gets the characters in the field that are in this troop.
-- @tparam number party The party number of the troop.
-- @tparam boolean alive True to include only living characters, false to only dead, nil to both.
-- @treturn List List of characters.
function TroopManager:currentCharacters(party, alive)
  local characters = List(self.characterList)
  characters:conditionalRemove(
    function(c)
      return c.party ~= party or alive == not c.battler:isAlive() 
    end)
  return characters
end
--- Gets all battlers that are enemies to the given party.
-- @tparam number yourParty The party number of the troop.
-- @tparam boolean alive True to include only living battlers, false to only dead, nil to both.
-- @treturn List List of battlers.
function TroopManager:enemyBattlers(yourParty, alive)
  local battlers = List()
  for party, troop in pairs(self.troops) do
    if yourParty ~= party then
      for battler in troop:visibleBattlers():iterator() do
        if not battler:isAlive() ~= alive then
          battlers:add(battler)
        end
      end
    end
  end
  return battlers
end

-- ------------------------------------------------------------------------------------------------
-- Parties
-- ------------------------------------------------------------------------------------------------

--- Setup party tiles by position of each party.
-- With two parties, each party gets a third of the map.
function TroopManager:setPartyTiles()
  local field = FieldManager.currentField
  for i, partyInfo in ipairs(field.parties) do
    local minx, miny, maxx, maxy
    if partyInfo.rotation == 0 then
      minx, maxx = math.floor(field.sizeX / 3) - 1, math.ceil(field.sizeX * 2 / 3) + 1
      miny, maxy = 0, math.floor(field.sizeY / 3)
    elseif partyInfo.rotation == 1 then
      minx, maxx = 0, math.floor(field.sizeX / 3)
      miny, maxy = math.floor(field.sizeY / 3) - 1, math.ceil(field.sizeY * 2 / 3) + 1
    elseif partyInfo.rotation == 2 then
      minx, maxx = math.floor(field.sizeX / 3) - 1, math.ceil(field.sizeX * 2 / 3) + 1
      miny, maxy = math.floor(field.sizeY * 2 / 3), field.sizeY
    else
      minx, maxx = math.floor(field.sizeX * 2 / 3), field.sizeX
      miny, maxy = math.floor(field.sizeY / 3) - 1, math.ceil(field.sizeY * 2 / 3) + 1
    end
    local id = i - 1
    for x = minx + 1, maxx do
      for y = miny + 1, maxy do
        for h = -1, 1 do
          local tile = field:getObjectTile(x, y, partyInfo.h + h)
          if tile then
            tile.party = id
          end
        end
      end
    end
  end
end
-- Gets player party's troop in the current battle if on battle, 
---  or player's troop from current save's data otherwise.
-- @treturn Troop The troop controlled by the player.
function TroopManager:getPlayerTroop()
  return self.troops and self.troops[self.playerParty] or Troop()
end
--- Searchs for a winner party (when all alive characters belong to the same party).
-- @treturn number The number of the party (returns nil if no one won yet, -1 if there's a draw).
function TroopManager:winnerParty()
  local currentParty = -1
  for bc in self.characterList:iterator() do
    if bc.battler:isAlive() then
      -- Battler's party is still active
      if currentParty == -1 then
        -- The only active party for now
        currentParty = bc.party
      elseif currentParty ~= bc.party then
        -- More than two active parties
        return nil
      end
    end
  end
  return currentParty
end
--- Gets the pixel center of each party.
-- @treturn table Array of vectors, indexed by party ID.
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
  for p, c in pairs(centers) do
    c.vector:mul(1 / c.count)
    centers[p] = c.vector
  end
  return centers
end
--- Gets the current in-battle state of all parties.
-- @treturn table Table containing the player's party and the troop data by party ID.
function TroopManager:getAllPartyData()
  local data = { playerParty = self.playerParty }
  for i = 0, self.partyCount - 1 do
    local save = util.table.deepCopy(self.troops[i]:getState())
    save.id = self.troops[i].data.id
    data[tostring(i)] = save
    for _, member in pairs(save.members) do
      if member.list ~= 2 then
        local char = self.characterList[member.key]
        if char then -- On Battle
          member.x, member.y, member.h = char:getTile():coordinates()
          member.dir = char.direction
          member.list = 0
        else
          member.list = 1
        end
      end
    end
  end
  return data
end

-- ------------------------------------------------------------------------------------------------
-- Battle
-- ------------------------------------------------------------------------------------------------

--- Calls the onBattleStart callback on each troop member.
function TroopManager:onBattleStart()
  for _, troop in pairs(self.troops) do
    for battler in troop:visibleBattlers():iterator() do
      local char = self:getBattlerCharacter(battler)
      battler:onBattleStart(char)
    end
  end
end
--- Calls the onBattleEnd callback on each troop member.
function TroopManager:onBattleEnd()
  for _, troop in pairs(self.troops) do
    for battler in troop:visibleBattlers():iterator() do
      local char = self:getBattlerCharacter(battler)
      battler:onBattleEnd(char)
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Clear
-- ------------------------------------------------------------------------------------------------

--- Erases battlers and clears list.
function TroopManager:clear()
  for bc in self.characterList:iterator() do
    bc.battler = nil
    bc.troopSlot = nil
  end
  self.characterList = nil
  self.troops = nil
  self.troopDirections = nil
  self.centers = nil
end
--- Store troop data in save.
-- @tparam Troop troop True to save modified grid formation (optional).
-- @tparam boolean saveFormation True to save modified grid formation (optional).
function TroopManager:saveTroop(troop, saveFormation)
  self.troopData[troop.data.id .. ''] = troop:getState(saveFormation)
end
--- Store data of all current troops.
function TroopManager:saveTroops()
  for i, troop in pairs(self.troops) do
    if troop.data.persistent then
      self:saveTroop(troop)
    end
  end
end

return TroopManager
