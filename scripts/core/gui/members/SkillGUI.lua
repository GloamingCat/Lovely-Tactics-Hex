
--[[===============================================================================================

SkillGUI
---------------------------------------------------------------------------------------------------
The GUI to manage and use skills from a member's skill set.

=================================================================================================]]

-- Imports
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local GUI = require('core/gui/GUI')
local SkillWindow = require('core/gui/members/window/interactable/SkillWindow')
local Vector = require('core/math/Vector')

local SkillGUI = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides GUI:init.
-- @param(parent : MemberGUI) Parent Member GUI.
function SkillGUI:init(parent)
  self.name = 'Skill GUI'
  GUI.init(self, parent)
end
-- Overrides GUI:createWindows.
function SkillGUI:createWindows()
  self:createSkillWindow()
  self:createDescriptionWindow()
  self:setActiveWindow(self.mainWindow)
end
-- Creates the main item window.
function SkillGUI:createSkillWindow()
  local window = SkillWindow(self)
  window:setXYZ(0, self.parent:getHeight() - ScreenManager.height / 2 + window.height / 2)
  self.mainWindow = window
end
-- Creates the item description window.
function SkillGUI:createDescriptionWindow()
  local initY = self.parent:getHeight()
  local w = ScreenManager.width - self:windowMargin() * 2
  local h = ScreenManager.height - initY - self.mainWindow.height - self:windowMargin() * 2
  local pos = Vector(0, ScreenManager.height / 2 - h / 2 - self:windowMargin())
  self.descriptionWindow = DescriptionWindow(self, w, h, pos)
end

---------------------------------------------------------------------------------------------------
-- Member
---------------------------------------------------------------------------------------------------

-- Called when player selects a member to use the item.
-- @param(member : Battler) New member to use the item.
function SkillGUI:setMember(member)
  self.mainWindow:setMember(member)
end
-- Verifies if a member can use an item.
-- @param(member : Battler) Member to check.
-- @ret(boolean) True if the member is active, false otherwise.
function SkillGUI:memberEnabled(member)
  return not member.skillList:isEmpty()
end

return SkillGUI
