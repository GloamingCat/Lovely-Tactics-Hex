
--[[===============================================================================================

VisiblePartyWindow
---------------------------------------------------------------------------------------------------
Makes the PartyWindow in the FieldGUI visible alongside the FieldCommandWindow.
Only use this for larger screens, otherwise the two windows won't fit together.

=================================================================================================]]

local FieldGUI = require('core/gui/menu/FieldGUI')
local FieldCommandWindow = require('core/gui/menu/window/interactable/FieldCommandWindow')

---------------------------------------------------------------------------------------------------
-- FieldGUI
---------------------------------------------------------------------------------------------------

-- Changes the position of the info windows.
local FieldGUI_createWindows = FieldGUI.createWindows
function FieldGUI:createWindows(...)
  FieldGUI_createWindows(self, ...)
  local y = -self.goldWindow.position.y
  self.goldWindow:setXYZ(nil, y)
  self.locationWindow:setXYZ(nil, y)
  self.timeWindow:setXYZ(nil, y)
end
-- Changes the position of the main window.
local FieldGUI_createMainWindow = FieldGUI.createMainWindow
function FieldGUI:createMainWindow()
  FieldGUI_createMainWindow(self)
  local m = self:windowMargin()
  local x = (self.mainWindow.width - ScreenManager.width) / 2 + m
  local y = (self.mainWindow.height - ScreenManager.height) / 2 + m
  self.goldWindowWidth = self.mainWindow.width
  self.mainWindow:setXYZ(x, y)
end
-- Changes the position of the members window and hides highlight.
local FieldGUI_createMembersWindow = FieldGUI.createMembersWindow
function FieldGUI:createMembersWindow()
  FieldGUI_createMembersWindow(self)
  local x = ScreenManager.width / 2 - self.partyWindow.width / 2 - self:windowMargin()
  local y = -ScreenManager.height / 2 + self.partyWindow.height / 2 + self:windowMargin()
  self.partyWindow:setXYZ(x, y)
  if self.partyWindow.highlight then
    self.partyWindow.highlight.hideOnDeactive = true
  end
  self.partyWindow.lastOpen = true
end

---------------------------------------------------------------------------------------------------
-- FieldCommandWindow
---------------------------------------------------------------------------------------------------

-- Changes the alignment of the button.
local FieldCommandWindow_createWidgets = FieldCommandWindow.createWidgets
function FieldCommandWindow:createWidgets(...)
  FieldCommandWindow_createWidgets(self, ...)
  for i = 1, #self.matrix do
    self.matrix[i].text.sprite:setAlignX('left')
  end
end
-- Chooses a member to manage.
function FieldCommandWindow:membersConfirm()
  self.GUI.partyWindow:activate()
  Fiber:wait()
  local result = self.GUI:waitForResult()
  while result > 0 do
    self.GUI:hide()
    self:openMemberGUI(result)
    self.GUI:show()
    result = self.GUI:waitForResult()
  end
  self.GUI.partyWindow.highlight:hide()
  self:activate()
end
