
--[[===============================================================================================

Berserker AI
---------------------------------------------------------------------------------------------------
An AI that picks the first character and attacks them.

=================================================================================================]]

local ActionInput = require('core/battle/action/ActionInput')

local Berserker = class()

function Berserker:nextAction(user)
  local skill = user.battler.attackSkill
  local input = ActionInput(skill)
  skill:onSelect(input, user)
  input.target = skill:bestTarget(user)
  return skill:onConfirm(input)
end

return Berserker
