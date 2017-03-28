
--[[===========================================================================

SkillWindow
-------------------------------------------------------------------------------
The window that is open to choose a skill from character's skill list.

=============================================================================]]

-- Imports
local ListButtonWindow = require('core/gui/ListButtonWindow')
local ActionWindow = require('custom/gui/battle/ActionWindow')
local SkillAction = require('core/battle/action/SkillAction')
local Vector = require('core/math/Vector')

local SkillWindow = require('core/class'):inherit(ActionWindow, ListButtonWindow)

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------

local old_init = SkillWindow.init
function SkillWindow:init(GUI)
  old_init(self, BattleManager.currentCharacter.battler.skillList, GUI)
end

-- Creates a button from a skill ID.
-- @param(skill : Skill) the skill data from battler's skill list
function SkillWindow:createButton(skill)
  local button = self:addButton(skill.data.name, nil, self.onButtonConfirm)
  button.skill = skill
end

-------------------------------------------------------------------------------
-- Input handlers
-------------------------------------------------------------------------------

-- Called when player chooses a skill.
-- @param(button : Button) the button selected
function SkillWindow:onButtonConfirm(button)
  self:selectSkill(button.skill)
end

-- Called when player cancels.
function SkillWindow:onCancel()
  self:changeWindow(self.GUI.turnWindow)
end

-------------------------------------------------------------------------------
-- Properties
-------------------------------------------------------------------------------

-- New button width.
function SkillWindow:buttonWidth()
  return 80
end

-- New row count.
function SkillWindow:rowCount()
  return 6
end

return SkillWindow
