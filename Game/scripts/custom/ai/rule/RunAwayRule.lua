
--[[===============================================================================================

RunAwayRule
---------------------------------------------------------------------------------------------------
The rule for an AI that moves to the tile that is the farest from the enemies.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local BattleTactics = require('core/battle/ai/BattleTactics')
local MoveAction = require('core/battle/action/MoveAction')
local PathFinder = require('core/battle/ai/PathFinder')
local AIRule = require('core/battle/ai/AIRule')

local RunAwayRule = class(AIRule)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function RunAwayRule:init()
  AIRule.init(self, 'RunAway', MoveAction())
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides AIRule:onSelect.
function RunAwayRule:onSelect(it, user)
  self.input.user = user
  self.input.action:onSelect(self.input)
  
  -- Find tile to move
  local queue = BattleTactics.runAway(user)
  if queue:isEmpty() then
    self.input = nil
    return
  end
  self.input.target = queue:front()
end

return RunAwayRule
