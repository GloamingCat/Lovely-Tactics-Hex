
-- ================================================================================================

--- Makes the PartyWindow in the FieldGUI visible alongside the FieldCommandWindow.
-- 
-- Use this together with the `UnifiedMemberWindow` script for better fit.
---------------------------------------------------------------------------------------------------
-- @plugin VisiblePartyWindow

-- ================================================================================================

-- Imports
local FieldGUI = require('core/gui/menu/FieldGUI')
local FieldCommandWindow = require('core/gui/menu/window/interactable/FieldCommandWindow')
local PartyWindow = require('core/gui/members/window/interactable/PartyWindow')

-- Rewrites
local FieldGUI_createWindows = FieldGUI.createWindows
local FieldGUI_createMainWindow = FieldGUI.createMainWindow
local FieldGUI_createMembersWindow = FieldGUI.createMembersWindow
local FieldCommandWindow_setProperties = FieldCommandWindow.setProperties
local FieldCommandWindow_colCount = FieldCommandWindow.colCount
local FieldCommandWindow_rowCount = FieldCommandWindow.rowCount
local PartyWindow_cellWidth = PartyWindow.cellWidth
local PartyWindow_cellHeight = PartyWindow.cellHeight

-- ------------------------------------------------------------------------------------------------
-- FieldGUI
-- ------------------------------------------------------------------------------------------------

--- Rewrites `FieldGUI:createWindows`.
-- @rewrite
function FieldGUI:createWindows(...)
  FieldGUI_createWindows(self, ...)
  local y = -self.goldWindow.position.y
  self.goldWindow:setXYZ(nil, y)
  self.locationWindow:setXYZ(nil, y)
  self.timeWindow:setXYZ(nil, y)
end
--- Rewrites `FieldGUI:createMainWindow`.
-- @rewrite
function FieldGUI:createMainWindow()
  FieldGUI_createMainWindow(self)
  local m = self:windowMargin()
  local x = (self.mainWindow.width - ScreenManager.width) / 2 + m
  local y = (self.mainWindow.height - ScreenManager.height) / 2 + m
  self.goldWindowWidth = self.mainWindow.width
  self.mainWindow:setXYZ(x, y)
end
--- Rewrites `FieldGUI:createMembersWindow`.
-- @rewrite
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

-- ------------------------------------------------------------------------------------------------
-- FieldCommandWindow
-- ------------------------------------------------------------------------------------------------

--- Rewrites `FieldCommandWindow:setProperties`.
-- @rewrite
function FieldCommandWindow:setProperties(...)
  FieldCommandWindow_setProperties(self, ...)
  self.buttonAlign = 'left'
end
--- Rewrites `FieldCommandWindow:openPartyWindow`.
-- @rewrite
function FieldCommandWindow:openPartyWindow(GUI, tooltip)
  if self.GUI.partyWindow.troop:visibleMembers().size <= 1 then
    self.GUI:hide()
    self:openMemberGUI(1, GUI)
    self.GUI:show()
    self:activate()
    return
  end
  self.GUI.partyWindow.tooltipTerm = tooltip
  self.GUI.partyWindow:activate()
  Fiber:wait()
  local result = self.GUI:waitForResult()
  while result > 0 do
    self.GUI:hide()
    self:openMemberGUI(result, GUI)
    self.GUI:show()
    result = self.GUI:waitForResult()
  end
  self:activate()
  self.GUI.partyWindow.highlight:hide()
end
--- Rewrites `FieldCommandWindow:colCount`.
-- @rewrite
function FieldCommandWindow:colCount()
  return 1
end
--- Rewrites `FieldCommandWindow:rowCount`.
-- @rewrite
function FieldCommandWindow:rowCount()
  return FieldCommandWindow_rowCount(self) * FieldCommandWindow_colCount(self)
end

-- ------------------------------------------------------------------------------------------------
-- PartyWindow
-- ------------------------------------------------------------------------------------------------

--- Rewrites `PartyWindow:cellWidth`.
-- @rewrite
function PartyWindow:cellWidth()
  if self.GUI and self.GUI.mainWindow then
    local w = ScreenManager.width - self.GUI.mainWindow.width - self.GUI:windowMargin() * 3
    return self:computeCellWidth(w)
  end
  return PartyWindow_cellWidth(self)
end
--- Rewrites `PartyWindow:cellHeight`.
-- @rewrite
function PartyWindow:cellHeight()
  if self.GUI and self.GUI.goldWindow then
    local h = ScreenManager.height - self.GUI.goldWindow.height - self.GUI:windowMargin() * 3
    return self:computeCellHeight(h)
  end
  return PartyWindow_cellHeight(self)
end
