
--[[===============================================================================================

Berserker AI
---------------------------------------------------------------------------------------------------
An AI that picks the first character and attacks them.

=================================================================================================]]

local Berserker = class()

function Berserker:nextAction(user)
  local action = user.battler.attackSkill
  BattleManager:selectAction(action)
  BattleManager:selectTarget(nil, action:firstTarget(user))
  return action:onConfirm(nil, user)
end

return Berserker
