
--[[===============================================================================================

Chicken AI
---------------------------------------------------------------------------------------------------
An AI that moves to the farest tile that still has a reachable target.

=================================================================================================]]

-- Imports
local ArtificialInteligence = require('core/battle/ArtificialInteligence')
local ActionInput = require('core/battle/action/ActionInput')
local BattleTactics = require('core/algorithm/BattleTactics')
local MoveAction = require('core/battle/action/MoveAction')
local PathFinder = require('core/algorithm/PathFinder')

-- Alias
local expectation = math.randomExpectation

local Chicken = class(ArtificialInteligence)

-- Overrides ArtificialInteligence:nextAction.
function Chicken:nextAction(user)
  local skill = user.battler.attackSkill
  local input = ActionInput(skill, user)
  skill:onSelect(input)
  local queue = BattleTactics.runAway(user.battler.party, input)
  
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

return Chicken
