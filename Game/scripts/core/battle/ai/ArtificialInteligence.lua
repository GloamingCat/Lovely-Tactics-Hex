
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

---------------------------------------------------------------------------------------------------
-- Action Selection
---------------------------------------------------------------------------------------------------

-- @param(character : Character)
-- @ret(table) array of actions
function ArtificialInteligence:getCharacterActions(character)
  local b = character.battler
  return {b.attackSkill, unpack(b.skillList)}
end

-- Gets a random action from the action list given by ArtificialInteligence:getCharacterActions.
-- @param(character : Character)
-- @ret(BattleAction)
function ArtificialInteligence:getRandomAction(character)
  local actions = self:getCharacterActions(character)
  return actions[rand(#actions)]
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Executes next action of the current character, when it's the character's turn.
-- By default, just skips turn, with no time loss.
-- @param(it : number) the number of iterations since last turn
-- @param(user : Character)
-- @ret(number)
function ArtificialInteligence:nextAction(it, user)
  return 0 -- Abstract.
end

return ArtificialInteligence
