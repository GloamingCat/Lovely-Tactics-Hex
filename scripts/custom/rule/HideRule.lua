
-- ================================================================================================

--- The rule for an AI that moves to the tile with less close enemies.
---------------------------------------------------------------------------------------------------
-- @battlemod HideRule
-- @extend AIRule

-- ================================================================================================

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local AIRule = require('core/battle/ai/AIRule')
local BattleMoveAction = require('core/battle/action/BattleMoveAction')
local BattleTactics = require('core/battle/ai/BattleTactics')

-- Class table.
local HideRule = class(AIRule)

-- ------------------------------------------------------------------------------------------------
-- Execution
-- ------------------------------------------------------------------------------------------------

--- Overrides `AIRule:onSelect`. 
-- @override
function HideRule:onSelect(user)
  user = user or TurnManager:currentCharacter()
  self.input = ActionInput(BattleMoveAction(), user)
  self.input.action:onSelect(self.input)
  -- Find tile to move
  local queue = BattleTactics.runAway(user, self.input)
  if queue:isEmpty() then
    self.input = nil
  else
    self.input.target = queue:front()
  end
end
-- For debugging.
function HideRule:__tostring()
  return 'HideRule: ' .. self.battler.key
end

return HideRule
