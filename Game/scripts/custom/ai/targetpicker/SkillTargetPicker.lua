
--[[===============================================================================================

SkillTargetPicker
---------------------------------------------------------------------------------------------------
A general TargetPicker for SkillActions.

=================================================================================================]]

-- Imports
local TargetPicker = require('core/ai/TargetPicker')
local BattleTactics = require('core/ai/BattleTactics')

local SkillTargetPicker = class(TargetPicker)

-- Overrides TargetPicker:potentialTargets.
local old_potentialTargets = SkillTargetPicker.potentialTargets
function SkillTargetPicker:potentialTargets(input)
  if input.action.radius > 1 then
    return BattleTactics.areaTargets(input):toList()
  else
    return BattleTactics.closestCharacters(input):toList()
  end
end

-- Overrides TargetPicker:potentialMovements.
local old_potentialMovements = SkillTargetPicker.potentialMovements
function SkillTargetPicker:potentialMovements(input)
  if input.action.range > 1 then
    local queue = BattleTactics.runAway(input.user, input)
    local list = queue:toList()
    list:add(input.user:getTile())
    return queue:toList()  
  else
    return old_potentialMovements(self, input)
  end
end

return SkillTargetPicker
