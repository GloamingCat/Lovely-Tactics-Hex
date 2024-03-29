
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

-- Overrides BattleAction:onActionGUI.
function WaitAction:onActionGUI(input)
  return self:onConfirm(input)
end
-- Overrides BattleAction:onConfirm.
function WaitAction:onConfirm(input)
  return { endCharacterTurn = true, endTurn = #TurnManager.turnCharacters == 1 }
end

return WaitAction
