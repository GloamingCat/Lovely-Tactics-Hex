
--[[===============================================================================================

RunAwayRule
---------------------------------------------------------------------------------------------------
The rule for an AI that moves to the tile that is the farest from the enemies.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local BattleTactics = require('core/battle/ai/BattleTactics')
local MoveAction = require('core/battle/action/MoveAction')
local PathFinder = require('core/algorithm/PathFinder')
local ScriptRule = require('core/battle/ai/dynamic/ScriptRule')

local RunAwayRule = class(ScriptRule)

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides ScriptRule:execute.
function RunAwayRule:execute(user)
  local queue = BattleTactics.runAway(user.battler.party)
  local input = ActionInput(MoveAction(), user, queue:front()) 
  return input:execute()
end

return RunAwayRule
