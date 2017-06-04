
--[[===============================================================================================

MonteCarlo AI
---------------------------------------------------------------------------------------------------
An AI based on Monte Carlo Tree Search, that chooses the better action considering the defined 
evaluation function.

=================================================================================================]]

-- Imports
local Queue = require('core/algorithm/Queue')
local BattleState = require('core/battle/ai/BattleState')
local ArtificialInteligence = require('core/battle/ai/ArtificialInteligence')
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
  local state = BattleState()
  local input = ActionInput(nil, user)
  input = self:getEvaluation(user, state, self.steps)
  input.action:onSelect(input)
  return input.action:onConfirm(input)
end

-- @param(user : Character)
-- @param(state : BattleState)
-- @param(depth : number)
-- @ret(ActionInput) the most promising input
-- @ret(number) score
function MonteCarlo:getEvaluation(user, state, depth)
	if depth == 0 then
		return self:estimateEvaluation()
	else
		local bestEval = -math.huge
    local bestInput = nil
    local possibleInputs = self:getPossibleInputs(user)
		for i = 1, #possibleInputs do
      local input = possibleInputs[i]
      -- Apply action modifications
			local newState = state:addInput(input)
      -- Get evaluation
			local _, eval = self:getEvaluation(user, newState, depth - 1)
			if eval > bestEval then
				bestEval = eval
        bestInput = input
			end
      -- Back to previous state
			state:revert()
		end
    return bestInput, bestEval
	end
end

-- @param(user : Character)
-- @ret(table) array of ActionInput objects
function MonteCarlo:getPossibleInputs(user)
  local inputs = {}
  local actions = ArtificialInteligence:getCharacterActions(user)
  for i = 1, #actions do
    local action = actions[i]
    local input = ActionInput(action, user)
    local targets = action:possibleTargets(input)
    for j = 1, #targets do
      local target = targets[j]
      inputs[#inputs + 1] = ActionInput(action, user, target)
    end
  end
  return inputs
end

---------------------------------------------------------------------------------------------------
-- Custom
---------------------------------------------------------------------------------------------------

-- @ret(number)
function MonteCarlo:estimateEvaluation()
  return 0 -- TODO
end

return MonteCarlo
