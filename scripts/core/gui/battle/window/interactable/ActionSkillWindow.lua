
-- ================================================================================================

--- The window that is open to choose a skill from character's skill list.
---------------------------------------------------------------------------------------------------
-- @windowmod ActionSkillWindow
-- @extend ActionWindow
-- @extend ListWindow

-- ================================================================================================

-- Imports
local ActionWindow = require('core/gui/battle/window/interactable/ActionWindow')
local Button = require('core/gui/widget/control/Button')
local ListWindow = require('core/gui/common/window/interactable/ListWindow')
local Vector = require('core/math/Vector')

-- Class table.
local ActionSkillWindow = class(ActionWindow, ListWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Menu menu Parent Menu.
-- @tparam SkillList skillList Battler's skill set.
-- @tparam number maxHeight The height of the space available for the window (in pixels).
function ActionSkillWindow:init(menu, skillList, maxHeight)
  local y = self:fitOnTop(maxHeight) + menu:windowMargin()
  ListWindow.init(self, menu, skillList, nil, nil, Vector(0, y, 0))
end
--- Creates a button from a skill ID.
-- @tparam SkillAction skill The SkillAction from battler's skill list.
function ActionSkillWindow:createListButton(skill)
  -- Button
  local button = Button(self)
  button:setIcon(skill.data.icon)
  button:createText('{%data.skill.' .. skill.data.key .. '}', skill.data.name, 'menu_button')
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
  button:createInfoText(cost .. '{%sp}', '', 'menu_button')
  return button
end

-- ------------------------------------------------------------------------------------------------
-- Input handlers
-- ------------------------------------------------------------------------------------------------

--- Updates description when button is selected.
-- @tparam Button button
function ActionSkillWindow:onButtonSelect(button)
  self.menu.descriptionWindow:updateTerm('{%data.skill.' .. button.skill.data.key .. '_desc}', button.skill.data.description)
end
--- Called when player chooses a skill.
-- @tparam Button button
function ActionSkillWindow:onButtonConfirm(button)
  self:selectAction(button.skill)
end
--- Called when player cancels.
-- @tparam Button button
function ActionSkillWindow:onButtonCancel(button)
  self.menu:hideDescriptionWindow()
  self:changeWindow(self.menu.turnWindow)
end
--- Tells if a skill can be used.
-- @tparam Button button Button to check, with the skill's information.
-- @treturn boolean True if the skill button should be enabled.
function ActionSkillWindow:buttonEnabled(button)
  local user = TurnManager:currentCharacter()
  return button.skill:canBattleUse(user) and self:skillActionEnabled(button.skill)
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:colCount`. 
-- @override
function ActionSkillWindow:colCount()
  return 1
end
--- Overrides `ListWindow:cellWidth`. 
-- @override
function ActionSkillWindow:cellWidth()
  return 200
end
-- For debugging.
function ActionSkillWindow:__tostring()
  return 'Battle Skill Window'
end

return ActionSkillWindow
