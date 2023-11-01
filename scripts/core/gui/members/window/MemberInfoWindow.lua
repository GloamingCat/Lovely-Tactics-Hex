
-- ================================================================================================

--- A window that shows HP and MP of a troop member.
---------------------------------------------------------------------------------------------------
-- @windowmod MemberInfoWindow
-- @extend Window

-- ================================================================================================

-- Imports
local MemberInfo = require('core/gui/widget/data/MemberInfo')
local Pagination = require('core/gui/widget/Pagination')
local TextComponent = require('core/gui/widget/TextComponent')
local Vector = require('core/math/Vector')
local Window = require('core/gui/Window')

-- Class table.
local MemberInfoWindow = class(Window)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Battler member The initial member.
-- @param ...  Other default parameters from Window:init.
function MemberInfoWindow:init(member, ...)
  self.member = member
  Window.init(self, ...)
end
--- Overrides `Window:createContent`. Creates the content of the initial member.
-- @override
function MemberInfoWindow:createContent(...)
  Window.createContent(self, ...)
  self.page = Pagination(self)
  self.content:add(self.page)
  self:setBattler(self.member)
end

-- ------------------------------------------------------------------------------------------------
-- Member
-- ------------------------------------------------------------------------------------------------

--- Changes the member info to another member's.
-- @tparam Battler battler The new member.
function MemberInfoWindow:setBattler(battler)
  self.member = battler
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
-- For debugging.
function MemberInfoWindow:__tostring()
  return 'Member Info Window'
end

return MemberInfoWindow
