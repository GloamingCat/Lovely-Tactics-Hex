
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
  self.steps = param and param.steps or 2
  ArtificialInteligence.init(self, key, battler, param and param.parallel)
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides ArtificialInteligence:nextAction.
function MonteCarlo:runTurn(it, user)
  --PROFI:start()
  local state = BattleState()
  local eval, input = self:getMax(it, user.battler.party, state, user, self.steps)
  --print(eval, input.action, input.target)
  input.skipAnimations = BattleManager.params.skipAnimations
  input.random = nil
  print(input)
  print(user:getTile())
  --PROFI:stop()
  --PROFI:writeReport( 'montecarlo profi.txt' )
  return input:execute()
end

-- @param(party : number) the party of the actual current user
-- @param(state : BattleState) current simulated state
-- @param(user : Character) current simulated user
-- @param(depth : number) max depth of the tree
-- @ret(number) the maximum possible score for the given party
-- @ret(ActionInput) the action that leads to that score
function MonteCarlo:getMax(it, party, state, user, depth)
  local inputs = self:getInputs(user)
  local bestEval = -math.huge
  local bestInput = nil
  for i = 1, #inputs do
    local input = inputs[i]
    local newState, newUser, newIt = state:applyInput(input, it)
    local eval
    if depth == 0 then
      eval = self:estimateEvaluation(party)
    else
      if newUser.battler.party == party then
        eval = self:getMax(newIt, party, newState, newUser, depth - 1) -- Ally
      else
        eval = self:getMin(newIt, party, newState, newUser, depth - 1) -- Enemy
      end
    end
    if eval > bestEval then
      bestEval = eval
      bestInput = input
    end
    state:revert()
  end
  return bestEval, bestInput
end

-- @param(party : number) the party of the actual current user
-- @param(state : BattleState) current simulated state
-- @param(user : Character) current simulated user
-- @param(depth : number) max depth of the tree
-- @ret(number) the minimum possible score for the given party
-- @ret(ActionInput) the action that leads to that score
function MonteCarlo:getMin(it, party, state, user, depth)
  local inputs = self:getInputs(user)
  local worstEval = math.huge
  local bestInput = nil
  for i = 1, #inputs do
    local input = inputs[i]
    local newState, newUser, newIt = state:applyInput(input, it)
    local eval
    if depth == 0 then
      eval = self:estimateEvaluation(party)
    else
      if newUser.battler.party == party then
        eval = self:getMax(newIt, party, newState, newUser, depth - 1) -- Ally
      else
        eval = self:getMin(newIt, party, newState, newUser, depth - 1) -- Enemy
      end
    end
    if eval < worstEval then
      worstEval = eval
      bestInput = input
    end
    state:revert()
  end
  return worstEval, bestInput
end

---------------------------------------------------------------------------------------------------
-- Potencial inptus
---------------------------------------------------------------------------------------------------

-- @param(user : Character)
-- @ret(table) array of ActionInput objects
function MonteCarlo:getInputs(user)
  --if PROFI then
  --  PROFI:start()
  --end
  local input = ActionInput.newSimulation(nil, user)
  local inputs = {}
  local actions = self:getCharacterActions(user)
  for i = 1, #actions do
    input.action = actions[i]
    self:addPotentialInputs(inputs, input)
  end
  --if PROFI then
  --  PROFI:stop()
  --  PROFI:writeReport('getInputs profi.txt' )
  --  PROFI = nil
  --end
  print('Possible actions: ' .. #inputs)
  return inputs
end

-- Selects potential inputs for the given action.
-- By default, selects all tiles that are selectable and reachable.
-- @param(array : table) an array of ActionInputs
-- @param(input : ActionInput) input with the action
function MonteCarlo:addPotentialInputs(array, input)
  for tile in FieldManager.currentfield:gridIterator() do
    if tile.gui.selectable and tile.gui.reachable then
      array[#array] = ActionInput.newSimulation(input.action, input.user, tile)
    end
  end
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
