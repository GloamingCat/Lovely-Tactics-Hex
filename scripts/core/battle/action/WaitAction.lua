
--[[===============================================================================================

WaitAction
---------------------------------------------------------------------------------------------------
The BattleAction that is executed when players chooses the "Wait" button.

=================================================================================================]]

-- Imports
local BattleAction = require('core/battle/action/BattleAction')

local WaitAction = class(BattleAction)

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
