
-- ================================================================================================

--- Removes the current turn's character from the field.
-- It is executed when players chooses the "Escape" button.
---------------------------------------------------------------------------------------------------
-- @battlemod EscapeAction
-- @extend BattleAction

-- ================================================================================================

-- Imports
local BattleAction = require('core/battle/action/BattleAction')
local BattleMoveAction = require('core/battle/action/BattleMoveAction')
local BattleTactics = require('core/battle/ai/BattleTactics')
local ConfirmMenu = require('core/gui/common/ConfirmMenu')

-- Class table.
local EscapeAction = class(BattleAction)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam boolean move Flag to allow the usar to move to a party tile.
-- @param ... Any arguments passed to `BattleAction:init`.
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
-- @override
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
--- Overrides `BattleAction:onActionMenu`. 
-- @override
function EscapeAction:onActionMenu(input)
  local confirm = MenuManager:showMenuForResult(ConfirmMenu(input.menu))
  if confirm == 1 then
    return self:onConfirm(input)
  else
    return self:onCancel(input)
  end
end
--- Overrides `BattleAction:execute`. Executes the escape animation for the given character.
-- @override
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
-- @coroutine
-- @tparam ActionInput input User's input.
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
-- @override
function EscapeAction:canExecute(input)
  local userParty = input.user.party
  local tileParty = input.user:getTile().party
  return userParty == tileParty or input.target ~= nil
end

return EscapeAction
