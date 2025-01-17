
-- ================================================================================================

--- Ends the current turn.
-- It is executed when players chooses the "Wait" button.
---------------------------------------------------------------------------------------------------
-- @battlemod WaitAction
-- @extend BattleAction

-- ================================================================================================

-- Imports
local BattleAction = require('core/battle/action/BattleAction')

-- Class table.
local WaitAction = class(BattleAction)

-- ------------------------------------------------------------------------------------------------
-- Callback
-- ------------------------------------------------------------------------------------------------

--- Overrides `BattleAction:onActionMenu`. 
-- @override
function WaitAction:onActionMenu(input)
  return self:onConfirm(input)
end
--- Overrides `FieldAction:onConfirm`. 
-- @override
function WaitAction:onConfirm(input)
  return { endCharacterTurn = true, endTurn = #TurnManager.turnCharacters == 1 }
end

return WaitAction
