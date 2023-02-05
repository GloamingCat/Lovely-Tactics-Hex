
--[[===============================================================================================

MemberGUI
---------------------------------------------------------------------------------------------------
The GUI that is shown when the player chooses a troop member to manage.
It is also the base class for other member GUI, such as SkillGUI, ItemGUI and EquipGUI.
When not used as based class, it just shows the battler window for the current member.

=================================================================================================]]

-- Imports
local BattlerWindow = require('core/gui/common/window/BattlerWindow')
local MemberInfoWindow = require('core/gui/members/window/MemberInfoWindow')
local Vector = require('core/math/Vector')
local GUI = require('core/gui/GUI')

local MemberGUI = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(troop : TroopBase) Current troop (player's troop by default).
-- @param(memberList : table) Arra of troop unit tables from current troop.
-- @param(memberID : number) Current selected member on the list (first one by default).
function MemberGUI:init(parent, troop, memberList, memberID)
  self.name = self.name or 'Member GUI'
  self.troop = troop
  self.members = memberList
  self.memberID = memberID or 1
  self.infoWindowWidth = ScreenManager.width * 3 / 4
  self.infoWindowHeight = 56
  self.initY = 0
  GUI.init(self, parent)
end
-- Implements GUI:createWindows.
function MemberGUI:createWindows()
  self:createInfoWindow()
  self:createBattlerWindow()
  self:setActiveWindow(self.mainWindow)
end
-- Creates the window with the information of the chosen member.
function MemberGUI:createInfoWindow()
  local y = (self.infoWindowHeight - ScreenManager.height) / 2 + self:windowMargin()
  self.infoWindow = MemberInfoWindow(self:currentMember(), self,
    self.infoWindowWidth, self.infoWindowHeight, Vector(0, y))
  self.initY = self.infoWindowHeight + self:windowMargin() * 2
end
-- Creates the window that is shown when no sub GUI is open.
function MemberGUI:createBattlerWindow()
  self.mainWindow = BattlerWindow(self)
  self.mainWindow:setXYZ(0, self.initY / 2)
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
  until self:memberEnabled(self:currentMember())
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
  until self:memberEnabled(self:currentMember())
  self:refreshMember()
end
-- Refreshs current open windows to match the new selected member.
function MemberGUI:refreshMember(member)
  member = member or self:currentMember()
  if self.infoWindow then
    self.infoWindow:setMember(member)
    self.infoWindow.page:set(self.memberID, #self.members)
  end
  if self.mainWindow then
    self.mainWindow:setBattler(member)
  end
end
-- Gets the current selected troop member.
-- @ret(table) The troop unit data.
function MemberGUI:currentMember()
  return self.members[self.memberID]
end
-- Overrides GUI:show. Refreshes member info.
function MemberGUI:show(...)
  self:refreshMember()
  GUI.show(self, ...)
end
-- @ret(boolean) True if the member is active, false otherwise.
function MemberGUI:memberEnabled(member)
  return true
end

return MemberGUI
