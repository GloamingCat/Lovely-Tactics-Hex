
--[[===============================================================================================

Default Monte-Carlo
---------------------------------------------------------------------------------------------------
Overrides the potential inputs to better performance.
Evaluates the current state by the sum of each character's state values.

=================================================================================================]]

-- Imports
local MoveAction = require('core/battle/action/MoveAction')
local BattleTactics = require('core/battle/ai/BattleTactics')
local ActionInput = require('core/battle/action/ActionInput')
local MonteCarlo = require('core/battle/ai/montecarlo/MonteCarlo')

-- Alias
local stateValues = Config.battle.stateValues
local min = math.min

-- Constants
local moveAction = MoveAction()

local DefaultMC = class(MonteCarlo)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function DefaultMC:init(battler, param)
  local key = 'DefaultMC ' .. battler.battlerID
  param = self:decodeParam(param)
  MonteCarlo.init(self, key, battler, param)
  self.moves = param and param.moves or 2
  self.targets = param and param.targets or 3
end

---------------------------------------------------------------------------------------------------
-- Potential inputs
---------------------------------------------------------------------------------------------------

function DefaultMC:getInputs(user)
  local inputs = {}
  -- Default attack
  local input = ActionInput.newSimulation(user.battler.attackSkill, user)
  self:addSkillInputs(inputs, input)
  -- Each skill in skill list
  for skill in user.battler.skillList:iterator() do
    input.action = skill
    self:addSkillInputs(inputs, input)
  end
  -- Movement-only
  input.action = moveAction
  input.moveTarget = nil
  local moves = BattleTactics.runAway(user):toList()
  local moveCount = min(#moves, self.moves)
  for i = 1, moveCount do
    input.target = moves[i]
    inputs[#inputs + 1] = ActionInput.newSimulationFromInput(input)
  end
  -- Wait
  input.action = nil
  input.target = nil
  inputs[#inputs + 1] = ActionInput.newSimulationFromInput(input)
  return inputs
end

-- Overrides MonteCarlo:addPotentialInputs.
function DefaultMC:addSkillInputs(array, input)
  input.moveTarget = nil
  input.action:onSelect(input)
  -- Get targets with greater damage
  local targets = BattleTactics.areaTargets(input):toList()
  --print('targets', #targets)
  if input.action.range > 1 then
    -- Ranged skills
    local targetCount = min(#targets, self.targets)
    for i = 1, targetCount do
      input.target = targets[i]
      local moves = BattleTactics.runAway(input.user, input):toList()
      --print('moves', #moves)
      local moveCount = min(#moves, self.moves)
      for j = 0, moveCount do
        input.moveTarget = moves[j]
        array[#array + 1] = ActionInput.newSimulationFromInput(input)
      end
    end
  else
    -- Melee skills
    local targetCount = min(#targets, self.targets)
    for i = 1, targetCount do
      input.target = targets[i]
      array[#array + 1] = ActionInput.newSimulationFromInput(input)
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Evaluation function
---------------------------------------------------------------------------------------------------

-- Overrides MonteCarlo:estimateEvaluation.
function DefaultMC:estimateEvaluation()
  local party = self.battler.party
  -- Average life poitns
  local meanLife = 0
  for char in TroopManager.characterList:iterator() do
    meanLife = meanLife + char.battler:absoluteLifePoints()
  end
  meanLife = meanLife / TroopManager.characterList.size
  
  local score = 0
  for char in TroopManager.characterList:iterator() do
    local charScore = 0
    if char.battler:isAlive() then
      --charScore = char.battler:absoluteLifePoints()
      --charScore = charScore + char.battler:relativeLifePoints() * meanLife
      --charScore = charScore - (1 - char.battler:relativeTurnCount()) / char.battler.turnStep()
    else
      charScore = -meanLife
    end
    if char.battler.party == party then
      score = score + charScore
    else
      score = score - charScore
    end
  end
  return score
end

return DefaultMC
