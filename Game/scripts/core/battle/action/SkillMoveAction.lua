
local MoveAction = require('core/battle/action/MoveAction')

--[[===========================================================================

A MoveAction with a different objetive (use a skill in a given target).

=============================================================================]]

local SkillMoveAction = MoveAction:inherit()

local old_init = SkillMoveAction.init
function SkillMoveAction:init(range, target, user)
  old_init(self, target, user)
  self.range = range
end

-- Overrides MoveAction:isFinal.
function SkillMoveAction:isFinal(tile)
  local cost = self:estimateCost(self.currentTarget, tile)
  return cost < self.range and not tile:hasColliders(self.user) 
end

return SkillMoveAction
