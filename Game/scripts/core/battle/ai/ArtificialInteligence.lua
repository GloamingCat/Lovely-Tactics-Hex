
--[[===============================================================================================

ArtificialInteligence
---------------------------------------------------------------------------------------------------
Implements basic functions to be used in AI classes.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')

-- Alias
local rand = love.math.random

local ArtificialInteligence = class()

-- Executes next action of the current character, when it's the character's turn.
-- By default, just skips turn, with no time loss.
-- @param(user : Character)
-- @ret(number)
function ArtificialInteligence:nextAction(user)
  return 0
end

-- @param(character : Character)
-- @ret(table) array of actions
function ArtificialInteligence:getCharacterActions(character)
  local b = character.battler
  return {b.attackSkill, unpack(b.skillList)}
end

-- Executes action in the best target.
-- @param(action : BattleAction)
-- @param(user : Character)
-- @ret(number)
function ArtificialInteligence:executeActionBest(action, user)
  local input = ActionInput(action, user)
  action:onSelect(input)
  input.target = action:bestTarget(input)
  return action:onConfirm(input)
end

-- Executes action in a random target.
-- @param(action : BattleAction)
-- @param(user : Character)
-- @ret(number)
function ArtificialInteligence:executeActionRandom(action, user)
  local input = ActionInput(action, user)
  action:onSelect(input)
  local targets = action:potencialTargets(input)
  input.target = targets[love.math.random(#targets)]
  return action:onConfirm(input)
end

-- Gets a random action from the action list given by ArtificialInteligence:getCharacterActions.
-- @param(character : Character)
-- @ret(BattleAction)
function ArtificialInteligence:getRandomAction(character)
  local actions = self:getCharacterActions(character)
  return actions[rand(#actions)]
end

return ArtificialInteligence
