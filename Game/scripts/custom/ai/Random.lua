
--[[===============================================================================================

Random AI
---------------------------------------------------------------------------------------------------
An AI that chooses a random skill from all possible skills and a random target from all valid 
targets hiven by the chosen skill.

=================================================================================================]]

local Random = class()

function Random:nextAction(user)
  local skill = nil
  local max = user.battler.skillList.size + 1
  local r = love.math.random(max)
  if r < max then
    skill = user.battler.skillList[r]
  else
    skill = user.battler.attackSkill
  end
  local targets = skill:potencialTargets(user)
  r = love.math.random(#targets)
  BattleManager:selectAction(skill)
  BattleManager:selectTarget(nil, targets[r])
  skill:onConfirm()
end

return Random
