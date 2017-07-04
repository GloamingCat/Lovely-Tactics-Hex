
--[[===============================================================================================

MonteCarlo AI
---------------------------------------------------------------------------------------------------
An AI based on Monte Carlo Tree Search, that chooses the better action considering the defined 
evaluation function.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local Queue = require('core/algorithm/Queue')
local BattleState = require('core/battle/ai/montecarlo/BattleState')
local ArtificialInteligence = require('core/battle/ai/ArtificialInteligence')

-- Alias
local floor = math.floor
local addArray = util.addArray

local MonteCarlo = class(ArtificialInteligence)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor. Starts decision tree as empty.
-- @param(battler : Battler)
-- @param(param : string) the script param (used as the maximum tree depth)
function MonteCarlo:init(key, battler, param)
  self.steps = param and param.steps or 1
  ArtificialInteligence.init(self, key, battler, param and param.parallel)
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides ArtificialInteligence:nextAction.
function MonteCarlo:runTurn(it, user)
  --PROFI:start()
  local state = BattleState()
  local eval, input = self:getMax(it, state, user, self.steps)
  --print(eval, input.action, input.target)
  input.skipAnimations = BattleManager.params.skipAnimations
  input.random = nil
  print(input)
  print(user:getTile())
  --PROFI:stop()
  --PROFI:writeReport( 'montecarlo profi.txt' )
  return input:execute()
end

-- @param(state : BattleState) current simulated state
-- @param(user : Character) current simulated user
-- @param(depth : number) max depth of the tree
-- @ret(number) the maximum possible score for the given party
-- @ret(ActionInput) the action that leads to that score
function MonteCarlo:getMax(it, state, user, depth)
  local inputs = self:getInputs(user)
  --print('ally', user, #inputs)
  local bestEval = -math.huge
  local bestInput = nil
  for i = 1, #inputs do
    local eval = self:getEvaluation(it, state, inputs[i], depth)
    if eval > bestEval then
      bestEval = eval
      bestInput = inputs[i]
    end
    state:revert()
  end
  print('ally', user, #inputs, bestEval, bestInput.action)
  return bestEval, bestInput
end

-- @param(state : BattleState) current simulated state
-- @param(user : Character) current simulated user
-- @param(depth : number) max depth of the tree
-- @ret(number) the minimum possible score for the given party
-- @ret(ActionInput) the action that leads to that score
function MonteCarlo:getMin(it, state, user, depth)
  local inputs = self:getInputs(user)
  local worstEval = math.huge
  local bestInput = nil
  for i = 1, #inputs do
    local eval = self:getEvaluation(it, state, inputs[i], depth)
    if eval < worstEval then
      worstEval = eval
      bestInput = inputs[i]
    end
    state:revert()
  end
  print('enemy', user, #inputs, worstEval, bestInput.action)
  return worstEval, bestInput
end

function MonteCarlo:getEvaluation(it, state, input, depth)
  local newState, newUser, newIt = state:applyInput(input, it)
  if depth == 0 then
    return self:estimateEvaluation()
  else
    if newUser.battler.party == self.battler.party then
      return self:getMax(newIt, newState, newUser, depth - 1) -- Ally
    else
      return self:getMin(newIt, newState, newUser, depth - 1) -- Enemy
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Potencial inptus
---------------------------------------------------------------------------------------------------

-- @param(user : Character)
-- @ret(table) array of ActionInput objects
function MonteCarlo:getInputs(user)
  return nil -- Abstract.
end

---------------------------------------------------------------------------------------------------
-- Evaluation
---------------------------------------------------------------------------------------------------

-- Estimates a score in the current simulated state for the given party.
-- @param(party : number) the party ID
-- @ret(number) the evaluation result
function MonteCarlo:estimateEvaluation(party)
  return nil -- Abstract.
end

return MonteCarlo
