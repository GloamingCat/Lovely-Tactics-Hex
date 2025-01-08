
-- ================================================================================================

--- Makes the `PartyWindow` in the `FieldMenu` visible alongside the `FieldCommandWindow`.
-- 
-- Use this together with the `UnifiedMemberWindow` script for better fit.
---------------------------------------------------------------------------------------------------
-- @plugin VisiblePartyWindow

-- ================================================================================================

-- Imports
local FieldMenu = require('core/gui/menu/FieldMenu')
local FieldCommandWindow = require('core/gui/menu/window/interactable/FieldCommandWindow')
local PartyWindow = require('core/gui/members/window/interactable/PartyWindow')

-- Rewrites
local FieldMenu_createWindows = FieldMenu.createWindows
local FieldMenu_createMainWindow = FieldMenu.createMainWindow
local FieldMenu_createMembersWindow = FieldMenu.createMembersWindow
local FieldCommandWindow_setProperties = FieldCommandWindow.setProperties
local FieldCommandWindow_colCount = FieldCommandWindow.colCount
local FieldCommandWindow_rowCount = FieldCommandWindow.rowCount
local PartyWindow_cellWidth = PartyWindow.cellWidth
local PartyWindow_cellHeight = PartyWindow.cellHeight

-- ------------------------------------------------------------------------------------------------
-- FieldMenu
-- ------------------------------------------------------------------------------------------------

--- Rewrites `FieldMenu:createWindows`.
-- @rewrite
function FieldMenu:createWindows(...)
  FieldMenu_createWindows(self, ...)
  local y = -self.goldWindow.position.y
  self.goldWindow:setXYZ(nil, y)
  self.locationWindow:setXYZ(nil, y)
  self.timeWindow:setXYZ(nil, y)
end
--- Rewrites `FieldMenu:createMainWindow`.
-- @rewrite
function FieldMenu:createMainWindow()
  FieldMenu_createMainWindow(self)
  local m = self:windowMargin()
  local x = (self.mainWindow.width - ScreenManager.width) / 2 + m
  local y = (self.mainWindow.height - ScreenManager.height) / 2 + m
  self.goldWindowWidth = self.mainWindow.width
  self.mainWindow:setXYZ(x, y)
end
--- Rewrites `FieldMenu:createMembersWindow`.
-- @rewrite
function FieldMenu:createMembersWindow()
  FieldMenu_createMembersWindow(self)
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
function FieldCommandWindow:openPartyWindow(Menu, tooltip)
  if self.menu.partyWindow.troop:visibleMembers().size <= 1 then
    self.menu:hide()
    self:openMemberMenu(1, Menu)
    self.menu:show()
    self:activate()
    return
  end
  self.menu.partyWindow.tooltipTerm = tooltip
  self.menu.partyWindow:activate()
  Fiber:wait()
  local result = self.menu:waitForResult()
  while result > 0 do
    self.menu:hide()
    self:openMemberMenu(result, Menu)
    self.menu:show()
    result = self.menu:waitForResult()
  end
  self:activate()
  self.menu.partyWindow.highlight:hide()
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
  if self.menu and self.menu.mainWindow then
    local w = ScreenManager.width - self.menu.mainWindow.width - self.menu:windowMargin() * 3
    return self:computeCellWidth(w)
  end
  return PartyWindow_cellWidth(self)
end
--- Rewrites `PartyWindow:cellHeight`.
-- @rewrite
function PartyWindow:cellHeight()
  if self.menu and self.menu.goldWindow then
    local h = ScreenManager.height - self.menu.goldWindow.height - self.menu:windowMargin() * 3
    return self:computeCellHeight(h)
  end
  return PartyWindow_cellHeight(self)
end
