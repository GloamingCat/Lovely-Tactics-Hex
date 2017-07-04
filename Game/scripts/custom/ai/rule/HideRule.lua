
--[[===============================================================================================

HideRule
---------------------------------------------------------------------------------------------------
The rule for an AI that moves to the farest tile that still has a reachable target.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local BattleTactics = require('core/battle/ai/BattleTactics')
local MoveAction = require('core/battle/action/MoveAction')
local PathFinder = require('core/battle/ai/PathFinder')
local AIRule = require('core/battle/ai/AIRule')

local HideRule = class(AIRule)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function HideRule:init(action)
  local name = action.skillID or tostring(action)
  AIRule.init(self, 'Hide: ' .. name, action)
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides AIRule:onSelect.
function HideRule:onSelect(it, user)
  local skill = self.input.action
  self.input.user = user
  skill:onSelect(self.input)
  
  -- Find tile to attack
  self.input.action = skill
  skill:onSelect(self.input)
  local queue = BattleTactics.closestCharacters(self.input)
  if queue:isEmpty() then
    self.input = nil
    return
  end
  self.input.target = queue:front()
  
  -- Find tile to move
  queue = BattleTactics.runAway(user, self.input)
  if not queue:isEmpty() then
    self.input.target = queue:front()
    self.input.action = MoveAction()
    self.input:execute()
  end
end

-- Overrides AIRule:execute.
function HideRule:execute()
  return self.input:execute()
end

return HideRule
