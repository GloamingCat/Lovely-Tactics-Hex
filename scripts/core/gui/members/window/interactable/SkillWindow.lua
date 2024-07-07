
-- ================================================================================================

--- The window that shows the list of skills to be used.
---------------------------------------------------------------------------------------------------
-- @windowmod SkillWindow
-- @extend ListWindow

-- ================================================================================================

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local Button = require('core/gui/widget/control/Button')
local ListWindow = require('core/gui/common/window/interactable/ListWindow')
local TargetMenu = require('core/gui/common/TargetMenu')
local Vector = require('core/math/Vector')

-- Class table.
local SkillWindow = class(ListWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Menu parent Parent Menu.
function SkillWindow:init(parent)
  self.visibleRowCount = 4
  self.member = parent:currentMember()
  ListWindow.init(self, parent, self.member:getSkillList())
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
  local button = Button(self)
  button:setIcon(skill.data.icon)
  button:createText('{%data.skill.' .. skill.data.key .. '}', skill.data.name, 'menu_button')
  button.skill = skill
  -- Get SP cost
  local cost = 0
  for i = 1, #skill.costs do
    if skill.costs[i].key == Config.battle.attSP then
      cost = cost + skill.costs[i].cost(skill, self.member.att)
    end
  end
  button:createInfoText(cost .. '{%sp}', '', 'menu_button')
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
-- @tparam Button button Selected button.
function SkillWindow:onButtonConfirm(button)
  local input = ActionInput(button.skill, self.member)
  if button.skill:isArea() then
    -- Use in all members
    input.targets = self.member.troop:currentBattlers()
    input.action:menuUse(input)
    self.menu:refreshMember()
  elseif button.skill:isRanged() then
    -- Choose a target
    self.menu:hide()
    local menu = TargetMenu(self.menu, self.member.troop, input)
    MenuManager:showMenuForResult(menu)
    _G.Fiber:wait()
    self.menu:show()
  else
    -- Use on user themselves
    input.target = input.user
    input.action:menuUse(input)
    self.menu:refreshMember()
  end
  for i = 1, #self.matrix do
    self.matrix[i]:refreshEnabled()
    self.matrix[i]:refreshState()
  end
end
--- Updates description when button is selected.
-- @tparam Button button Selected button.
function SkillWindow:onButtonSelect(button)
  if self.menu.descriptionWindow then
    if button.skill then
      self.menu.descriptionWindow:updateTerm('{%data.skill.' .. button.skill.data.key .. '_desc}', button.skill.data.description)
    else
      self.menu.descriptionWindow:updateText('')
    end
  end
end
--- Changes current member to the next member in the party.
function SkillWindow:onNext()
  if self.menu.nextMember then
    AudioManager:playSFX(Config.sounds.buttonSelect)
    self.menu:nextMember()
  end
end
--- Changes current member to the previous member in the party.
function SkillWindow:onPrev()
  if self.menu.nextMember then
    AudioManager:playSFX(Config.sounds.buttonSelect)
    self.menu:prevMember()
  end
end
--- Tells the selected skill can be executed.
-- @tparam Button button Button to check, containing the skill's information.
-- @treturn boolean Whether the skill button should be enabled.
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
-- For debugging.
function SkillWindow:__tostring()
  return 'Menu Skill Window'
end

return SkillWindow
