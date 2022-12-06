
--[[===============================================================================================

MemberCommandWindow
---------------------------------------------------------------------------------------------------
The small windows with the commands for character management.

Should come before VisiblePartyWindow.

=================================================================================================]]
  
-- Imports
local Button = require('core/gui/widget/control/Button')
local EquipGUI = require('core/gui/members/EquipGUI')
local FieldCommandWindow = require('core/gui/menu/window/interactable/FieldCommandWindow')
local ItemGUI = require('core/gui/members/ItemGUI')
local MemberGUI = require('core/gui/members/MemberGUI')
local GridWindow = require('core/gui/GridWindow')
local SkillGUI = require('core/gui/members/SkillGUI')

-- Arguments
local useItem = args.useItem == 'true'

local MemberCommandWindow = class(GridWindow)

---------------------------------------------------------------------------------------------------
-- Buttons
---------------------------------------------------------------------------------------------------

-- Constructor.
function MemberCommandWindow:createWidgets()
  Button:fromKey(self, 'equips')
  Button:fromKey(self, 'skills')
  if useItem then
    Button:fromKey(self, 'items')
  end
end

---------------------------------------------------------------------------------------------------
-- Confirm Callbacks
---------------------------------------------------------------------------------------------------

-- Items button.
function MemberCommandWindow:itemsConfirm()
  self.GUI:showSubGUI(ItemGUI)
end
-- Skills button.
function MemberCommandWindow:skillsConfirm()
  self.GUI:showSubGUI(SkillGUI)
end
-- Equips button.
function MemberCommandWindow:equipsConfirm()
  self.GUI:showSubGUI(EquipGUI)
end

---------------------------------------------------------------------------------------------------
-- Enabled Conditions
---------------------------------------------------------------------------------------------------

-- @ret(boolean) True if Item GUI may be open, false otherwise.
function MemberCommandWindow:itemsEnabled()
  return ItemGUI:memberEnabled(self.GUI:currentMember())
end
-- @ret(boolean) True if Skill GUI may be open, false otherwise.
function MemberCommandWindow:skillsEnabled()
  return SkillGUI:memberEnabled(self.GUI:currentMember())
end

---------------------------------------------------------------------------------------------------
-- Member GUI
---------------------------------------------------------------------------------------------------

-- Called when player presses "next" key.
function MemberCommandWindow:onNext()
  AudioManager:playSFX(Config.sounds.buttonSelect)
  self.GUI:nextMember()
end
-- Called when player presses "prev" key.
function MemberCommandWindow:onPrev()
  AudioManager:playSFX(Config.sounds.buttonSelect)
  self.GUI:prevMember()
end
-- Changes current selected member.
-- @param(member : Battler)
function MemberCommandWindow:setMember(member)
  for i = 1, #self.matrix do
    self.matrix[i]:refreshEnabled()
    self.matrix[i]:refreshState()
  end
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function MemberCommandWindow:colCount()
  return 1
end
-- Overrides GridWindow:rowCount.
function MemberCommandWindow:rowCount()
  return useItem and 3 or 2
end
-- @ret(string) String representation (for debugging).
function MemberCommandWindow:__tostring()
  return 'Member Command Window'
end

---------------------------------------------------------------------------------------------------
-- MemberGUI
---------------------------------------------------------------------------------------------------

-- Creates the window with the commands for the chosen member.
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
-- Refreshes current member of command window.
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
    self.commandWindow:setMember(member)
  end
end
-- @ret(boolean) True if the member is active, false otherwise.
function MemberGUI:memberEnabled(member)
  return not self.subGUI or self.subGUI:memberEnabled(self:currentMember())
end

---------------------------------------------------------------------------------------------------
-- Sub GUI
---------------------------------------------------------------------------------------------------

-- Shows a sub GUI under the command window.
-- @param(GUI : class) The class of the GUI to be open.
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
  self.mainWindow:setMember(self:currentMember())
  self:setActiveWindow(self.commandWindow)
  self.commandWindow.cursor:show()
end

---------------------------------------------------------------------------------------------------
-- FieldCommandWindow
---------------------------------------------------------------------------------------------------

-- Changes the alignment of the button.
local FieldCommandWindow_setProperties = FieldCommandWindow.setProperties
function FieldCommandWindow:setProperties(...)
  FieldCommandWindow_setProperties(self, ...)
  self.buttonAlign = 'center'
end
-- Changes the alignment of the button.
function FieldCommandWindow:createWidgets(...)
  Button:fromKey(self, 'inventory')
  Button:fromKey(self, 'members')
  Button:fromKey(self, 'config')
  Button:fromKey(self, 'save')
  Button:fromKey(self, 'quit')
  Button:fromKey(self, 'return')
end
function FieldCommandWindow:colCount()
  return 1
end
function FieldCommandWindow:rowCount()
  return 6
end
