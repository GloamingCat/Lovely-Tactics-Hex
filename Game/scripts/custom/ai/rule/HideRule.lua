
--[[===============================================================================================

HideRule
---------------------------------------------------------------------------------------------------
The rule for an AI that moves to the farest tile that still has a reachable target.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local BattleTactics = require('core/battle/ai/BattleTactics')
local MoveAction = require('core/battle/action/MoveAction')
local PathFinder = require('core/algorithm/PathFinder')
local ScriptRule = require('core/battle/ai/dynamic/ScriptRule')

local HideRule = class(ScriptRule)

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides ScriptRule:execute.
function HideRule:execute(user)
  local skill = self.action
  local input = ActionInput(skill, user)
  skill:onSelect(input)
  
  -- Find tile to move
  local queue = BattleTactics.runAway(user.battler.party, input)
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

return HideRule
