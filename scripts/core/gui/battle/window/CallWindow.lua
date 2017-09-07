
--[[===============================================================================================

CallWindow
---------------------------------------------------------------------------------------------------
Window with the list of battles in the party backup.

=================================================================================================]]

-- Imports
local Button = require('core/gui/Button')
local BattlerBase = require('core/battle/BattlerBase')
local GridWindow = require('core/gui/GridWindow')

-- Alias
local max = math.max

local CallWindow = class(GridWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function CallWindow:init(GUI)
  GridWindow.init(self, GUI)
end
-- Creates a button for each backup member.
function CallWindow:createButtons()
  local troop = TurnManager:currentTroop()
  for i = 1, #troop.backup do
    local member = troop.backup[i]
    local save = troop:getMemberData(member.key)
    local battler = BattlerBase:fromMember(member, save)
    local button = Button(self, battler.data.name, nil, self.onButtonConfirm)
    button.onSelect = self.onButtonSelect
    button.battler = battler
    button.memberKey = member.key
  end
end

---------------------------------------------------------------------------------------------------
-- Callbacks
---------------------------------------------------------------------------------------------------

-- Confirm callback for each button, returns the chosen battle.
function CallWindow:onButtonConfirm(button)
  self.result = button.memberKey
end
-- Select callback for each button, show the battler's info.
function CallWindow:onButtonSelect(button)
  -- TODO: show target window
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:buttonWidth.
function CallWindow:buttonWidth()
  return 70
end
-- Overrides GridWindow:colCount.
function CallWindow:colCount()
  return 1
end
-- Overrides GridWindow:rowCount.
function CallWindow:rowCount()
  return 4
end

return CallWindow
