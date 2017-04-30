
--[[===============================================================================================

Berserker AI
---------------------------------------------------------------------------------------------------
An AI that picks the first character and attacks them.

=================================================================================================]]

local Berserker = class()

function Berserker:nextAction(user)
  local skill = user.battler.attackSkill
  BattleManager:selectAction(skill)
  BattleManager:selectTarget(nil, skill:bestTarget(user))
  return skill:onConfirm(nil, user)
end

return Berserker
