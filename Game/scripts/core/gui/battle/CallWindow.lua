
--[[===============================================================================================

CallWindow
---------------------------------------------------------------------------------------------------
Window with the list of battles in the party backup.

=================================================================================================]]

local Battler = require('core/battle/Battler')
local ButtonWindow = require('core/gui/ButtonWindow')

local CallWindow = class(ButtonWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function CallWindow:init(GUI)
  ButtonWindow.init(self, GUI)
end
-- Creates a button for each backup member.
function CallWindow:createButtons()
  local backup = PartyManager:backupBattlersIDs()
  for i = 1, #backup do
    local battler = Battler(backup[i], TroopManager.playerParty)
    local button = self:addButton(battler.data.name, nil, self.onButtonConfirm)
    button.onSelect = self.onButtonSelect
    button.battler = battler
  end
end

---------------------------------------------------------------------------------------------------
-- Callbacks
---------------------------------------------------------------------------------------------------

-- Confirm callback for each button, returns the chosen battle.
function CallWindow:onButtonConfirm(button)
  self.result = button.battler
end
-- Select callback for each button, show the battler's info.
function CallWindow:onButtonSelect(button)
  -- TODO: show target window
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides ButtonWindow:buttonWidth.
function CallWindow:buttonWidth()
  return 70
end
-- Overrides ButtonWindow:colCount.
function CallWindow:colCount()
  return 1
end
-- Overrides ButtonWindow:rowCount.
function CallWindow:rowCount()
  return 4
end

return CallWindow
