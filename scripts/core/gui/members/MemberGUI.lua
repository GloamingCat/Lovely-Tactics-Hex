
--[[===============================================================================================

MemberGUI
---------------------------------------------------------------------------------------------------
The GUI that is shown when the player chooses a troop member to manage.

=================================================================================================]]

-- Imports
local BattlerWindow = require('core/gui/common/window/BattlerWindow')
local GUI = require('core/gui/GUI')
local MemberCommandWindow = require('core/gui/members/window/interactable/MemberCommandWindow')
local MemberInfoWindow = require('core/gui/members/window/MemberInfoWindow')
local Vector = require('core/math/Vector')

local MemberGUI = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(troop : TroopBase) Current troop (player's troop by default).
-- @param(memberList : table) Arra of troop unit tables from current troop.
-- @param(memberID : number) Current selected member on the list (first one by default).
function MemberGUI:init(parent, troop, memberList, memberID)
  self.name = 'Member GUI'
  self.troop = troop
  self.members = memberList
  self.memberID = memberID or 1
  GUI.init(self, parent)
end
-- Implements GUI:createWindows.
function MemberGUI:createWindows()
  self:createCommandWindow()
  self:createInfoWindow()
  self:createBattlerWindow()
  self:setActiveWindow(self.commandWindow)
end
-- Creates the window with the commands for the chosen member.
function MemberGUI:createCommandWindow()
  local window = MemberCommandWindow(self)
  window:setXYZ((window.width - ScreenManager.width) / 2 + self:windowMargin(), 
      (window.height - ScreenManager.height) / 2 + self:windowMargin())
  self.commandWindow = window
end
-- Creates the window with the information of the chosen member.
function MemberGUI:createInfoWindow()
  local w = ScreenManager.width - self.commandWindow.width - self:windowMargin() * 3
  local h = self.commandWindow.height
  local x = self.commandWindow.width + self:windowMargin() * 2 + w / 2 - ScreenManager.width / 2
  local y = (h - ScreenManager.height) / 2 + self:windowMargin()
  local member = self:currentMember()
  self.infoWindow = MemberInfoWindow(member, self, w, h, Vector(x, y))
end
-- Creates the window that is shown when no sub GUI is open.
function MemberGUI:createBattlerWindow()
  self.battlerWindow = BattlerWindow(self)
  self.battlerWindow:setXYZ(0, self:getHeight() / 2)
end

---------------------------------------------------------------------------------------------------
-- Member
---------------------------------------------------------------------------------------------------

-- Selected next troop members.
function MemberGUI:nextMember()
  repeat
    if self.memberID == #self.members then
      self.memberID = 1
    else
      self.memberID = self.memberID + 1
    end
  until not self.subGUI or self.subGUI:memberEnabled(self:currentMember())
  self:refreshMember()
end
-- Selected previous troop members.
function MemberGUI:prevMember()
  repeat
    if self.memberID == 1 then
      self.memberID = #self.members
    else
      self.memberID = self.memberID - 1
    end
  until not self.subGUI or self.subGUI:memberEnabled(self:currentMember())
  self:refreshMember()
end
-- Refreshs current open windows to match the new selected member.
function MemberGUI:refreshMember()
  local member = self:currentMember()
  self.commandWindow:setMember(member)
  self.infoWindow:setMember(member)
  self.infoWindow.page:set(self.memberID, #self.members)
  if self.subGUI then
    self.subGUI:setMember(member)
  else
    self.battlerWindow:setMember(member)
  end
end
-- Gets the current selected troop member.
-- @ret(table) The troop unit data.
function MemberGUI:currentMember()
  return self.members[self.memberID]
end
-- Overrides GUI:hide. Saves troop modifications.
function MemberGUI:hide(...)
  TroopManager:saveTroop(self.troop)
  GUI.hide(self, ...)
end
-- Overrides GUI:show. Refreshes member info.
function MemberGUI:show(...)
  self:refreshMember()
  GUI.show(self, ...)
end

---------------------------------------------------------------------------------------------------
-- Sub GUI
---------------------------------------------------------------------------------------------------

-- Shows a sub GUI under the command window.
-- @param(GUI : class) The class of the GUI to be open.
function MemberGUI:showSubGUI(GUI)
  self.battlerWindow:hide()
  local gui = GUI(self)
  self.subGUI = gui
  gui:setMember(self:currentMember(), self.battler)
  self:setActiveWindow(nil)
  GUIManager:showGUIForResult(gui)
  self:setActiveWindow(self.commandWindow)
  self.subGUI = nil
  self.battlerWindow:show()
  self.battlerWindow:setMember(self:currentMember())
end
-- The total height occupied by the command and info windows.
-- @ret(number) Height of the GUI including window margin.
function MemberGUI:getHeight()
  return self.commandWindow.height + self:windowMargin() * 2
end

return MemberGUI
