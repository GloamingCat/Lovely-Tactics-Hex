
-- ================================================================================================

--- The small windows with the commands for character management.
---------------------------------------------------------------------------------------------------
-- @classmod MemberCommandWindow
-- @extend GridWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local EquipGUI = require('core/gui/members/EquipGUI')
local ItemGUI = require('core/gui/members/ItemGUI')
local GridWindow = require('core/gui/GridWindow')
local SkillGUI = require('core/gui/members/SkillGUI')

-- Class table.
local MemberCommandWindow = class(GridWindow)

-- ------------------------------------------------------------------------------------------------
-- Buttons
-- ------------------------------------------------------------------------------------------------

--- Constructor.
function MemberCommandWindow:createWidgets()
  Button:fromKey(self, 'equips')
  Button:fromKey(self, 'skills')
  Button:fromKey(self, 'items')
end

-- ------------------------------------------------------------------------------------------------
-- Confirm Callbacks
-- ------------------------------------------------------------------------------------------------

--- Items button.
function MemberCommandWindow:itemsConfirm()
  self:showGUI(ItemGUI)
end
--- Skills button.
function MemberCommandWindow:skillsConfirm()
  self:showGUI(SkillGUI)
end
--- Equips button.
function MemberCommandWindow:equipsConfirm()
  self:showGUI(EquipGUI)
end

-- ------------------------------------------------------------------------------------------------
-- Enabled Conditions
-- ------------------------------------------------------------------------------------------------

-- @treturn boolean True if Item GUI may be open, false otherwise.
function MemberCommandWindow:itemsEnabled()
  return ItemGUI:memberEnabled(self.GUI:currentMember())
end
-- @treturn boolean True if Skill GUI may be open, false otherwise.
function MemberCommandWindow:skillsEnabled()
  return SkillGUI:memberEnabled(self.GUI:currentMember())
end

-- ------------------------------------------------------------------------------------------------
-- Member GUI
-- ------------------------------------------------------------------------------------------------

--- Shows a sub GUI for the current member.
-- @tparam class GUI
function MemberCommandWindow:showGUI(GUI)
  self.cursor:hide()
  self.GUI:showSubGUI(GUI)
  self.cursor:show()
end
--- Called when player presses "next" key.
function MemberCommandWindow:onNext()
  AudioManager:playSFX(Config.sounds.buttonSelect)
  self.GUI:nextMember()
end
--- Called when player presses "prev" key.
function MemberCommandWindow:onPrev()
  AudioManager:playSFX(Config.sounds.buttonSelect)
  self.GUI:prevMember()
end
--- Changes current selected member.
-- @tparam Battler battler The Battler associated with current/chosen character.
function MemberCommandWindow:setBattler(battler)
  for i = 1, #self.matrix do
    self.matrix[i]:refreshEnabled()
    self.matrix[i]:refreshState()
  end
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:colCount`. 
-- @override
function MemberCommandWindow:colCount()
  return 1
end
--- Overrides `GridWindow:rowCount`. 
-- @override
function MemberCommandWindow:rowCount()
  return 2
end
--- String representation (for debugging).
-- @treturn string
function MemberCommandWindow:__tostring()
  return 'Member Command Window'
end

return MemberCommandWindow
