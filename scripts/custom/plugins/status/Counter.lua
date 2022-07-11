
--[[===============================================================================================

Counter
---------------------------------------------------------------------------------------------------
Makes a character attack back if hit.

-- Battler parameters:
The skill used when character counter-attacks is defined by <counter> tag. If not set, than this
battler does not counter-attack.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local Battler = require('core/battle/battler/Battler')
local SkillAction = require('core/battle/action/SkillAction')

---------------------------------------------------------------------------------------------------
-- Skill Action
---------------------------------------------------------------------------------------------------

-- Override. Checks for characters that counter attack.
local SkillAction_allTargetsEffect = SkillAction.allTargetsEffect
function SkillAction:allTargetsEffect(input, originTile)
  local allTargets = SkillAction_allTargetsEffect(self, input, originTile)
  if not self.offensive or self.counter then
    return allTargets
  end
  for i = #allTargets, 1, -1 do
    for targetChar in allTargets[i].characterList:iterator() do
      if targetChar.battler and targetChar.battler:isActive() and targetChar.battler:counterAttacks() then
        targetChar.battler:attack(targetChar, input.user:getTile())
      end
    end
  end
  return allTargets
end

---------------------------------------------------------------------------------------------------
-- Battler
---------------------------------------------------------------------------------------------------

-- Checks if this character counter-attacks.
function Battler:counterAttacks()
  for status in self.statusList:iterator() do
    if status.tags.counter then
      return true
    end
  end
  return false
end
-- Attacks the given character.
function Battler:attack(user, target)
  local skill = self.attackSkill
  if self.tags.counter then
    skill = SkillAction(tonumber(self.tags.counter))
  end
  local input = ActionInput(skill, user, target)
  if input:canExecute() then
    skill.counter = true
    local result = input:execute()
    skill.counter = false
    return result
  end
end
