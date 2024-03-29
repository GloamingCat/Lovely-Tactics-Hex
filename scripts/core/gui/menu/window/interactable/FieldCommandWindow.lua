
--[[===============================================================================================

FieldCommandWindow
---------------------------------------------------------------------------------------------------
Main GUI's selectable window.

=================================================================================================]]

-- Imports
local Button = require('core/gui/widget/control/Button')
local OptionsWindow = require('core/gui/menu/window/interactable/OptionsWindow')
local InventoryGUI = require('core/gui/common/InventoryGUI')
local MemberGUI = require('core/gui/members/MemberGUI')
local EquipGUI = require('core/gui/members/EquipGUI')
local SkillGUI = require('core/gui/members/SkillGUI')

local FieldCommandWindow = class(OptionsWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides OptionsWindow:setPropertis.
-- Changes button alingment.
function FieldCommandWindow:setProperties()
  OptionsWindow.setProperties(self)
  self.buttonAlign = 'left'
end
-- Implements GridWindow:createWidgets.
function FieldCommandWindow:createWidgets()
  Button:fromKey(self, 'inventory')
  Button:fromKey(self, 'members')
  Button:fromKey(self, 'equips')
  Button:fromKey(self, 'skills')
  Button:fromKey(self, 'config')
  Button:fromKey(self, 'save')
  Button:fromKey(self, 'return')
  Button:fromKey(self, 'quit')
end

---------------------------------------------------------------------------------------------------
-- Buttons
---------------------------------------------------------------------------------------------------

-- Opens the inventory screen.
function FieldCommandWindow:inventoryConfirm()
  self.GUI:hide()
  GUIManager:showGUIForResult(InventoryGUI(self.GUI, self.GUI.troop))
  self.GUI:show()
end
-- Chooses a member to manage.
function FieldCommandWindow:membersConfirm()
  self:openPartyWindow(MemberGUI, 'battler')
end
-- Chooses a member to manage.
function FieldCommandWindow:equipsConfirm()
  self:openPartyWindow(EquipGUI, 'equipper')
end
-- Chooses a member to manage.
function FieldCommandWindow:skillsConfirm()
  self:openPartyWindow(SkillGUI, 'user')
end
-- Closes menu.
function FieldCommandWindow:returnConfirm()
  self.result = 0
end

---------------------------------------------------------------------------------------------------
-- Members
---------------------------------------------------------------------------------------------------

-- Open the GUI's party window.
-- @param(GUI : class) The sub GUI class to open after the character selection.
function FieldCommandWindow:openPartyWindow(GUI, tooltip)
  self.GUI:hide()
  self.GUI.partyWindow.tooltipTerm = tooltip
  self.GUI.partyWindow:show()
  self.GUI.partyWindow:activate()
  local result = self.GUI:waitForResult()
  while result > 0 do
    self.GUI.partyWindow:hide()
    self:openMemberGUI(result, GUI)
    self.GUI.partyWindow:show()
    result = self.GUI:waitForResult()
  end
  self.GUI.partyWindow:hide()
  self:activate()
  self.GUI:show()
end
-- Open the member GUI for the selected character.
-- @param(memberID : number) Character's position in the party.
function FieldCommandWindow:openMemberGUI(memberID, GUI)
  local gui = GUI(self.GUI, self.GUI.troop, self.GUI.partyWindow.list, memberID)
  GUIManager:showGUIForResult(gui)
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function FieldCommandWindow:colCount()
  return 2
end
-- Overrides GridWindow:rowCount.
function FieldCommandWindow:rowCount()
  return 4
end
-- @ret(string) String representation (for debugging).
function FieldCommandWindow:__tostring()
  return 'Field Command Window'
end

return FieldCommandWindow
