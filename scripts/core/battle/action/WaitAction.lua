
-- ================================================================================================

--- The BattleAction that is executed when players chooses the "Wait" button.
---------------------------------------------------------------------------------------------------
-- @classmod WaitAction

-- ================================================================================================

-- Imports
local BattleAction = require('core/battle/action/BattleAction')

-- Class table.
local WaitAction = class(BattleAction)

-- ------------------------------------------------------------------------------------------------
-- Callback
-- ------------------------------------------------------------------------------------------------

--- Overrides `BattleAction:onActionGUI`. 
-- @override onActionGUI
function WaitAction:onActionGUI(input)
  return self:onConfirm(input)
end
--- Overrides `FieldAction:onConfirm`. 
-- @override onConfirm
function WaitAction:onConfirm(input)
  return { endCharacterTurn = true, endTurn = #TurnManager.turnCharacters == 1 }
end

return WaitAction
