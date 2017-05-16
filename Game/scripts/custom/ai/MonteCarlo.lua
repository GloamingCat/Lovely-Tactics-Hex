
--[[===============================================================================================

MonteCarlo AI
---------------------------------------------------------------------------------------------------
An AI based on Monte Carlo Tree Search, that chooses the better action considering the defined 
evaluation function.

=================================================================================================]]

-- Imports
local Queue = require('core/algorithm/Queue')
local BattleSimulation = require('core/battle/BattleSimulation')
local ArtificialInteligence = require('core/battle/ArtificialInteligence')
local ActionInput = require('core/battle/action/ActionInput')

-- Alias
local floor = math.floor

local MonteCarlo = class(ArtificialInteligence)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor. Starts decision tree as empty.
-- @param(param : string) the script param (used as the maximum tree depth)
function MonteCarlo:init(param, battler)
  local steps = 1
  if param ~= '' then
    steps = tonumber(param) or 1
  end
  self.steps = steps
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides ArtificialInteligence:nextAction.
function MonteCarlo:nextAction(user)
  local state = BattleSimulation()
  local input = self:getBestAction(user, state)
  input.action:onSelect(input, user)
  return input.action:onConfirm(input)
end

-- @ret(ActionInput)
function MonteCarlo:getBestBranch(user, state)
  local possibleActions = self:getCharacterActions(user)
  local bestEval = self:getEvaluation(state)
  local bestAction = nil
  local bestTarget = nil
  local input = ActionInput(nil, user)
  for i = 1, #possibleActions do
    input.action = possibleActions[i]
    local possibleTargets = input.action:potencialTargets(input)
    for j = 1, #possibleTargets do
      input.target = possibleTargets[i]
      local newState = state:applyAction(input)
      local eval = self:getEvaluation(newState)
      if eval > bestEval then
        bestEval = eval
        bestAction = input.action
        bestTarget = input.target
      end
      print(eval)
    end
  end
  input.target = bestTarget
  input.action = bestAction
  return input
end

---------------------------------------------------------------------------------------------------
-- Custom
---------------------------------------------------------------------------------------------------

-- Evaluation function. By default, the value is given by:
--  sum(HP of allies) - sum(HP of enemies).
function MonteCarlo:getEvaluation(state)
  local sum = 0
  local party = BattleManager.currentCharacter.battler.party
  for char in TroopManager.characterList:iterator() do
    if char.battler then
      local charState = state.characters[char]
      local hp = charState and charState.hp or char.battler.currentHP
      if char.battler.party == party then
        sum = sum + hp
      else
        sum = sum - hp
      end
    end
  end
  return sum
end

return MonteCarlo
