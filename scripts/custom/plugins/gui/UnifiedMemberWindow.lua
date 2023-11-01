
-- ================================================================================================

--- The small windows with the commands for character management.
-- Should come before `VisiblePartyWindow` if both plugins are used.
---------------------------------------------------------------------------------------------------
-- @plugin UnifiedMemberWindow

-- ================================================================================================
  
-- Imports
local Button = require('core/gui/widget/control/Button')
local EquipMenu = require('core/gui/members/EquipMenu')
local FieldCommandWindow = require('core/gui/menu/window/interactable/FieldCommandWindow')
local GridWindow = require('core/gui/GridWindow')
local ItemMenu = require('core/gui/members/ItemMenu')
local MemberCommandWindow = require('core/gui/members/window/interactable/MemberCommandWindow')
local MemberMenu = require('core/gui/members/MemberMenu')
local SkillMenu = require('core/gui/members/SkillMenu')

-- Rewrites
local MemberMenu_createWindows = MemberMenu.createWindows
local MemberMenu_createInfoWindow = MemberMenu.createInfoWindow
local MemberMenu_refreshMember = MemberMenu.refreshMember
local FieldCommandWindow_setProperties = FieldCommandWindow.setProperties

-- Parameters
local useItem = args.useItem

-- ------------------------------------------------------------------------------------------------
-- Buttons
-- ------------------------------------------------------------------------------------------------

--- Rewrites `MemberCommandWindow:createWidgets`.
-- @rewrite
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
-- @rewrite
function MemberCommandWindow:itemsConfirm()
  self.menu:showSubMenu(ItemMenu)
end
--- Rewrites `MemberCommandWindow:skillsConfirm`.
-- @rewrite
function MemberCommandWindow:skillsConfirm()
  self.menu:showSubMenu(SkillMenu)
end
--- Rewrites `MemberCommandWindow:equipsConfirm`.
-- @rewrite
function MemberCommandWindow:equipsConfirm()
  self.menu:showSubMenu(EquipMenu)
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Rewrites `MemberCommandWindow:rowCount`. 
-- @rewrite
function MemberCommandWindow:rowCount()
  return useItem and 3 or 2
end

-- ------------------------------------------------------------------------------------------------
-- MemberMenu
-- ------------------------------------------------------------------------------------------------

--- Rewrites `MemberMenu:createWindows`. Creates the window with the commands for the chosen member.
-- @rewrite
function MemberMenu:createWindows(...)
  -- Creates command window
  local window = MemberCommandWindow(self)
  window:setXYZ((window.width - ScreenManager.width) / 2 + self:windowMargin(), 
      (window.height - ScreenManager.height) / 2 + self:windowMargin())
  self.commandWindow = window
  -- Sets info window size accordingly
  self.infoWindowWidth = ScreenManager.width - window.width - self:windowMargin() * 3
  self.infoWindowHeight = window.height
  -- Creates other windows
  MemberMenu_createWindows(self, ...)
  -- Update info window position
  local x = window.width + self:windowMargin() * 2 + (self.infoWindowWidth - ScreenManager.width) / 2
  self.infoWindow:setXYZ(x, nil)
  -- Changes active window
  self:setActiveWindow(window)
end
--- Rewrites `MemberMenu:createInfoWindow`.
-- @rewrite
function MemberMenu:createInfoWindow()
  if self.parent and self.parent.createInfoWindow then
    -- Is sub Menu
    self.initY = self.parent.initY
  else
    -- Parent Menu
    MemberMenu_createInfoWindow(self)
  end
end
--- Rewrites `MemberMenu:refreshMember`. Refreshes current member of command window.
-- @rewrite
function MemberMenu:refreshMember(member)
  MemberMenu_refreshMember(self, member)
  if self.parent and self.parent.refreshMember then
    -- Is sub Menu
    self.parent.memberID = self.memberID
    self.parent:refreshMember()
  else
    -- Is parent Menu
    member = member or self:currentMember()
    self.commandWindow:setBattler(member)
  end
end
--- Rewrites `MemberMenu:memberEnabled`.
-- @rewrite
function MemberMenu:memberEnabled(member)
  return not self.subMenu or self.subMenu:memberEnabled(self:currentMember())
end

-- ------------------------------------------------------------------------------------------------
-- Sub Menu
-- ------------------------------------------------------------------------------------------------

--- Shows a sub Menu under the command window.
-- @tparam class Menu The class of the Menu to be open.
function MemberMenu:showSubMenu(Menu)
  self.commandWindow.cursor:hide()
  self.mainWindow:hide()
  local menu = Menu(self, self.troop, self.members, self.memberID)
  self.subMenu = menu
  menu.memberID = self.memberID
  menu:refreshMember()
  self:setActiveWindow(nil)
  MenuManager:showMenuForResult(menu)
  self.subMenu = nil
  self.mainWindow:show()
  self.mainWindow:setBattler(self:currentMember())
  self:setActiveWindow(self.commandWindow)
  self.commandWindow.cursor:show()
end

-- ------------------------------------------------------------------------------------------------
-- FieldCommandWindow
-- ------------------------------------------------------------------------------------------------

--- Rewrites `FieldCommandWindow:setProperties`. Changes the alignment of the button.
-- @rewrite
function FieldCommandWindow:setProperties(...)
  FieldCommandWindow_setProperties(self, ...)
  self.buttonAlign = 'center'
end
--- Rewrites `FieldCommandWindow:createWidgets`. Changes the available buttons.
-- @rewrite
function FieldCommandWindow:createWidgets(...)
  Button:fromKey(self, 'inventory')
  Button:fromKey(self, 'members')
  Button:fromKey(self, 'config')
  Button:fromKey(self, 'save')
  Button:fromKey(self, 'quit')
  Button:fromKey(self, 'return')
end
--- Rewrites `FieldCommandWindow:colCount`.
-- @rewrite
function FieldCommandWindow:colCount()
  return 1
end
--- Rewrites `FieldCommandWindow:rowCount`.
-- @rewrite
function FieldCommandWindow:rowCount()
  return 6
end
