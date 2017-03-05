
local AI = {}

function AI.nextAction(user)
  local skill = user.battler:getAttackSkill()
  BattleManager:selectTarget(skill:firstTarget())
  skill:onExecute()
end

return AI
