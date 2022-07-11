
--[[===============================================================================================

SkillRule
---------------------------------------------------------------------------------------------------
An AIRule that executes a skill defined by the tag field "id", which means the id-th skill of the
battler. If there's no such field, it will use battler's attack skill.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local AIRule = require('core/battle/ai/AIRule')

local SkillRule = class(AIRule)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(...) AIRule constructor arguments.
function SkillRule:init(...)
  AIRule.init(self, ...)
  local id = self.tags and tonumber(self.tags.id)
  self.skill = id and self.battler.skillList[id] or self.battler.attackSkill
  assert(self.skill, tostring(self.battler) .. ' does not have a skill!')
end
-- Prepares the rule to be executed (or not, if it1s not possible).
-- @param(user : Character)
function SkillRule:onSelect(user)
  self.input = ActionInput(self.skill, user or TurnManager:currentCharacter())
  self.skill:onSelect(self.input)
end

return SkillRule
