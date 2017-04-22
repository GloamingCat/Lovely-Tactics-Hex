
local Default = {}

function Default.nextAction(user)
  local action = user.battler.attackSkill:asAction()
  BattleManager:selectAction(action)
  BattleManager:selectTarget(action:firstTarget())
  return action:onConfirm()
end

return Default
