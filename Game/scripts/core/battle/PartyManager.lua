
--[[===========================================================================

PartyManager
-------------------------------------------------------------------------------
Stores and manages player's party members (active and backup).

=============================================================================]]

-- Imports
local List = require('core/algorithm/List')

local PartyManager = class()

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

function PartyManager:init()
  self.members = List(Config.initialMembers)
end

-- Returns a list of battlers currently in the party.
-- @ret(List) a list of battler tables
function PartyManager:currentBattlers()
  local battlers = List()
  for member in self.members:iterator() do
    battlers:add(Database.battlers[member + 1])
  end
  return battlers
end

function PartyManager:currentBattlerIDs()
  return List(self.members)
end

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
-- @ret(List) a list of battler tables
function PartyManager:backupBattlersIDs()
  local list = List(self.members)
  list:conditionalRemove(function(id)
    local battler = Database.battlers[id + 1]
    local c = TroopManager:battlerCount(battler)
    return c > 0
  end)
  return list
end

return PartyManager
