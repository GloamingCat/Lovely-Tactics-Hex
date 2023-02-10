
--[[===============================================================================================

SkillGUI
---------------------------------------------------------------------------------------------------
The GUI to manage and use skills from a member's skill set.

=================================================================================================]]

-- Imports
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local MemberGUI = require('core/gui/members/MemberGUI')
local SkillWindow = require('core/gui/members/window/interactable/SkillWindow')
local Vector = require('core/math/Vector')

local SkillGUI = class(MemberGUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides MemberGUI:init.
function SkillGUI:init(...)
  self.name = 'Skill GUI'
  MemberGUI.init(self, ...)
end
-- Overrides GUI:createWindows.
function SkillGUI:createWindows()
  self:createInfoWindow()
  self:createSkillWindow()
  self:createDescriptionWindow()
  self:setActiveWindow(self.mainWindow)
end
-- Creates the main item window.
function SkillGUI:createSkillWindow()
  local window = SkillWindow(self)
  window:setXYZ(0, self.initY - (ScreenManager.height - window.height) / 2)
  self.mainWindow = window
end
-- Creates the item description window.
function SkillGUI:createDescriptionWindow()
  local w = ScreenManager.width - self:windowMargin() * 2
  local h = ScreenManager.height - self.initY - self.mainWindow.height - self:windowMargin() * 2
  local pos = Vector(0, ScreenManager.height / 2 - h / 2 - self:windowMargin())
  self.descriptionWindow = DescriptionWindow(self, w, h, pos)
end

---------------------------------------------------------------------------------------------------
-- Member
---------------------------------------------------------------------------------------------------

-- Verifies if a member can use an item.
-- @param(member : Battler) Member to check.
-- @ret(boolean) True if the member is active, false otherwise.
function SkillGUI:memberEnabled(member)
  return not member:getSkillList():isEmpty()
end

return SkillGUI
