
--[[===============================================================================================

AreaTarget
---------------------------------------------------------------------------------------------------
Adds more target restrictions to area skills.

-- Skill parameters:
To enable this, add the tag <target> to a skill with one or more of these flags in the values:
 - switch: make it affect any character regardless of party;
 - living: only affects tiles with living characters;
 - dead: only affects tiles with dead characters.

=================================================================================================]]

-- Imports
local SkillAction = require('core/battle/action/SkillAction')

---------------------------------------------------------------------------------------------------
-- SkillAction
---------------------------------------------------------------------------------------------------

local SkillAction_receivesEffect = SkillAction.receivesEffect
function SkillAction:receivesEffect(input, char)
  if not SkillAction_receivesEffect(self, input, char) then
    return false
  end
  local target = self.tags.target or ''
  if char.battler:isAlive() then
    if target:find('dead') then
      return false
    end
  else
    if target:find('living') then
      return false
    end
  end
  if target:find('switch') then
    return true
  else
    local ally = input.user.party == char.party
    return (ally == self.support or (not ally) == self.offensive)
  end
end
