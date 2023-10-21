
-- ================================================================================================

--- The window that shows the list of skills to be used.
---------------------------------------------------------------------------------------------------
-- @classmod SkillWindow
-- @extend ListWindow

-- ================================================================================================

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local Button = require('core/gui/widget/control/Button')
local ListWindow = require('core/gui/common/window/interactable/ListWindow')
local MenuTargetGUI = require('core/gui/common/MenuTargetGUI')
local Vector = require('core/math/Vector')

-- Class table.
local SkillWindow = class(ListWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam GUI gui Parent GUI.
function SkillWindow:init(gui)
  self.visibleRowCount = 4
  self.member = gui:currentMember()
  ListWindow.init(self, gui, self.member:getSkillList())
end
--- Overrides `ListWindow:createWidgets`. 
-- @override
function SkillWindow:createWidgets()
  if #self.list > 0 then
    ListWindow.createWidgets(self)
  else
    Button(self)
  end
end
--- Creates a button from an item.
-- @tparam SkillAction skill The button's skill.
function SkillWindow:createListButton(skill)
  local icon = skill.data.icon.id >= 0 and 
    ResourceManager:loadIconAnimation(skill.data.icon, GUIManager.renderer)
  local button = Button(self)
  button:createIcon(icon)
  button:createText('data.skill.' .. skill.data.key, skill.data.name, 'gui_button')
  button.skill = skill
  -- Get SP cost
  local cost = 0
  for i = 1, #skill.costs do
    if skill.costs[i].key == Config.battle.attSP then
      cost = cost + skill.costs[i].cost(skill, self.member.att)
    end
  end
  button:createInfoText(cost .. '{%sp}', '', 'gui_button')
  return button
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Changes current member.
-- @tparam Battler battler The battler associated with the current/chosen character.
function SkillWindow:setBattler(battler)
  self.member = battler
  self:refreshSkills()
end
--- Updates buttons to match new state of the skill list.
function SkillWindow:refreshSkills()
  self:refreshButtons(self.member and self.member:getSkillList() or {})
end

-- ------------------------------------------------------------------------------------------------
-- Input handlers
-- ------------------------------------------------------------------------------------------------

--- Open target selector for the chosen skill.
-- @tparam Button button
function SkillWindow:onButtonConfirm(button)
  local input = ActionInput(button.skill, self.member)
  if button.skill:isArea() then
    -- Use in all members
    input.targets = self.member.troop:currentBattlers()
    input.action:menuUse(input)
    self.GUI:refreshMember()
  elseif button.skill:isRanged() then
    -- Choose a target
    self.GUI:hide()
    local gui = MenuTargetGUI(self.GUI, self.member.troop, input)
    GUIManager:showGUIForResult(gui)
    _G.Fiber:wait()
    self.GUI:show()
  else
    -- Use on user themselves
    input.target = input.user
    input.action:menuUse(input)
    self.GUI:refreshMember()
  end
  for i = 1, #self.matrix do
    self.matrix[i]:refreshEnabled()
    self.matrix[i]:refreshState()
  end
end
--- Updates description when button is selected.
-- @tparam Button button
function SkillWindow:onButtonSelect(button)
  if self.GUI.descriptionWindow then
    if button.skill then
      self.GUI.descriptionWindow:updateTerm('data.skill.' .. button.skill.data.key .. '_desc', button.skill.data.description)
    else
      self.GUI.descriptionWindow:updateText('')
    end
  end
end
--- Changes current member to the next member in the party.
function SkillWindow:onNext()
  if self.GUI.nextMember then
    AudioManager:playSFX(Config.sounds.buttonSelect)
    self.GUI:nextMember()
  end
end
--- Changes current member to the previous member in the party.
function SkillWindow:onPrev()
  if self.GUI.nextMember then
    AudioManager:playSFX(Config.sounds.buttonSelect)
    self.GUI:prevMember()
  end
end
--- Tells the selected skill can be used.
-- @tparam Button button
-- @treturn boolean
function SkillWindow:buttonEnabled(button)
  return not self.member or self.member:isActive() and button.skill
    and button.skill:canMenuUse(self.member)
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `ListWindow:cellWidth`. 
-- @override
function SkillWindow:cellWidth()
  return 200
end
--- Overrides `GridWindow:colCount`. 
-- @override
function SkillWindow:colCount()
  return 1
end
--- Overrides `GridWindow:rowCount`. 
-- @override
function SkillWindow:rowCount()
  return self.visibleRowCount
end
-- @treturn string String representation (for debugging).
function SkillWindow:__tostring()
  return 'Menu Skill Window'
end

return SkillWindow
