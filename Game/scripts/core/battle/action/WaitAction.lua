
--[[===============================================================================================

WaitAction
---------------------------------------------------------------------------------------------------
The BattleAction that is executed when players chooses the "Wait" button.

=================================================================================================]]

-- Imports
local BattleAction = require('core/battle/action/BattleAction')

local WaitAction = class(BattleAction)

---------------------------------------------------------------------------------------------------
-- Initilization
---------------------------------------------------------------------------------------------------

-- Constructor.
function WaitAction:init()
  BattleAction.init(self, 0, 0, '')
end

---------------------------------------------------------------------------------------------------
-- Callback
---------------------------------------------------------------------------------------------------

-- Overrides BattoeAction:onActionGUI.
function WaitAction:onActionGUI(input)
  return self:onConfirm(input)
end

function WaitAction:onConfirm(input)
  return { endTurn = true, endCharacterTurn = true }
end

return WaitAction
