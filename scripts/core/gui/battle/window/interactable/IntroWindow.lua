
--[[===============================================================================================

IntroWindow
---------------------------------------------------------------------------------------------------
Window that is shown in the beginning of the battle.

=================================================================================================]]

-- Imports
local ActionGUI = require('core/gui/battle/ActionGUI')
local ActionInput = require('core/battle/action/ActionInput')
local ActionWindow = require('core/gui/battle/window/interactable/ActionWindow')
local Button = require('core/gui/widget/control/Button')
local FormationAction = require('core/battle/action/FormationAction')
local MemberGUI = require('core/gui/members/MemberGUI')
local VisualizeAction = require('core/battle/action/VisualizeAction')

local IntroWindow = class(ActionWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Creates a button for each backup member.
function IntroWindow:createWidgets()
  self.visualizeAction = VisualizeAction()
  self:addButton('start')
  self:addButton('formation')
  self:addButton('members')
end
-- Overriden to align text.
function IntroWindow:addButton(key)
  local button = Button:fromKey(self, key)
  button.text.sprite:setAlignX('center')
  return button
end

---------------------------------------------------------------------------------------------------
-- Callbacks
---------------------------------------------------------------------------------------------------

-- When player chooses Start button.
function IntroWindow:startConfirm(button)
  self.result = 1
end
-- When player chooses Party button.
function IntroWindow:formationConfirm(button)
  -- Executes action grid selecting.
  local action = FormationAction()
  local input = ActionInput(action, nil, nil, self.GUI)
  input.party = TroopManager.playerParty
  action:onSelect(input)
  self.GUI:hide()
  GUIManager:showGUIForResult(ActionGUI(self.GUI, input))
  local center = TroopManager.centers[input.party]
  FieldManager.renderer:moveToPoint(center.x, center.y)
  self.GUI:show()
end
-- When player chooses Items button.
function IntroWindow:membersConfirm(button)
  self:hide()
  self.GUI.partyWindow:show()
  self.GUI.partyWindow:activate()
  local result = self.GUI:waitForResult()
  while result > 0 do
    self.GUI:hide()
    local gui = MemberGUI(self.GUI, self.GUI.troop, self.GUI.partyWindow.list, result)
    GUIManager:showGUIForResult(gui)
    self.GUI:show()
    result = self.GUI:waitForResult()
  end
  self.GUI.partyWindow:hide()
  self:show()
  self:activate()
end
-- Overrides GridWindow:onCancel.
function IntroWindow:onCancel()
  local center = TroopManager.centers[TroopManager.playerParty]
  local x, y, z = math.field.pixel2Tile(center.x, center.y, center.z)
  local tx = math.round(x)
  local ty = math.round(y)
  local tz = math.round(z)
  local target = FieldManager.currentField:getObjectTile(tx, ty, tz)
  local input = ActionInput(nil, nil, target, self.GUI)
  self:selectAction(self.visualizeAction, input)
  FieldManager.renderer:moveToPoint(center.x, center.y)
  self.result = nil
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function IntroWindow:colCount()
  return 1
end
-- Overrides GridWindow:rowCount.
function IntroWindow:rowCount()
  return 3
end
-- @ret(string) String representation (for debugging).
function IntroWindow:__tostring()
  return 'Battle Intro Window'
end

return IntroWindow
