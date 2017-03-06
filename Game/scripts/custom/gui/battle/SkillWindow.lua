
local ListButtonWindow = require('core/gui/ListButtonWindow')
local ActionWindow = require('custom/gui/battle/ActionWindow')
local SkillAction = require('core/battle/action/SkillAction')
local Vector = require('core/math/Vector')

--[[===========================================================================

The window that is open to choose a skill from character's skill list.

=============================================================================]]

local SkillWindow = require('core/class'):inherit(ActionWindow, ListButtonWindow)

local old_init = SkillWindow.init
function SkillWindow:init(GUI)
  old_init(self, BattleManager.currentCharacter.battler.skillList, GUI)
end

-- Creates a button from a skill ID.
-- @param(id : number) the skill ID
function SkillWindow:createButton(id)
  local skill = Database.skills[id + 1]
  local button = self:addButton(skill.name, nil, self.onButtonConfirm)
  button.skill = skill
end

-- Called when player chooses a skill.
-- @param(button : Button) the button selected
function SkillWindow:onButtonConfirm(button)
  self:selectSkill(button.skill)
end

-- Called when player cancels.
function SkillWindow:onCancel()
  self:changeWindow(self.GUI.turnWindow)
end

-- New button width.
function SkillWindow:buttonWidth()
  return 80
end

-- New row count.
function SkillWindow:rowCount()
  return 6
end

return SkillWindow
