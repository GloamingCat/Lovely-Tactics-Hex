
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
-- General
---------------------------------------------------------------------------------------------------

-- Constructor.
function PartyManager:init()
  self.members = List(Config.initialMembers)
end

---------------------------------------------------------------------------------------------------
-- All members
---------------------------------------------------------------------------------------------------

-- Returns a list of battlers currently in the party.
-- @ret(List) a list of battler tables
function PartyManager:currentBattlers()
  local battlers = List()
  for member in self.members:iterator() do
    battlers:add(Database.battlers[member + 1])
  end
  return battlers
end
-- Returns a list with the current members in the party.
-- @ret(List) a list of battler IDs
function PartyManager:currentBattlerIDs()
  return List(self.members)
end

---------------------------------------------------------------------------------------------------
-- Members on battle
---------------------------------------------------------------------------------------------------

-- Retuns the list of battlers that are in battle.
-- @ret(List) a list of battler tables
function PartyManager:onFieldBattlers()
  local battlers = self:currentBattlers()
  battlers:conditionalRemove(function(battler)
    local c = TroopManager:battlerCount(battler)
    return c == 0
  end)
  return battlers
end
-- Retuns the list of battlers that are in battle.
-- @ret(List) a list of battler IDs
function PartyManager:onFieldBattlersIDs()
  local list = List(self.members)
  list:conditionalRemove(function(id)
    local battler = Database.battlers[id + 1]
    local c = TroopManager:battlerCount(battler)
    return c == 0
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
    local c = TroopManager:battlerCount(battler)
    return c > 0
  end)
  return battlers
end
-- Retuns the list of battlers that are not in battle.
-- @ret(List) a list of battler IDs
function PartyManager:backupBattlersIDs()
  local list = List(self.members)
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
  local backup = self:backupBattlers()
  local battlers = self:onFieldBattlers()
  local enemies = List(TroopManager.characterList)
  enemies:conditionalRemove(
    function(e) 
      return e.battler.party == 0 or e.battler:isAlive() 
    end
  )
  for i = 1, #stateVariables do
    if stateVariables[i].reward == 2 then -- Party reward
      self:addPartyRewards(stateVariables[i].name, enemies)
    elseif stateVariables[i].reward == 1 then -- Battler reward
      self:addBattlerRewards(stateVariables[i], enemies, battlers, backup)
    end
  end
end
-- Adds a party reward type i.
-- @param(name : string) the name of the state variable
-- @param(enemies : List) list of defeated enemies
function PartyManager:addPartyRewards(name, enemies)
  local state = SaveManager.current.partyData
  for e in enemies:iterator() do
    state[name] = state[name] + e.battler.state[name]
  end
end
-- Adds a battler reward type i.
-- @param(var : table) the state variable
-- @param(enemies : List) list of defeated enemies
-- @param(battlers : List) list of battlers on the field
-- @param(backup : List) list of backup battlers
function PartyManager:addBattlerRewards(var, enemies, battlers, backup)
  local state = SaveManager.current.partyData
  local div = 1
  if var.divide then
    div = #battlers + #backup * var.backup / 100
  end
  for e in enemies:iterator() do
    -- On field battlers
    for b in battlers:iterator() do
      b = b.data
      if b.persistent then
        b.state[var.name] = b.state[var.name] + e.state[var.name] / div
      end
    end
    -- Backup battlers
    for b in backup:iterator() do
      b = b.data
      if b.persistent then
        b.state[var.name] = b.state[var.name] + e.state[var.name] / div * var.backup / 100
      end
    end
  end
end

return PartyManager
