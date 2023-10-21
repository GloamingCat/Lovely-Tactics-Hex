
-- ================================================================================================

--- The rule for an AI that moves to the safest tile that still has a reachable target.
---------------------------------------------------------------------------------------------------
-- @classmod DefendRule

-- ================================================================================================

-- Imports
local BattleMoveAction = require('core/battle/action/BattleMoveAction')
local BattleTactics = require('core/battle/ai/BattleTactics')
local SkillRule = require('core/battle/ai/SkillRule')

-- Class table.
local DefendRule = class(SkillRule)

-- ------------------------------------------------------------------------------------------------
-- Execution
-- ------------------------------------------------------------------------------------------------

--- Overrides `SkillRule:onSelect`. 
-- @override
function DefendRule:onSelect(user)
  SkillRule.onSelect(self, user)
  -- Find tile to move
  local queue = BattleTactics.runFromEnemiesToAllies(user, self.input)
  if queue:isEmpty() then
    self.input = nil
    return
  end
  self.input.action = BattleMoveAction()
  self.input.target = queue:front()
end
--- String identifier.
-- @treturn string
function DefendRule:__tostring()
  return 'DefendRule: ' .. self.battler.key
end

return DefendRule
