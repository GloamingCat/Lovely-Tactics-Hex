
--[[===============================================================================================

DefendRule
---------------------------------------------------------------------------------------------------
The rule for an AI that moves to the safest tile that still has a reachable target.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local BattleTactics = require('core/battle/ai/BattleTactics')
local MoveAction = require('core/battle/action/MoveAction')
local PathFinder = require('core/algorithm/PathFinder')
local ScriptRule = require('core/battle/ai/dynamic/ScriptRule')

local DefendRule = class(ScriptRule)

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides ScriptRule:execute.
function DefendRule:execute(user)
  local skill = self.action
  local input = ActionInput(skill, user)
  skill:onSelect(input)
  local queue = BattleTactics.runFromEnemiesToAllies(user.battler.party, input)
  
  if queue:isEmpty() then
    return nil
  end
  
  -- Find tile to move
  input.target = queue:front()
  input.action = MoveAction()
  input.action:onSelect(input)
  input.action:onConfirm(input)
  
  -- Find tile to attack
  input.action = skill
  skill:onSelect(input)
  queue = BattleTactics.closestCharacters(input)
  input.target = queue:front()
  
  return skill:onConfirm(input)
end

return DefendRule
