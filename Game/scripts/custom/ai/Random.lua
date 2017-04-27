
--[[===============================================================================================

Random AI
---------------------------------------------------------------------------------------------------
An AI that chooses a random action from all possiblities and a random target from all valid 
targets hiven by the chosen action.

=================================================================================================]]

local Random = require('core/class'):new()

function Random:nextAction(user)
  local action = nil
  local max = user.battler.skillList.size + 1
  local r = love.math.random(max)
  if r < max then
    action = user.battler.skillList[r]:asAction()
  else
    action = user.battler.attackSkill:asAction()
  end
  BattleManager:selectAction(action)
  local targets = action:validTargets()
  r = love.math.random(#targets)
  BattleManager:selectTarget(targets[r])
  action:onConfirm()
end

return Random
