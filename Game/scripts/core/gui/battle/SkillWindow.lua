
--[[===============================================================================================

SkillWindow
---------------------------------------------------------------------------------------------------
The window that is open to choose a skill from character's skill list.

=================================================================================================]]

-- Imports
local SkillAction = require('core/battle/action/SkillAction')
local Vector = require('core/math/Vector')
local Button = require('core/gui/Button')
local ActionWindow = require('core/gui/battle/ActionWindow')
local ListButtonWindow = require('core/gui/ListButtonWindow')

local SkillWindow = class(ActionWindow, ListButtonWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function SkillWindow:init(GUI, skillList)
  ListButtonWindow.init(self, skillList, GUI)
end
-- Creates a button from a skill ID.
-- @param(skill : SkillAction) the SkillAction from battler's skill list
function SkillWindow:createButton(skill)
  local button = Button(self, skill.data.name, nil, self.onButtonConfirm, self.buttonEnabled)
  button.skill = skill
end

---------------------------------------------------------------------------------------------------
-- Input handlers
---------------------------------------------------------------------------------------------------

-- Called when player chooses a skill.
-- @param(button : Button) the button selected
function SkillWindow:onButtonConfirm(button)
  self:selectAction(button.skill)
end
-- Tells if a skill can be used.
-- @param(button : Button) the button to check
-- @ret(boolean)
function SkillAction:buttonEnabled(button)
  return button.skill:canExecute(BattleManager.currentCharacter)
end
-- Called when player cancels.
function SkillWindow:onCancel()
  self:changeWindow(self.GUI.turnWindow)
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- New button width.
function SkillWindow:buttonWidth()
  return 80
end
-- New row count.
function SkillWindow:rowCount()
  return 6
end
-- String identifier.
function SkillWindow:__tostring()
  return 'SkillWindow'
end

return SkillWindow
