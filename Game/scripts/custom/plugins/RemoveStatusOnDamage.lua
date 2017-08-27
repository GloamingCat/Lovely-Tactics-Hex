
--[[===============================================================================================

RemoveStatusOnDamage
---------------------------------------------------------------------------------------------------
Provides the support for status that are removed 

=================================================================================================]]

local Status = require('core/battle/Status')

function Status:onSkillEffectStart(char, input, results)
  if results.damage and self.tags.removeOnDamage then
    self:remove(char)
  end
end