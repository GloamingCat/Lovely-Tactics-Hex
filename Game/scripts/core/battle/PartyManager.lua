
--[[===========================================================================

Manages party members (active and backup).

=============================================================================]]

-- Imports
local List = require('core/algorithm/List')

local PartyManager = require('core/class'):new()

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

return PartyManager
