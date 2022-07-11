
--[[===============================================================================================

FieldCommandWindow
---------------------------------------------------------------------------------------------------
Main GUI's selectable window.

=================================================================================================]]

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')
local InventoryGUI = require('core/gui/common/InventoryGUI')
local MemberGUI = require('core/gui/members/MemberGUI')
local SaveGUI = require('core/gui/menu/SaveGUI')
local SettingsGUI = require('core/gui/menu/SettingsGUI')

local FieldCommandWindow = class(GridWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Implements GridWindow:createWidgets.
function FieldCommandWindow:createWidgets()
  Button:fromKey(self, 'inventory')
  Button:fromKey(self, 'members')
  Button:fromKey(self, 'config')
  Button:fromKey(self, 'save')
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
  self.GUI.partyWindow:activate()
  local result = self.GUI:waitForResult()
  while result > 0 do
    self.GUI:hide()
    local gui = MemberGUI(self.GUI, self.GUI.troop, self.GUI.partyWindow.list, result)
    GUIManager:showGUIForResult(gui)
    self.GUI:show()
    result = self.GUI:waitForResult()
  end
  self.GUI.partyWindow.highlight:hide()
  self:activate()
end
-- Opens the settings screen.
function FieldCommandWindow:configConfirm()
  self.GUI:hide()
  GUIManager:showGUIForResult(SettingsGUI(self.GUI))
  self.GUI:show()
end
-- Opens the save screen.
function FieldCommandWindow:saveConfirm()
  self.GUI:hide()
  GUIManager:showGUIForResult(SaveGUI(self.GUI))
  self.GUI:show()
end
-- Opens the exit screen.
function FieldCommandWindow:quitConfirm()
  self.GUI:hide()
  self.GUI:showWindowForResult(self.GUI.quitWindow)
  self.GUI:show()
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function FieldCommandWindow:colCount()
  return 1
end
-- Overrides GridWindow:rowCount.
function FieldCommandWindow:rowCount()
  return 5
end
-- @ret(string) String representation (for debugging).
function FieldCommandWindow:__tostring()
  return 'Field Command Window'
end

return FieldCommandWindow
