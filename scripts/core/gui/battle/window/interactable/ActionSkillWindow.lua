
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
function ActionSkillWindow:init(gui, skillList)
  local m = gui:windowMargin()
  local w = ScreenManager.width - gui:windowMargin() * 2
  local h = ScreenManager.height * 4 / 5 - self:paddingY() * 2 - m * 3
  self.visibleRowCount = math.floor(h / self:cellHeight())
  local fith = self.visibleRowCount * self:cellHeight() + self:paddingY() * 2
  local pos = Vector(0, fith / 2 - ScreenManager.height / 2 + m / 2, 0)
  ListWindow.init(self, gui, skillList, w, h, pos)
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
  button:createText(skill.data.name, 'gui_medium')
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
  button:createInfoText(cost .. Vocab.sp, 'gui_medium')
  return button
end

---------------------------------------------------------------------------------------------------
-- Input handlers
---------------------------------------------------------------------------------------------------

-- Updates description when button is selected.
-- @param(button : Button)
function ActionSkillWindow:onButtonSelect(button)
  self.GUI.descriptionWindow:updateText(button.description)
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
  return 2
end
-- Overrides GridWindow:rowCount.
function ActionSkillWindow:rowCount()
  return self.visibleRowCount
end
-- @ret(string) String representation (for debugging).
function ActionSkillWindow:__tostring()
  return 'Battle Skill Window'
end

return ActionSkillWindow
