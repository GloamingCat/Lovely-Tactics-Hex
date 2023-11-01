
-- ================================================================================================

--- `FieldMenu`'s selectable window.
---------------------------------------------------------------------------------------------------
-- @windowmod FieldCommandWindow
-- @extend OptionsWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local OptionsWindow = require('core/gui/menu/window/interactable/OptionsWindow')
local InventoryMenu = require('core/gui/common/InventoryMenu')
local MemberMenu = require('core/gui/members/MemberMenu')
local EquipMenu = require('core/gui/members/EquipMenu')
local SkillMenu = require('core/gui/members/SkillMenu')

-- Class table.
local FieldCommandWindow = class(OptionsWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `OptionsWindow:setProperties`. Changes button alingment.
-- @override
function FieldCommandWindow:setProperties()
  OptionsWindow.setProperties(self)
  self.buttonAlign = 'left'
end
--- Implements `GridWindow:createWidgets`.
-- @implement
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

-- ------------------------------------------------------------------------------------------------
-- Buttons
-- ------------------------------------------------------------------------------------------------

--- Opens the inventory screen.
function FieldCommandWindow:inventoryConfirm()
  self.menu:hide()
  MenuManager:showMenuForResult(InventoryMenu(self.menu, self.menu.troop))
  self.menu:show()
end
--- Chooses a member to manage.
function FieldCommandWindow:membersConfirm()
  self:openPartyWindow(MemberMenu, 'battler')
end
--- Chooses a member to manage.
function FieldCommandWindow:equipsConfirm()
  self:openPartyWindow(EquipMenu, 'equipper')
end
--- Chooses a member to manage.
function FieldCommandWindow:skillsConfirm()
  self:openPartyWindow(SkillMenu, 'user')
end
--- Closes menu.
function FieldCommandWindow:returnConfirm()
  self.result = 0
end

-- ------------------------------------------------------------------------------------------------
-- Members
-- ------------------------------------------------------------------------------------------------

--- Open the Menu's party window.
-- @tparam class Menu The sub Menu class to open after the character selection.
-- @tparam string tooltip The tooltip term to be shown from this window is open.
function FieldCommandWindow:openPartyWindow(Menu, tooltip)
  if self.menu.partyWindow.troop:visibleMembers().size <= 1 then
    self.menu:hide()
    self:openMemberMenu(1, Menu)
    self.menu:show()
    self:activate()
    return
  end
  self.menu:hide()
  self.menu.partyWindow.tooltipTerm = tooltip
  self.menu.partyWindow:show()
  self.menu.partyWindow:activate()
  local result = self.menu:waitForResult()
  while result > 0 do
    self.menu.partyWindow:hide()
    self:openMemberMenu(result, Menu)
    self.menu.partyWindow:show()
    result = self.menu:waitForResult()
  end
  self.menu.partyWindow:hide()
  self:activate()
  self.menu:show()
end
--- Open the member Menu for the selected character.
-- @tparam number memberID Character's position in the party.
-- @tparam class menuClass A `MemberMenu` subclass to be instantiated.
function FieldCommandWindow:openMemberMenu(memberID, menuClass)
  local menu = menuClass(self.menu, self.menu.troop, self.menu.partyWindow.list, memberID)
  MenuManager:showMenuForResult(menu)
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:colCount`. 
-- @override
function FieldCommandWindow:colCount()
  return 2
end
--- Overrides `GridWindow:rowCount`. 
-- @override
function FieldCommandWindow:rowCount()
  return 4
end
-- For debugging.
function FieldCommandWindow:__tostring()
  return 'Field Command Window'
end

return FieldCommandWindow
