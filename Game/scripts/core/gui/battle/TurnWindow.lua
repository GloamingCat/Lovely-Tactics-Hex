
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

-- Alias
local mathf = math.field

local TurnWindow = class(ActionWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides ButtonWindow:createButtons.
function TurnWindow:createButtons()
  self.backupBattlers = PartyManager:backupBattlers()
  self:addButton('Attack', nil, self.onAttackAction, self.attackEnabled)
  self:addButton('Move', nil, self.onMoveAction, self.moveEnabled)
  self:addButton('Skill', nil, self.onSkill, self.skillEnabled)
  self:addButton('Item', nil, self.onItem, self.itemEnabled)
  self:addButton('Trade', nil, self.onTradeAction, self.tradeEnabled)
  self:addButton('Escape', nil, self.onEscapeAction, self.escapeEnabled)
  self:addButton('Wait', nil, self.onWait)
  self:addButton('Call Ally', nil, self.onCallAllyAction, self.callAllyEnabled)
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
  self.GUI:hide()
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
    for i, j in mathf.radiusIterator(range + 1, tile.x, tile.y) do
      if i >= 1 and j >= 1 and i <= field.sizeX and j <= field.sizeY and
          field:getObjectTile(i, j, tile.layer.height):hasEnemy(user.battler.party) then
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
  local user = BattleManager.currentCharacter.battler
  return not user.skillList:isEmpty()
end

-- Item condition. Enabled if character has any items to use.
function TurnWindow:itemEnabled(button)
  local user = BattleManager.currentCharacter.battler
  return not user.inventory:isEmpty()
end

-- Trade condition. Enabled if there are any characters nearby that have items.
function TurnWindow:tradeEnabled()
  -- TODO
  return false
end

-- Escape condition. Only escapes if the character is in a tile of their party.
function TurnWindow:escapeEnabled()
  local userParty = BattleManager.currentCharacter.battler.party
  local tileParty = BattleManager.currentCharacter:getTile().party
  return userParty == tileParty
end

-- Call Ally condition. Enabled if there any any backup members.
function TurnWindow:callAllyEnabled()
  return not self.backupBattlers:isEmpty()
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
local old_show = TurnWindow.show
function TurnWindow:show(add)
  local user = BattleManager.currentCharacter
  self.userCursor:setCharacter(user)
  old_show(self, add)
end

-- String identifier.
function TurnWindow:__tostring()
  return 'TurnWindow'
end

return TurnWindow
