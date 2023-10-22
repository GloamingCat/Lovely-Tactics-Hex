
-- ================================================================================================

--- Window that is shown in the beginning of the battle.
---------------------------------------------------------------------------------------------------
-- @uimod IntroWindow
-- @extend FieldCommandWindow
-- @extend ActionWindow

-- ================================================================================================

-- Imports
local ActionGUI = require('core/gui/battle/ActionGUI')
local ActionInput = require('core/battle/action/ActionInput')
local ActionWindow = require('core/gui/battle/window/interactable/ActionWindow')
local FieldCommandWindow = require('core/gui/menu/window/interactable/FieldCommandWindow')
local Button = require('core/gui/widget/control/Button')
local FormationAction = require('core/battle/action/FormationAction')
local MemberGUI = require('core/gui/members/MemberGUI')
local VisualizeAction = require('core/battle/action/VisualizeAction')

-- Class table.
local IntroWindow = class(FieldCommandWindow, ActionWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Changes the alignment of the button.
function IntroWindow:setProperties(...)
  FieldCommandWindow.setProperties(self, ...)
  self.buttonAlign = 'center'
  self.visualizeAction = VisualizeAction()
  self.formationAction = FormationAction()
end
--- Creates a button for each backup member.
function IntroWindow:createWidgets()
  Button:fromKey(self, 'start')
  Button:fromKey(self, 'formation')
  Button:fromKey(self, 'inventory')
  Button:fromKey(self, 'skills')
  Button:fromKey(self, 'equips')
  Button:fromKey(self, 'inspect')
end

-- ------------------------------------------------------------------------------------------------
-- Callbacks
-- ------------------------------------------------------------------------------------------------

--- When player chooses Start button.
function IntroWindow:startConfirm(button)
  self.result = 1
end
--- When player chooses Party button.
function IntroWindow:formationConfirm(button)
  -- Executes action grid selecting.
  local center = TroopManager.centers[TroopManager.playerParty]
  local x, y, z = math.field.pixel2Tile(center.x, center.y, center.z)
  x, y, z = math.round(x), math.round(y), math.round(z)
  local target = FieldManager.currentField:getObjectTile(x, y, z)
  local input = ActionInput(self.formationAction, nil, target, self.GUI)
  input.party = TroopManager.playerParty
  self:selectAction(self.formationAction, input)
  FieldManager.renderer:moveToPoint(center.x, center.y)
  self.result = nil
end
--- Overrides `GridWindow:onCancel`. 
-- @override
function IntroWindow:inspectConfirm()
  local center = TroopManager.centers[TroopManager.playerParty]
  local x, y, z = math.field.pixel2Tile(center.x, center.y, center.z)
  x, y, z = math.round(x), math.round(y), math.round(z)
  local target = FieldManager.currentField:getObjectTile(x, y, z)
  local input = ActionInput(self.visualizeAction, nil, target, self.GUI)
  self:selectAction(self.visualizeAction, input)
  FieldManager.renderer:moveToPoint(center.x, center.y)
  self.result = nil
end
--- "Options" button callback. Opens save window.
function IntroWindow:optionsConfirm(button)
  self:hide()
  self.GUI:showWindowForResult(self.GUI.optionsWindow)
  self:show()
end
--- Overrides `GridWindow:onCancel`. 
-- @override
function IntroWindow:onCancel()
  AudioManager:playSFX(Config.sounds.buttonCancel)
  self:optionsConfirm()
  self.result = nil
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:colCount`. 
-- @override
function IntroWindow:colCount()
  return 1
end
--- Overrides `GridWindow:rowCount`. 
-- @override
function IntroWindow:rowCount()
  return 6
end
-- For debugging.
function IntroWindow:__tostring()
  return 'Battle Intro Window'
end

return IntroWindow
