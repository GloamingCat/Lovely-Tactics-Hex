
local ActionWindow = require('custom/gui/battle/ActionWindow')
local MoveAction = require('core/battle/action/MoveAction')
local TradeAction = require('core/battle/action/TradeAction')
local EscapeAction = require('core/battle/action/EscapeAction')
local VisualizeAction = require('core/battle/action/VisualizeAction')
local CallAction = require('core/battle/action/CallAction')
local BattleCursor = require('core/battle/BattleCursor')
local mathf = math.field

--[[===========================================================================

Window that opens in the start of a character turn.
Result = 1 means that the turn ended.

=============================================================================]]

local TurnWindow = require('core/class'):inherit(ActionWindow)

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

-------------------------------------------------------------------------------
-- Confirm callbacks
-------------------------------------------------------------------------------

-- "Attack" button callback.
-- @param(button : Button) the button chosen
function TurnWindow:onAttackAction(button)
  local id = BattleManager.currentCharacter.battler.attackSkillID
  local skill = Database.skills[id + 1]
  print(skill.script.path)
  self:selectSkill(skill)
end

-- "Move" button callback.
-- @param(button : Button) the button chosen
function TurnWindow:onMoveAction(button)
  self:selectAction(MoveAction)
end

-- "Trade" button callback.
-- @param(button : Button) the button chosen
function TurnWindow:onTradeAction(button)
  self:selectAction(TradeAction)
end

-- "Escape" button callback.
-- @param(button : Button) the button chosen
function TurnWindow:onEscapeAction(button)
  self:selectAction(EscapeAction)
end

-- "Call Ally" button callback.
-- @param(button : Button) the button chosen
function TurnWindow:onCallAllyAction(button)
  self:selectAction(CallAction)
end

-- "Wait" button callback. End turn.
-- @param(button : Button) the button chosen
function TurnWindow:onWait(button)
  self.result = 1
end

-- "Skill" button callback. Opens Skill Window.
-- @param(button : Button) the button chosen
function TurnWindow:onSkill(button)
  self:hide(true)
  self.GUI.skillWindow:show(true)
  self.GUI.skillWindow:activate()
end

-- "Item" button callback. Opens Item Window.
-- @param(button : Button) the button chosen
function TurnWindow:onItem(button)
  self:hide(true)
  self.GUI.itemWindow:show(true)
  button.window.GUI.itemWindow:activate()
end

-------------------------------------------------------------------------------
-- Enable Conditions
-------------------------------------------------------------------------------

-- Attack condition. Enabled if there are tiles to move to or if there are any
--  enemies that the skill can reach.
function TurnWindow:attackEnabled(button)
  if self:moveEnabled(button) then
    return true
  else
    local user = BattleManager.currentCharacter
    local range = user.battler:getAttackSkill().range
    local tile = user:getTile()
    local field = FieldManager.currentField
    local iterator = mathf.radiusIterator(range, tile.x, tile.y, field.sizeX, field.sizeY)
    for i, j in iterator do
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
  if user.currentSteps <= 0 then
    return false
  end
  for distance in BattleManager.distanceMatrix:iterator() do
    if distance <= user.currentSteps and distance > 0 then
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

function TurnWindow:tradeEnabled()
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

-------------------------------------------------------------------------------
-- General info
-------------------------------------------------------------------------------

-- Overrides ButtonWindow:colCount.
function TurnWindow:colCount()
  return 2
end

-- Overrides ButtonWindow:rowCount.
function TurnWindow.rowCount()
  return 4
end

-- Overrides ButtonWindow:onCancel.
function TurnWindow:onCancel()
  self:selectAction(VisualizeAction)
  self.result = nil
end

-- Overrides Window:show.
local old_show = TurnWindow.show
function TurnWindow:show(add)
  local user = BattleManager.currentCharacter
  self.userCursor:setCharacter(user)
  FieldManager.renderer:moveTo(user.position.x, user.position.y)
  old_show(self, add)
end

return TurnWindow
