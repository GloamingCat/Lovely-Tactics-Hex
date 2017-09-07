
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
function CallWindow:init(GUI, troop)
  GridWindow.init(self, GUI)
  self.troop = troop
end
-- Creates a button for each backup member.
function CallWindow:createButtons()
  for i = 1, #self.troop.backup do
    local member = self.troop.backup[i]
    local save = self.troop:getMemberData(member.key)
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
  if self.GUI.targetWindow then
    self.GUI.targetWindow:setBattler(button.battler)
  end
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
