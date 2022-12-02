
--[[===============================================================================================

ActionSkillWindow
---------------------------------------------------------------------------------------------------
The window that is open to choose a skill from character's skill list.

=================================================================================================]]

-- Imports
local ActionWindow = require('core/gui/battle/window/interactable/ActionWindow')
local Button = require('core/gui/widget/control/Button')
local ListWindow = require('core/gui/common/window/interactable/ListWindow')
local Vector = require('core/math/Vector')

local ActionSkillWindow = class(ActionWindow, ListWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(gui : GUI) /parent GUI.
-- @param(skillList : SkillList) Battler's skill set.
function ActionSkillWindow:init(gui, skillList, maxHeight)
  local y = self:fitOnTop(maxHeight) + gui:windowMargin()
  ListWindow.init(self, gui, skillList, nil, nil, Vector(0, y, 0))
end
-- Creates a button from a skill ID.
-- @param(skill : SkillAction) The SkillAction from battler's skill list.
function ActionSkillWindow:createListButton(skill)
  -- Icon
  local icon = skill.data.icon.id >= 0 and 
    ResourceManager:loadIconAnimation(skill.data.icon, GUIManager.renderer)
  -- Button
  local button = Button(self)
  button:createIcon(icon)
  button:createText('data.skill.' .. skill.data.key, skill.data.name, 'gui_button')
  button.skill = skill
  button.description = skill.data.description
  -- Get SP cost
  local char = TurnManager:currentCharacter()
  local cost = 0
  for i = 1, #skill.costs do
    if skill.costs[i].key == Config.battle.attSP then
      cost = cost + skill.costs[i].cost(skill, char.battler.att)
    end
  end
  button:createInfoText(cost .. '{%sp}', '', 'gui_button')
  return button
end

---------------------------------------------------------------------------------------------------
-- Input handlers
---------------------------------------------------------------------------------------------------

-- Updates description when button is selected.
-- @param(button : Button)
function ActionSkillWindow:onButtonSelect(button)
  self.GUI.descriptionWindow:updateTerm('data.skill.' .. button.skill.data.key .. '_desc', button.skill.data.description)
end
-- Called when player chooses a skill.
-- @param(button : Button)
function ActionSkillWindow:onButtonConfirm(button)
  self:selectAction(button.skill)
end
-- Called when player cancels.
-- @param(button : Button)
function ActionSkillWindow:onButtonCancel(button)
  self.GUI:hideDescriptionWindow()
  self:changeWindow(self.GUI.turnWindow)
end
-- Tells if a skill can be used.
-- @param(button : Button)
-- @ret(boolean)
function ActionSkillWindow:buttonEnabled(button)
  local user = TurnManager:currentCharacter()
  return button.skill:canBattleUse(user) and self:skillActionEnabled(button.skill)
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function ActionSkillWindow:colCount()
  return 1
end
-- Overrides ListWindow:cellWidth.
function ActionSkillWindow:cellWidth()
  return 200
end
-- @ret(string) String representation (for debugging).
function ActionSkillWindow:__tostring()
  return 'Battle Skill Window'
end

return ActionSkillWindow
