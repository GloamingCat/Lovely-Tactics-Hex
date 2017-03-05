
local List = require('core/algorithm/List')

--[[



]]

local PartyManager = require('core/class'):new()

function PartyManager:init()
  self.members = List(Config.party.initialMembers)
end

-- Returns a list of battlers currently in the party.
-- @ret(List) a list of battler tables
function PartyManager:currentBattlers()
  local battlers = List()
  for m, member in self.members:iterator() do
    battlers:add(Database.battlers[member + 1])
  end
  return battlers
end

-- Retuns the list of battlers that are not in battle.
function PartyManager:backupBattlers()
  local battlers = self:currentBattlers()
  battlers:conditionalRemove(function(b, battler)
    local c = TroopManager:battlerCount(battler)
    return c > 0
  end)
  return battlers
end

return PartyManager
