
-- ================================================================================================

--- The window that is open to choose a skill from character's skill list.
---------------------------------------------------------------------------------------------------
-- @classmod ActionSkillWindow

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
-- @tparam GUI gui /parent GUI.
-- @tparam SkillList skillList Battler's skill set.
-- @tparam number maxHeight The height of the space available for the window (in pixels).
function ActionSkillWindow:init(gui, skillList, maxHeight)
  local y = self:fitOnTop(maxHeight) + gui:windowMargin()
  ListWindow.init(self, gui, skillList, nil, nil, Vector(0, y, 0))
end
--- Creates a button from a skill ID.
-- @tparam SkillAction skill The SkillAction from battler's skill list.
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

-- ------------------------------------------------------------------------------------------------
-- Input handlers
-- ------------------------------------------------------------------------------------------------

--- Updates description when button is selected.
-- @tparam Button button
function ActionSkillWindow:onButtonSelect(button)
  self.GUI.descriptionWindow:updateTerm('data.skill.' .. button.skill.data.key .. '_desc', button.skill.data.description)
end
--- Called when player chooses a skill.
-- @tparam Button button
function ActionSkillWindow:onButtonConfirm(button)
  self:selectAction(button.skill)
end
--- Called when player cancels.
-- @tparam Button button
function ActionSkillWindow:onButtonCancel(button)
  self.GUI:hideDescriptionWindow()
  self:changeWindow(self.GUI.turnWindow)
end
--- Tells if a skill can be used.
-- @tparam Button button
-- @treturn boolean
function ActionSkillWindow:buttonEnabled(button)
  local user = TurnManager:currentCharacter()
  return button.skill:canBattleUse(user) and self:skillActionEnabled(button.skill)
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:colCount`. 
-- @override colCount
function ActionSkillWindow:colCount()
  return 1
end
--- Overrides `ListWindow:cellWidth`. 
-- @override cellWidth
function ActionSkillWindow:cellWidth()
  return 200
end
-- @treturn string String representation (for debugging).
function ActionSkillWindow:__tostring()
  return 'Battle Skill Window'
end

return ActionSkillWindow
