
--[[===============================================================================================

DefendRule
---------------------------------------------------------------------------------------------------
The rule for an AI that moves to the safest tile that still has a reachable target.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local BattleTactics = require('core/battle/ai/BattleTactics')
local MoveAction = require('core/battle/action/MoveAction')
local PathFinder = require('core/battle/ai/PathFinder')
local ScriptRule = require('core/battle/ai/script/ScriptRule')

local DefendRule = class(ScriptRule)

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides ScriptRule:execute.
function DefendRule:execute(user)
  local skill = self.action
  local input = ActionInput(skill, user)
  skill:onSelect(input)
  
  -- Find tile to move
  local queue = BattleTactics.runFromEnemiesToAllies(user, input)
  if not queue:isEmpty() then
    input.target = queue:front()
    input.action = MoveAction()
    input:execute()
  end
  
  -- Find tile to attack
  input.action = skill
  skill:onSelect(input)
  queue = BattleTactics.closestCharacters(input)
  
  if queue:isEmpty() then
    return nil
  end
  
  input.target = queue:front()
  return input:execute()
end

return DefendRule
