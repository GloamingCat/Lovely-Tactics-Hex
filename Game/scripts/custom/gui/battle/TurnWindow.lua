
local ButtonWindow = require('core/gui/ButtonWindow')
local AttackAction = require('core/battle/action/AttackAction')
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

local TurnWindow = ButtonWindow:inherit()

-------------------------------------------------------------------------------
-- Enable Conditions
-------------------------------------------------------------------------------

local function moveEnabled()
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
local function attackEnabled()
  if moveEnabled() then
    return true
  else
    local user = BattleManager.currentCharacter
    local range = user.battler:getAttackSkill().range
    local tile = user:getTile()
    local field = FieldManager.currentField
    local iterator = mathf.radiusIterator(range, tile.x, tile.y, field.sizeX, field.sizeY)
    for i, j in iterator do
      if field:getObjectTile(i, j, tile.layer.height):hasEnemy(user.party) then
        return true
      end
    end
  end
  return false
end
local function skillEnabled()
  local user = BattleManager.currentCharacter.battler
  return not user.skillList:isEmpty()
end
local function itemEnabled()
  local user = BattleManager.currentCharacter.battler
  return not user.inventory:isEmpty()
end
local function tradeEnabled()
  return true
end
local function escapeEnabled()
  return true
end
local function callAllyEnabled()
  return true
end

-- Overrides ButtonWindow:createButtons.
function TurnWindow:createButtons()
  self:addButton('Attack', nil, self.onAttack, attackEnabled)
  self:addButton('Move', nil, self.onMoveAction, moveEnabled)
  self:addButton('Skill', nil, self.onSkill, skillEnabled)
  self:addButton('Item', nil, self.onItem, itemEnabled)
  self:addButton('Trade', nil, self.onTrade, tradeEnabled)
  self:addButton('Escape', nil, self.onEscape, escapeEnabled)
  self:addButton('Wait', nil, self.onWait)
  self:addButton('Call Ally', nil, self.onCallAlly, callAllyEnabled)
  self.userCursor = BattleCursor()
  self.content:add(self.userCursor)
end

-------------------------------------------------------------------------------
-- Confirm callbacks
-------------------------------------------------------------------------------

function TurnWindow:onAttack(button)
  self:selectAction(AttackAction)
end

function TurnWindow:onMoveAction(button)
  self:selectAction(MoveAction)
end

function TurnWindow:onTrade(button)
  self:selectAction(TradeAction)
end

function TurnWindow:onEscape(button)
  self:selectAction(EscapeAction)
end

function TurnWindow:onCallAlly(button)
  self:selectAction(CallAction)
end

function TurnWindow:onWait(button)
  self.result = 1
end

function TurnWindow:onSkill(button)
  self:hide(true)
  self.GUI.skillWindow:show(true)
  self.GUI.skillWindow:activate()
end

function TurnWindow:onItem(button)
  self:hide(true)
  self.GUI.itemWindow:show(true)
  button.window.GUI.itemWindow:activate()
end

-- Select an action.
-- @param(actionType : class) the class of the action
--  (must inherit from BattleAction) 
function TurnWindow:selectAction(actionType, ...)
  -- Executes action grid selecting.
  BattleManager:selectAction(actionType(...))
  local result = GUIManager:showGUIForResult('battle/ActionGUI')
  if result == 1 then
    -- End of turn.
    self.result = 1
  end
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
