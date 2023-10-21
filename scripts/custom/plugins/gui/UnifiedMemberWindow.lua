
-- ================================================================================================

--- The small windows with the commands for character management.
-- Should come before `VisiblePartyWindow` if both plugins are used.
---------------------------------------------------------------------------------------------------
-- @plugin UnifiedMemberWindow

-- ================================================================================================
  
-- Imports
local Button = require('core/gui/widget/control/Button')
local EquipGUI = require('core/gui/members/EquipGUI')
local FieldCommandWindow = require('core/gui/menu/window/interactable/FieldCommandWindow')
local GridWindow = require('core/gui/GridWindow')
local ItemGUI = require('core/gui/members/ItemGUI')
local MemberCommandWindow = require('core/gui/members/window/interactable/MemberCommandWindow')
local MemberGUI = require('core/gui/members/MemberGUI')
local SkillGUI = require('core/gui/members/SkillGUI')

-- Arguments
local useItem = args.useItem

-- ------------------------------------------------------------------------------------------------
-- Buttons
-- ------------------------------------------------------------------------------------------------

--- Rewrites `MemberCommandWindow:createWidgets`.
-- @override MemberCommandWindow_createWidgets
function MemberCommandWindow:createWidgets()
  Button:fromKey(self, 'equips')
  Button:fromKey(self, 'skills')
  if useItem then
    Button:fromKey(self, 'items')
  end
end

-- ------------------------------------------------------------------------------------------------
-- Confirm Callbacks
-- ------------------------------------------------------------------------------------------------

--- Rewrites `MemberCommandWindow:itemsConfirm`.
-- @override MemberCommandWindow_itemsConfirm
function MemberCommandWindow:itemsConfirm()
  self.GUI:showSubGUI(ItemGUI)
end
--- Rewrites `MemberCommandWindow:skillsConfirm`.
-- @override MemberCommandWindow_skillsConfirm
function MemberCommandWindow:skillsConfirm()
  self.GUI:showSubGUI(SkillGUI)
end
--- Rewrites `MemberCommandWindow:equipsConfirm`.
-- @override MemberCommandWindow_equipsConfirm
function MemberCommandWindow:equipsConfirm()
  self.GUI:showSubGUI(EquipGUI)
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Rewrites `MemberCommandWindow:rowCount`. 
-- @override MemberCommandWindow_rowCount
function MemberCommandWindow:rowCount()
  return useItem and 3 or 2
end

-- ------------------------------------------------------------------------------------------------
-- MemberGUI
-- ------------------------------------------------------------------------------------------------

--- Rewrites `MemberGUI:createWindows`.
--  Creates the window with the commands for the chosen member.
-- @override MemberGUI_createWindows
local MemberGUI_createWindows = MemberGUI.createWindows
function MemberGUI:createWindows(...)
  -- Creates command window
  local window = MemberCommandWindow(self)
  window:setXYZ((window.width - ScreenManager.width) / 2 + self:windowMargin(), 
      (window.height - ScreenManager.height) / 2 + self:windowMargin())
  self.commandWindow = window
  -- Sets info window size accordingly
  self.infoWindowWidth = ScreenManager.width - window.width - self:windowMargin() * 3
  self.infoWindowHeight = window.height
  -- Creates other windows
  MemberGUI_createWindows(self, ...)
  -- Update info window position
  local x = window.width + self:windowMargin() * 2 + (self.infoWindowWidth - ScreenManager.width) / 2
  self.infoWindow:setXYZ(x, nil)
  -- Changes active window
  self:setActiveWindow(window)
end
--- Rewrites `MemberGUI:createInfoWindow`.
-- @override MemberGUI_createInfoWindow
local MemberGUI_createInfoWindow = MemberGUI.createInfoWindow
function MemberGUI:createInfoWindow()
  if self.parent and self.parent.createInfoWindow then
    -- Is sub GUI
    self.initY = self.parent.initY
  else
    -- Parent GUI
    MemberGUI_createInfoWindow(self)
  end
end
--- Rewrites `MemberGUI:refreshMember`.
-- Refreshes current member of command window.
-- @override MemberGUI_refreshMember
local MemberGUI_refreshMember = MemberGUI.refreshMember
function MemberGUI:refreshMember(member)
  MemberGUI_refreshMember(self, member)
  if self.parent and self.parent.refreshMember then
    -- Is sub GUI
    self.parent.memberID = self.memberID
    self.parent:refreshMember()
  else
    -- Is parent GUI
    member = member or self:currentMember()
    self.commandWindow:setBattler(member)
  end
end
--- Rewrites `MemberGUI:memberEnabled`.
-- @override MemberGUI_memberEnabled
function MemberGUI:memberEnabled(member)
  return not self.subGUI or self.subGUI:memberEnabled(self:currentMember())
end

-- ------------------------------------------------------------------------------------------------
-- Sub GUI
-- ------------------------------------------------------------------------------------------------

--- Shows a sub GUI under the command window.
-- @tparam class GUI The class of the GUI to be open.
function MemberGUI:showSubGUI(GUI)
  self.commandWindow.cursor:hide()
  self.mainWindow:hide()
  local gui = GUI(self, self.troop, self.members, self.memberID)
  self.subGUI = gui
  gui.memberID = self.memberID
  gui:refreshMember()
  self:setActiveWindow(nil)
  GUIManager:showGUIForResult(gui)
  self.subGUI = nil
  self.mainWindow:show()
  self.mainWindow:setBattler(self:currentMember())
  self:setActiveWindow(self.commandWindow)
  self.commandWindow.cursor:show()
end

-- ------------------------------------------------------------------------------------------------
-- FieldCommandWindow
-- ------------------------------------------------------------------------------------------------

--- Rewrites `FieldCommandWindow:setProperties`. Changes the alignment of the button.
-- @override FieldCommandWindow_setProperties
local FieldCommandWindow_setProperties = FieldCommandWindow.setProperties
function FieldCommandWindow:setProperties(...)
  FieldCommandWindow_setProperties(self, ...)
  self.buttonAlign = 'center'
end
--- Rewrites `FieldCommandWindow:createWidgets`. Changes the available buttons.
-- @override FieldCommandWindow_createWidgets
function FieldCommandWindow:createWidgets(...)
  Button:fromKey(self, 'inventory')
  Button:fromKey(self, 'members')
  Button:fromKey(self, 'config')
  Button:fromKey(self, 'save')
  Button:fromKey(self, 'quit')
  Button:fromKey(self, 'return')
end
--- Rewrites `FieldCommandWindow:colCount`.
-- @override FieldCommandWindow_colCount
function FieldCommandWindow:colCount()
  return 1
end
--- Rewrites `FieldCommandWindow:rowCount`.
-- @override FieldCommandWindow_rowCount
function FieldCommandWindow:rowCount()
  return 6
end
