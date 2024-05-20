
-- ================================================================================================

--- The small windows with the commands for character management.
---------------------------------------------------------------------------------------------------
-- @windowmod MemberCommandWindow
-- @extend GridWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local EquipMenu = require('core/gui/members/EquipMenu')
local ItemMenu = require('core/gui/members/ItemMenu')
local GridWindow = require('core/gui/GridWindow')
local SkillMenu = require('core/gui/members/SkillMenu')

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

--- Items button. Opens a new `ItemMenu`.
function MemberCommandWindow:itemsConfirm()
  self:showMenu(ItemMenu)
end
--- Skills button. Opens a new `SkillMenu`.
function MemberCommandWindow:skillsConfirm()
  self:showMenu(SkillMenu)
end
--- Equips button. Open a new `EquipMenu`.
function MemberCommandWindow:equipsConfirm()
  self:showMenu(EquipMenu)
end

-- ------------------------------------------------------------------------------------------------
-- Enabled Conditions
-- ------------------------------------------------------------------------------------------------

--- Checks if the ItemMenu can be open.
-- @treturn boolean Whether the item button should be enabled for the current battler.
function MemberCommandWindow:itemsEnabled()
  return ItemMenu:memberEnabled(self.menu:currentMember())
end
--- Checks if the SkillMenu can be open.
-- @treturn boolean Whether the skill button should be enabled for the current battler.
function MemberCommandWindow:skillsEnabled()
  return SkillMenu:memberEnabled(self.menu:currentMember())
end

-- ------------------------------------------------------------------------------------------------
-- Member Menu
-- ------------------------------------------------------------------------------------------------

--- Shows a sub Menu for the current member.
-- @tparam class Menu A subclass of the `Menu` class that will be instantiated.
function MemberCommandWindow:showMenu(Menu)
  self.cursor:hide()
  self.menu:showSubMenu(Menu)
  self.cursor:show()
end
--- Called when player presses "next" key.
function MemberCommandWindow:onNext()
  AudioManager:playSFX(Config.sounds.buttonSelect)
  self.menu:nextMember()
end
--- Called when player presses "prev" key.
function MemberCommandWindow:onPrev()
  AudioManager:playSFX(Config.sounds.buttonSelect)
  self.menu:prevMember()
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
-- For debugging.
function MemberCommandWindow:__tostring()
  return 'Member Command Window'
end

return MemberCommandWindow
