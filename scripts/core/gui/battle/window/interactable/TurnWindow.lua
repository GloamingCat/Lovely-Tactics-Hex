
-- ================================================================================================

--- Window that opens in the start of a character turn.
-- When the character's turn ends, the result field is 1.
---------------------------------------------------------------------------------------------------
-- @classmod TurnWindow

-- ================================================================================================

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local ActionWindow = require('core/gui/battle/window/interactable/ActionWindow')
local BattleCursor = require('core/battle/BattleCursor')
local Button = require('core/gui/widget/control/Button')
local SaveGUI = require('core/gui/menu/SaveGUI')
local CallAction = require('core/battle/action/CallAction')
local EscapeAction = require('core/battle/action/EscapeAction')
local BattleMoveAction = require('core/battle/action/BattleMoveAction')
local VisualizeAction = require('core/battle/action/VisualizeAction')
local WaitAction = require('core/battle/action/WaitAction')

-- Alias
local mathf = math.field

-- Class table.
local TurnWindow = class(ActionWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
function TurnWindow:init(...)
  self.moveAction = BattleMoveAction()
  self.callAction = CallAction()
  self.escapeAction = EscapeAction()
  self.visualizeAction = VisualizeAction()
  self.waitAction = WaitAction()
  ActionWindow.init(self, ...)
end
--- Overrides `GridWindow:setProperties`. 
-- @override setProperties
function TurnWindow:setProperties()
  ActionWindow.setProperties(self)
  self.tooltipTerm = ''
end
--- Overrides `GridWindow:createContent`. Creates character cursor and stores troop's data.
-- @override createContent
function TurnWindow:createContent(...)
  local troop = TurnManager:currentTroop()
  self.backupBattlers = troop:backupBattlers()
  self.fieldBattlers = troop:currentBattlers()
  self.livingAllies = TroopManager:currentCharacters(troop.party, true)
  ActionWindow.createContent(self, ...)
  self.userCursor = BattleCursor()
  self.content:add(self.userCursor)
end
--- Implements `GridWindow:createWidgets`. 
-- @implement createWidgets
function TurnWindow:createWidgets()
  Button:fromKey(self, 'attack')
  Button:fromKey(self, 'move')
  Button:fromKey(self, 'skill')
  Button:fromKey(self, 'item')
  Button:fromKey(self, 'inspect')
  Button:fromKey(self, 'callAlly')
  Button:fromKey(self, 'wait')
  Button:fromKey(self, 'escape')
end

-- ------------------------------------------------------------------------------------------------
-- Confirm callbacks
-- ------------------------------------------------------------------------------------------------

--- "Attack" button callback.
function TurnWindow:attackConfirm(button)
  self:selectAction(TurnManager:currentCharacter().battler:getAttackSkill())
end
--- "Move" button callback.
function TurnWindow:moveConfirm(button)
  self:selectAction(self.moveAction)
end
--- "Escape" button callback.
function TurnWindow:escapeConfirm(button)
  self:selectAction(self.escapeAction)
end
--- "Call Ally" button callback.
function TurnWindow:callAllyConfirm(button)
  self:selectAction(self.callAction)
end
--- "Skill" button callback. Opens Skill Window.
function TurnWindow:skillConfirm(button)
  self:changeWindow(self.GUI.skillWindow, true)
end
--- "Item" button callback. Opens Item Window.
function TurnWindow:itemConfirm(button)
  self:changeWindow(self.GUI.itemWindow, true)
end
--- "Inspect" button callback. Starts visualize action.
function TurnWindow:inspectConfirm(button)
  self:selectAction(self.visualizeAction)
end
--- "Wait" button callback. End turn.
function TurnWindow:waitConfirm(button)
  self:selectAction(self.waitAction)
end
--- "Save" button callback. Opens save window.
function TurnWindow:optionsConfirm(button)
  self:hide()
  self.GUI:showWindowForResult(self.GUI.optionsWindow)
  self:show()
end
--- Overrides `GridWindow:onCancel`. 
-- @override onCancel
function TurnWindow:onCancel()
  AudioManager:playSFX(Config.sounds.buttonCancel)
  self:optionsConfirm()
  self.result = nil
end
--- Overrides `Window:onNext`. 
-- @override onNext
function TurnWindow:onNext()
  local index = TurnManager:nextCharacterIndex(1, true)
  if index and index ~= TurnManager.characterIndex then
    self.result = { characterIndex = index }
  end
end
--- Overrides `Window:onPrev`. 
-- @override onPrev
function TurnWindow:onPrev()
  local index = TurnManager:nextCharacterIndex(-1, true)
  if index and index ~= TurnManager.characterIndex then
    self.result = { characterIndex = index }
  end
end

-- ------------------------------------------------------------------------------------------------
-- Enable Conditions
-- ------------------------------------------------------------------------------------------------

--- Attack condition. Enabled if there are tiles to move to or if there are any
--  enemies that the skill can reach.
function TurnWindow:attackEnabled(button)
  local user = TurnManager:currentCharacter()
  return self:skillActionEnabled(user.battler:getAttackSkill())
end
--- Skill condition. Enabled if character has any skills to use.
function TurnWindow:skillEnabled(button)
  return self.GUI.skillWindow ~= nil
end
--- Item condition. Enabled if character has any items to use.
function TurnWindow:itemEnabled(button)
  return self.GUI.itemWindow ~= nil
end
--- Escape condition. Only escapes if the character is in a tile of their party.
function TurnWindow:escapeEnabled()
  if #self.livingAllies == 1 then
    if not BattleManager.params.escapeEnabled or #self.fieldBattlers > 1 then
      return false
    end
  end
  local char = TurnManager:currentCharacter()
  local userParty = char.party
  local tileParty = char:getTile().party
  return userParty == tileParty
end
--- Call Ally condition. Enabled if there any any backup members.
function TurnWindow:callAllyEnabled()
  return TroopManager:getMemberCount() < Config.troop.maxMembers and 
    not self.backupBattlers:isEmpty()
end

-- ------------------------------------------------------------------------------------------------
-- Show / Hide
-- ------------------------------------------------------------------------------------------------

--- Overrides `Window:show`. 
-- @override show
function TurnWindow:show(...)
  local user = TurnManager:currentCharacter()
  self.userCursor:setCharacter(user)
  ActionWindow.show(self, ...)
end

-- ------------------------------------------------------------------------------------------------
-- General info
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:colCount`. 
-- @override colCount
function TurnWindow:colCount()
  return 2
end
--- Overrides `GridWindow:rowCount`. 
-- @override rowCount
function TurnWindow:rowCount()
  return 4
end
--- Overrides `GridWindow:cellWidth`. 
-- @override cellWidth
function TurnWindow:cellWidth()
  return ActionWindow.cellWidth(self) * 3 / 4
end
-- @treturn string String representation (for debugging).
function TurnWindow:__tostring()
  return 'Battle Turn Window'
end

return TurnWindow
