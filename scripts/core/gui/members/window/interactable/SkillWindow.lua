
--[[===============================================================================================

SkillWindow
---------------------------------------------------------------------------------------------------
The window that shows the list of skills to be used.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local Button = require('core/gui/widget/control/Button')
local ListWindow = require('core/gui/common/window/interactable/ListWindow')
local MenuTargetGUI = require('core/gui/common/MenuTargetGUI')
local Vector = require('core/math/Vector')

local SkillWindow = class(ListWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(gui : GUI) Parent GUI.
function SkillWindow:init(gui)
  self.member = gui.parent:currentMember()
  ListWindow.init(self, gui, self.member.skillList)
end
-- Changes current member.
-- @param(member : Battler)
function SkillWindow:setMember(member)
  self.member = member
  self:refreshButtons()
end
-- Creates a button from an item.
-- @param(id : number) The item's ID.
function SkillWindow:createListButton(skill)
  local icon = skill.data.icon.id >= 0 and 
    ResourceManager:loadIconAnimation(skill.data.icon, GUIManager.renderer)
  local button = Button(self)
  button:createIcon(icon)
  button:createText(skill.data.name, 'gui_medium')
  button.skill = skill
  button.description = skill.data.description
  -- Get SP cost
  local cost = 0
  for i = 1, #skill.costs do
    if skill.costs[i].key == Config.battle.attSP then
      cost = cost + skill.costs[i].cost(skill, self.member.att)
    end
  end
  button:createInfoText(cost .. Vocab.sp, 'gui_medium')
  return button
end

---------------------------------------------------------------------------------------------------
-- Input handlers
---------------------------------------------------------------------------------------------------

-- Open target selector for the chosen skill.
-- @param(button : Button)
function SkillWindow:onButtonConfirm(button)
  local input = ActionInput(button.skill, self.member)
  if button.skill:isArea() then
    -- Use in all members
    input.targets = self.member.troop:currentBattlers()
    input.action:menuUse(input)
    self.GUI.parent:refreshMember()
  else
    -- Choose a target
    local parent = self.GUI.parent
    GUIManager.fiberList:fork(parent.hide, parent)
    self.GUI:hide()
    local gui = MenuTargetGUI(self.GUI, self.member.troop)
    gui.input = input
    GUIManager:showGUIForResult(gui)
    GUIManager.fiberList:fork(parent.show, parent)
    _G.Fiber:wait()
    self.GUI:show()
  end
  for i = 1, #self.matrix do
    self.matrix[i]:refreshEnabled()
    self.matrix[i]:refreshState()
  end
end
-- Updates description when button is selected.
-- @param(button : Button)
function SkillWindow:onButtonSelect(button)
  self.GUI.descriptionWindow:updateText(button.description)
end
-- Changes current member to the next member in the party.
function SkillWindow:onNext()
  self.GUI.parent:nextMember()
end
-- Changes current member to the previous member in the party.
function SkillWindow:onPrev()
  self.GUI.parent:prevMember()
end
-- Tells the selected skill can be used.
-- @param(button : Button)
-- @ret(boolean)
function SkillWindow:buttonEnabled(button)
  return self.member:isActive() and button.skill and button.skill:canMenuUse(self.member)
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function SkillWindow:colCount()
  return 2
end
-- Overrides GridWindow:rowCount.
function SkillWindow:rowCount()
  return 6
end
-- @ret(string) String representation (for debugging).
function SkillWindow:__tostring()
  return 'Menu Skill Window'
end

return SkillWindow
