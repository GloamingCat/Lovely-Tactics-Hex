
--[[===============================================================================================

Default Monte-Carlo
---------------------------------------------------------------------------------------------------
Overrides the potential inputs to better performance.
Evaluates the current state by the sum of each character's state values.

=================================================================================================]]

-- Imports
local BattleTactics = require('core/battle/ai/BattleTactics')
local ActionInput = require('core/battle/action/ActionInput')
local MonteCarlo = require('core/battle/ai/montecarlo/MonteCarlo')

-- Alias
local stateValues = Config.battle.stateValues

local DefaultMC = class(MonteCarlo)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function DefaultMC:init(battler, param)
  local key = 'DefaultMC ' .. battler.battlerID
  MonteCarlo.init(self, key, battler, self:decodeParam(param))
end

---------------------------------------------------------------------------------------------------
-- Potential inputs
---------------------------------------------------------------------------------------------------

-- Overrides MonteCarlo:addPotentialInputs.
function DefaultMC:addPotentialInputs(array, input)
  input.moveTarget = nil
  if not input.action.calculateEffectResult then
    -- Non-skill actions
    array[#array + 1] = ActionInput.newSimulationFromInput(input)
  end
  input.action:onSelect(input)
  -- Get targets with greater damage
  local targets = BattleTactics.areaTargets(input):toList()
  print('targets', #targets)
  if input.action.range > 1 then
    -- Ranged skills
    for i = 1, #targets do
      input.target = targets[i]
      local moves = BattleTactics.runAway(input.user, input):toList()
      print('moves', #moves)
      for j = 1, #moves + 1 do
        input.moveTarget = moves[j]
        array[#array + 1] = ActionInput.newSimulationFromInput(input)
      end
    end
  else
    -- Melee skills
    for i = 1, #targets do
      input.target = targets[i]
      array[#array + 1] = ActionInput.newSimulationFromInput(input)
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Evaluation function
---------------------------------------------------------------------------------------------------

-- Overrides MonteCarlo:estimateEvaluation.
function DefaultMC:estimateEvaluation(party)
  local sum = 0
  for char in TroopManager.characterList:iterator() do
    if char.battler.party == party then
      for i = 1, #stateValues do
        sum = sum + char.battler.state[stateValues[i].shortName]
      end
    else
      for i = 1, #stateValues do
        sum = sum - char.battler.state[stateValues[i].shortName]
      end
    end
  end
  return sum
end

return DefaultMC
