
--[[===============================================================================================

VisiblePartyWindow
---------------------------------------------------------------------------------------------------
Makes the PartyWindow in the FieldGUI visible alongside the FieldCommandWindow.

Use this together with the MemberCommandWindow script for better fit, 

=================================================================================================]]

local FieldGUI = require('core/gui/menu/FieldGUI')
local FieldCommandWindow = require('core/gui/menu/window/interactable/FieldCommandWindow')
local PartyWindow = require('core/gui/members/window/interactable/PartyWindow')

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
-- Do not open/close GUI when changing focus to/from the PartyWindow.
function FieldCommandWindow:openPartyWindow(GUI)
  self.GUI.partyWindow:activate()
  Fiber:wait()
  local result = self.GUI:waitForResult()
  while result > 0 do
    self.GUI:hide()
    self:openMemberGUI(result, GUI)
    self.GUI:show()
    result = self.GUI:waitForResult()
  end
  self.GUI.partyWindow.highlight:hide()
  self:activate()
end
-- To make the window thinner to fit the party window.
function FieldCommandWindow:colCount()
  return 1
end
-- To make the window longer to fit the other buttons.
function FieldCommandWindow:rowCount()
  return 8
end

---------------------------------------------------------------------------------------------------
-- PartyWindow
---------------------------------------------------------------------------------------------------

-- Overrides ListWindow:cellWidth.
local PartyWindow_cellWidth = PartyWindow.cellWidth
function PartyWindow:cellWidth()
  if self.GUI and self.GUI.mainWindow then
    local w = ScreenManager.width - self.GUI.mainWindow.width - self.GUI:windowMargin() * 3
    return self:computeCellWidth(w)
  end
  return PartyWindow_cellWidth(self)
end
