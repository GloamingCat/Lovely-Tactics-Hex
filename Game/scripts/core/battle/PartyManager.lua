
--[[===============================================================================================

PartyManager
---------------------------------------------------------------------------------------------------
Stores and manages player's party members (active and backup).

=================================================================================================]]

-- Imports
local List = require('core/algorithm/List')

-- Constants
local stateVariables = Config.stateVariables

local PartyManager = class()

---------------------------------------------------------------------------------------------------
-- Operations
---------------------------------------------------------------------------------------------------

function PartyManager:addBattler(battlerID, noCopy)
  local members = SaveManager.current.partyMembers
  if noCopy and util.arrayIndexOf(members, battlerID) then
    return
  end
  members[#members + 1] = battlerID
end

function PartyManager:removeBattler(battlerID, removeAll)
  local members = SaveManager.current.partyMembers
  if removeAll then
    -- TODO
  else
    local i = util.arrayIndexOf(members, battlerID)
    if i then 
      table.remove(members, i)
      -- TODO: remove from grid
    end
  end
end

---------------------------------------------------------------------------------------------------
-- All members
---------------------------------------------------------------------------------------------------

-- Returns a list of battlers currently in the party.
-- @ret(List) a list of battler tables
function PartyManager:currentBattlers()
  local battlers = List()
  local members = SaveManager.current.partyMembers
  for i, member in ipairs(members) do
    battlers:add(Database.battlers[member + 1])
  end
  return battlers
end
-- Returns a list with the current members in the party.
-- @ret(List) a list of battler IDs
function PartyManager:currentBattlerIDs()
  local members = SaveManager.current.partyMembers
  return List(members)
end

---------------------------------------------------------------------------------------------------
-- Members on battle
---------------------------------------------------------------------------------------------------

-- Retuns the list of battlers that are in battle.
-- @ret(List) a list of battler tables
function PartyManager:onFieldBattlers()
  local battlers = self:currentBattlers()
  battlers:conditionalRemove(function(battler)
    return TroopManager:battlerCount(battler) == 0
  end)
  return battlers
end
-- Retuns the list of battlers that are in battle.
-- @ret(List) a list of battler IDs
function PartyManager:onFieldBattlersIDs()
  local list = self:currentBattlerIDs()
  list:conditionalRemove(function(id)
    local battler = Database.battlers[id + 1]
    return TroopManager:battlerCount(battler) == 0
  end)
  return list
end

---------------------------------------------------------------------------------------------------
-- Backup members
---------------------------------------------------------------------------------------------------

-- Retuns the list of battlers that are not in battle.
-- @ret(List) a list of battler tables
function PartyManager:backupBattlers()
  local battlers = self:currentBattlers()
  battlers:conditionalRemove(function(battler)
    return TroopManager:battlerCount(battler) > 0
  end)
  return battlers
end
-- Retuns the list of battlers that are not in battle.
-- @ret(List) a list of battler IDs
function PartyManager:backupBattlersIDs()
  local list = self:currentBattlerIDs()
  list:conditionalRemove(function(id)
    local battler = Database.battlers[id + 1]
    local c = TroopManager:battlerCount(battler)
    return c > 0
  end)
  return list
end

---------------------------------------------------------------------------------------------------
-- Rewards
---------------------------------------------------------------------------------------------------

-- Adds the rewards from the defeated enemies.
function PartyManager:addRewards()
  local backup = self:backupBattlersIDs()
  local battlers = self:onFieldBattlersIDs()
  local enemies = List(TroopManager.characterList)
  enemies:conditionalRemove(
    function(e) 
      return e.battler.party == TroopManager.playerParty or e.battler:isAlive() 
    end
  )
  for i = 1, #stateVariables do
    if stateVariables[i].reward == 2 then -- Party reward
      self:addPartyRewards(stateVariables[i].shortName, enemies)
    elseif stateVariables[i].reward == 1 then -- Battler reward
      self:addBattlerRewards(stateVariables[i], enemies, battlers, backup)
    end
  end
end
-- Adds a party reward type i.
-- @param(name : string) the name of the state variable
-- @param(enemies : List) list of defeated enemies
function PartyManager:addPartyRewards(name, enemies)
  local data = SaveManager.current.partyData
  for e in enemies:iterator() do
    data[name] = data[name] + e.battler.state[name]
  end
end
-- Adds a battler reward type i.
-- @param(var : table) the state variable
-- @param(enemies : List) list of defeated enemies
-- @param(battlers : List) list of battlers on the field
-- @param(backup : List) list of backup battlers
function PartyManager:addBattlerRewards(var, enemies, battlers, backup)
  local data = SaveManager.current.battlerData
  local div = 1
  if var.divide then
    div = #battlers + #backup * var.backup / 100
  end
  local name = var.shortName
  for e in enemies:iterator() do
    -- On field battlers
    for id in battlers:iterator() do
      local b = Database.battlers[id + 1]
      if b.persistent then
        id = id .. ''
        data[id] = data[id] or {}
        data[id][name] = data[id][name] + e.battler.state[name] / div
      end
    end
    -- Backup battlers
    for id in backup:iterator() do
      local b = Database.battlers[id + 1]
      if b.persistent then
        id = id .. ''
        data[id] = data[id] or {}
        data[id][name] = data[id][name] + e.battler.state[name] / div * var.backup / 100
      end
    end
  end
end

return PartyManager
