
--[[===============================================================================================

RunAwayRule
---------------------------------------------------------------------------------------------------
The rule for an AI that moves to the tile that is the farest from the enemies.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local BattleTactics = require('core/battle/ai/BattleTactics')
local MoveAction = require('core/battle/action/MoveAction')
local PathFinder = require('core/battle/ai/PathFinder')
local ScriptRule = require('core/battle/ai/script/ScriptRule')

local RunAwayRule = class(ScriptRule)

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides ScriptRule:execute.
function RunAwayRule:execute(user)
  local action = MoveAction()
  local input = ActionInput(action, user)
  action:onSelect(input)
  
  -- Find tile to move
  local queue = BattleTactics.runAway(user)
  if queue:isEmpty() then
    return nil
  end
  
  input.target = queue:front()
  return input:execute()
end

return RunAwayRule
