
-- ================================================================================================

--- The BattleAction that is executed when players chooses the "Escape" button.
---------------------------------------------------------------------------------------------------
-- @classmod EscapeAction

-- ================================================================================================

-- Imports
local BattleAction = require('core/battle/action/BattleAction')
local BattleMoveAction = require('core/battle/action/BattleMoveAction')
local BattleTactics = require('core/battle/ai/BattleTactics')
local ConfirmGUI = require('core/gui/common/ConfirmGUI')

-- Class table.
local EscapeAction = class(BattleAction)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `BattleAction:init`. Sets animation speed.
-- @override init
function EscapeAction:init(move, ...)
  BattleAction.init(self, ...)
  self.animSpeed = 2
  self.hide = false
  if move then
    self.moveAction = BattleMoveAction()
  end
end

-- ------------------------------------------------------------------------------------------------
-- Callback
-- ------------------------------------------------------------------------------------------------

--- Overrides `BattleAction:onSelect`. 
-- @override onSelect
function EscapeAction:onSelect(input)
  BattleAction.onSelect(self, input)
  if self.moveAction and not self:canExecute(input) then
    -- Move to closest party tile.
    local moveInput = input:createMoveInput()
    moveInput.action:onSelect(moveInput)
    local queue = BattleTactics.closestMovableTiles(input.user, moveInput, function(tile)
        return tile.party == input.user.party
      end)
    if not queue:isEmpty() then
      input.target = queue:front()
    end
  end
end
--- Overrides `BattleAction:onActionGUI`. 
-- @override onActionGUI
function EscapeAction:onActionGUI(input)
  local confirm = GUIManager:showGUIForResult(ConfirmGUI(input.GUI))
  if confirm == 1 then
    return self:onConfirm(input)
  else
    return self:onCancel(input)
  end
end
--- Overrides `BattleAction:execute`. Executes the escape animation for the given character.
-- @override execute
function EscapeAction:execute(input)
  if input.moveResult then
    if input.moveResult.executed then
      return self:escape(input)
    else
      return { executed = false, endCharacterTurn = true }
    end
  else
    return self:escape(input)
  end
end
--- Removes character from field.
function EscapeAction:escape(input)
  local char = input.user
  local party = char.party
  if Config.sounds.escape then
    AudioManager:playSFX(Config.sounds.escape)
  end
  char:colorizeTo(nil, nil, nil, 0, self.animSpeed, true)
  local troop = TurnManager:currentTroop()
  troop:moveMember(char.key, self.hide and 2 or 1)
  TroopManager:deleteCharacter(char)
  if TroopManager:getMemberCount(party) == 0 then
    return { executed = true, endTurn = true, escaped = true }
  else
    return { executed = true, endCharacterTurn = true, escaped = false }
  end
end
--- Overrides `FieldAction:canExecute`. 
-- @override canExecute
function EscapeAction:canExecute(input)
  local userParty = input.user.party
  local tileParty = input.user:getTile().party
  return userParty == tileParty or input.target ~= nil
end

return EscapeAction
