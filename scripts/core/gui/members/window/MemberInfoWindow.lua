
--[[===============================================================================================

MemberInfoWindow
---------------------------------------------------------------------------------------------------
A window that shows HP and MP of a troop member.

=================================================================================================]]

-- Imports
local MemberInfo = require('core/gui/widget/data/MemberInfo')
local Pagination = require('core/gui/widget/Pagination')
local SimpleText = require('core/gui/widget/SimpleText')
local Vector = require('core/math/Vector')
local Window = require('core/gui/Window')

local MemberInfoWindow = class(Window)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(member : Battler) The initial member.
-- @param(...) Other default parameters from Window:init.
function MemberInfoWindow:init(member, ...)
  self.member = member
  Window.init(self, ...)
end
-- Overrides Window:createContent.
-- Creates the content of the initial member.
function MemberInfoWindow:createContent(...)
  Window.createContent(self, ...)
  self.page = Pagination(self)
  self.content:add(self.page)
  self:setMember(self.member)
end

---------------------------------------------------------------------------------------------------
-- Member
---------------------------------------------------------------------------------------------------

-- @param(member : Battler) Changes the member info to another member's.
function MemberInfoWindow:setMember(member)
  self.member = member
  if self.info then
    self.info:destroy()
    self.content:removeElement(self.info)
  end
  local w = self.width - self:paddingX() * 2
  local h = self.height - self:paddingY() * 2
  self.info = MemberInfo(self.member, w, h, Vector(-w / 2, -h / 2))
  self.info:updatePosition(self.position)
  self.content:add(self.info)
  if not self.open then
    self.info:hide()
  end
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- @ret(string) String representation (for debugging).
function MemberInfoWindow:__tostring()
  return 'Member Info Window'
end

return MemberInfoWindow
