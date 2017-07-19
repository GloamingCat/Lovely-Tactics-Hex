
--[[===============================================================================================

TurnWindow
---------------------------------------------------------------------------------------------------
Window that opens in the start of a character turn.
Result = 1 means that the turn ended.

=================================================================================================]]

-- Imports
local ActionWindow = require('core/gui/battle/ActionWindow')
local MoveAction = require('core/battle/action/MoveAction')
local EscapeAction = require('core/battle/action/EscapeAction')
local VisualizeAction = require('core/battle/action/VisualizeAction')
local CallAction = require('core/battle/action/CallAction')
local TradeSkill = require('custom/skill/TradeSkill')
local BattleCursor = require('core/battle/BattleCursor')
local Button = require('core/gui/Button')

-- Alias
local mathf = math.field

local TurnWindow = class(ActionWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides ButtonWindow:createButtons.
function TurnWindow:createButtons()
  self.backupBattlers = PartyManager:backupBattlers()
  Button(self, Vocab.attack, Icon.attack, self.onAttackAction, self.attackEnabled)
  Button(self, Vocab.move, Icon.move, self.onMoveAction, self.moveEnabled)
  Button(self, Vocab.skill, Icon.skill, self.onSkill, self.skillEnabled)
  Button(self, Vocab.item, Icon.item, self.onItem, self.itemEnabled)
  Button(self, Vocab.trade, Icon.trade, self.onTradeAction, self.tradeEnabled)
  Button(self, Vocab.escape, Icon.escape, self.onEscapeAction, self.escapeEnabled)
  Button(self, Vocab.wait, Icon.wait, self.onWait)
  Button(self, Vocab.callAlly, Icon.callAlly, self.onCallAllyAction, self.callAllyEnabled)
  self.userCursor = BattleCursor()
  self.content:add(self.userCursor)
end

---------------------------------------------------------------------------------------------------
-- Confirm callbacks
---------------------------------------------------------------------------------------------------

-- "Attack" button callback.
function TurnWindow:onAttackAction(button)
  self:selectAction(BattleManager.currentCharacter.battler.attackSkill)
end
-- "Move" button callback.
function TurnWindow:onMoveAction(button)
  self:selectAction(MoveAction())
end
-- "Trade" button callback.
function TurnWindow:onTradeAction(button)
  self:selectAction(TradeSkill())
end
-- "Escape" button callback.
function TurnWindow:onEscapeAction(button)
  self:selectAction(EscapeAction())
end
-- "Call Ally" button callback.
function TurnWindow:onCallAllyAction(button)
  self:selectAction(CallAction())
end
-- "Skill" button callback. Opens Skill Window.
function TurnWindow:onSkill(button)
  self:changeWindow(self.GUI.skillWindow)
end
-- "Item" button callback. Opens Item Window.
function TurnWindow:onItem(button)
  self:changeWindow(self.GUI.itemWindow)
end
-- "Wait" button callback. End turn.
function TurnWindow:onWait(button)
  self.result = 0
end
-- Overrides ButtonWindow:onCancel.
function TurnWindow:onCancel()
  self:selectAction(VisualizeAction())
  self.result = nil
end

---------------------------------------------------------------------------------------------------
-- Enable Conditions
---------------------------------------------------------------------------------------------------

-- Attack condition. Enabled if there are tiles to move to or if there are any
--  enemies that the skill can reach.
function TurnWindow:attackEnabled(button)
  if self:moveEnabled(button) then
    return true
  else
    local user = BattleManager.currentCharacter
    local tile = user:getTile()
    local field = FieldManager.currentField
    local range = user.battler.attackSkill.data.range
    for i, j in mathf.radiusIterator(range, tile.x, tile.y, field.sizeX, field.sizeY) do
      if field:getObjectTile(i, j, tile.layer.height):hasEnemy(user.battler.party) then
        return true
      end
    end
  end
  return false
end
-- Move condition. Enabled if there are any tiles for the character to move to.
function TurnWindow:moveEnabled(button)
  local user = BattleManager.currentCharacter.battler
  if user.state.steps <= 0 then
    return false
  end
  for path in BattleManager.pathMatrix:iterator() do
    if path and path.totalCost <= user.state.steps then
      return true
    end
  end
  return false
end
-- Skill condition. Enabled if character has any skills to use.
function TurnWindow:skillEnabled(button)
  return self.GUI.skillWindow ~= nil
end
-- Item condition. Enabled if character has any items to use.
function TurnWindow:itemEnabled(button)
  return self.GUI.itemWindow ~= nil
end
-- Trade condition. Enabled if there are any characters nearby that have items.
function TurnWindow:tradeEnabled()
  -- TODO
  return false
end
-- Escape condition. Only escapes if the character is in a tile of their party.
function TurnWindow:escapeEnabled()
  if not BattleManager.params.escapeEnabled and #PartyManager:onFieldBattlers() == 1 then
    return false
  elseif not Battle.partyTileEscape then
    return true
  end
  local userParty = BattleManager.currentCharacter.battler.party
  local tileParty = BattleManager.currentCharacter:getTile().gui.party
  return userParty == tileParty
end
-- Call Ally condition. Enabled if there any any backup members.
function TurnWindow:callAllyEnabled()
  return TroopManager:getMemberCount() < Battle.maxMembers and not self.backupBattlers:isEmpty()
end

---------------------------------------------------------------------------------------------------
-- General info
---------------------------------------------------------------------------------------------------

-- Overrides ButtonWindow:colCount.
function TurnWindow:colCount()
  return 2
end
-- Overrides ButtonWindow:rowCount.
function TurnWindow:rowCount()
  return 4
end
-- Overrides Window:show.
function TurnWindow:show(add)
  local user = BattleManager.currentCharacter
  self.userCursor:setCharacter(user)
  ActionWindow.show(self, add)
end
-- String identifier.
function TurnWindow:__tostring()
  return 'TurnWindow'
end

return TurnWindow
