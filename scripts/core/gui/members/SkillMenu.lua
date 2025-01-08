
-- ================================================================================================

--- Menu to manage and use skills from a `Battler`'s skill set.
---------------------------------------------------------------------------------------------------
-- @menumod SkillMenu
-- @extend MemberMenu

-- ================================================================================================

-- Imports
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local MemberMenu = require('core/gui/members/MemberMenu')
local SkillWindow = require('core/gui/members/window/interactable/SkillWindow')
local Vector = require('core/math/Vector')

-- Class table.
local SkillMenu = class(MemberMenu)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `MemberMenu:init`. 
-- @override
function SkillMenu:init(...)
  self.name = 'Skill Menu'
  MemberMenu.init(self, ...)
end
--- Overrides `Menu:createWindows`. 
-- @override
function SkillMenu:createWindows()
  self:createInfoWindow()
  self:createSkillWindow()
  self:createDescriptionWindow()
  self:setActiveWindow(self.mainWindow)
end
--- Creates the main item window.
function SkillMenu:createSkillWindow()
  local window = SkillWindow(self)
  window:setXYZ(0, self.initY - (ScreenManager.height - window.height) / 2)
  self.mainWindow = window
end
--- Creates the item description window.
function SkillMenu:createDescriptionWindow()
  local w = ScreenManager.width - self:windowMargin() * 2
  local h = ScreenManager.height - self.initY - self.mainWindow.height - self:windowMargin() * 2
  local pos = Vector(0, ScreenManager.height / 2 - h / 2 - self:windowMargin())
  self.descriptionWindow = DescriptionWindow(self, w, h, pos)
end

-- ------------------------------------------------------------------------------------------------
-- Member
-- ------------------------------------------------------------------------------------------------

--- Checks if a member has skills, usable or not.
-- @tparam Battler member Member to check.
-- @treturn boolean True if the member has at least one skill.
function SkillMenu:memberEnabled(member)
  return not member:getSkillList():isEmpty()
end

return SkillMenu
