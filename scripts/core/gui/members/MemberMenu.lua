
-- ================================================================================================

--- Menu to manage a troop member's `Battler`.
-- When not used as parent class, it just shows the battler window for the current member.
---------------------------------------------------------------------------------------------------
-- @menumod MemberMenu
-- @extend Menu

-- ================================================================================================

-- Imports
local BattlerWindow = require('core/gui/common/window/BattlerWindow')
local MemberInfoWindow = require('core/gui/members/window/MemberInfoWindow')
local Vector = require('core/math/Vector')
local Menu = require('core/gui/Menu')

-- Class table.
local MemberMenu = class(Menu)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Menu parent Parent Menu.
-- @tparam Troop troop Current troop.
-- @tparam table memberList Array of troop unit tables from current troop.
-- @tparam[opt=1] number memberID Current selected member on the list.
function MemberMenu:init(parent, troop, memberList, memberID)
  self.name = self.name or 'Member Menu'
  self.troop = troop
  self.members = memberList
  self.memberID = memberID or 1
  self.infoWindowWidth = ScreenManager.width * 3 / 4
  self.infoWindowHeight = 56
  self.initY = 0
  Menu.init(self, parent)
end
--- Implements `Menu:createWindows`.
-- @implement
function MemberMenu:createWindows()
  self:createInfoWindow()
  self:createBattlerWindow()
  self:setActiveWindow(self.mainWindow)
end
--- Creates the window with the information of the chosen member.
function MemberMenu:createInfoWindow()
  local y = (self.infoWindowHeight - ScreenManager.height) / 2 + self:windowMargin()
  self.infoWindow = MemberInfoWindow(self:currentMember(), self,
    self.infoWindowWidth, self.infoWindowHeight, Vector(0, y))
  self.initY = self.infoWindowHeight + self:windowMargin() * 2
end
--- Creates the window that is shown when no sub Menu is open.
function MemberMenu:createBattlerWindow()
  self.mainWindow = BattlerWindow(self)
  self.mainWindow:setXYZ(0, self.initY / 2)
end

-- ------------------------------------------------------------------------------------------------
-- Member
-- ------------------------------------------------------------------------------------------------

--- Selected next troop members.
function MemberMenu:nextMember()
  repeat
    if self.memberID == #self.members then
      self.memberID = 1
    else
      self.memberID = self.memberID + 1
    end
  until self:memberEnabled(self:currentMember())
  self:refreshMember()
end
--- Selected previous troop members.
function MemberMenu:prevMember()
  repeat
    if self.memberID == 1 then
      self.memberID = #self.members
    else
      self.memberID = self.memberID - 1
    end
  until self:memberEnabled(self:currentMember())
  self:refreshMember()
end
--- Refreshes current open windows to match the new selected member.
function MemberMenu:refreshMember(member)
  member = member or self:currentMember()
  if self.infoWindow then
    self.infoWindow:setBattler(member)
    self.infoWindow.page:set(self.memberID, #self.members)
  end
  if self.mainWindow then
    self.mainWindow:setBattler(member)
  end
end
--- Gets the current selected troop member.
-- @treturn table The troop unit data.
function MemberMenu:currentMember()
  return self.members[self.memberID]
end
--- Overrides `Menu:show`. Refreshes member info.
-- @override
function MemberMenu:show(...)
  self:refreshMember()
  Menu.show(self, ...)
end
--- True if the member is active, false otherwise.
-- @treturn boolean
function MemberMenu:memberEnabled(member)
  return true
end

return MemberMenu
