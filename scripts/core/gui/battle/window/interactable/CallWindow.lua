
--[[===============================================================================================

CallWindow
---------------------------------------------------------------------------------------------------
Window with the list of battles in the party backup.

=================================================================================================]]

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')

-- Alias
local max = math.max

local CallWindow = class(GridWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function CallWindow:init(GUI, troop, allMembers)
  self.troop = troop
  self.allMembers = allMembers
  GridWindow.init(self, GUI)
end
-- Creates a button for each backup member.
function CallWindow:createWidgets()
  local current = self.troop:currentBattlers()
  local backup = self.troop:backupBattlers()
  if self.allMembers then
    for i = 1, #current do
      self:createBattlerButton(current[i])
    end
  end
  for i = 1, #backup do
    self:createBattlerButton(backup[i])
  end
  if self.allMembers and #current > 1 then
    self:createNoneButton()
  end
end
-- @param(battler : Battler) Battler associated with this button.
-- @ret(Button)
function CallWindow:createBattlerButton(battler)
  local button = Button(self)
  button:createText(battler.name)
  button.battler = battler
  button.memberKey = battler.key
  return button
end
-- @ret(Button)
function CallWindow:createNoneButton()
  local button = Button(self)
  button:createText(Vocab.none)
  button.memberKey = ''
  if self.GUI.targetWindow then
    self.GUI.targetWindow:setVisible(false)
  end
  return button
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
    if button.battler then 
      GUIManager.fiberList:fork(function()
          self.GUI.targetWindow:show()
          self.GUI.targetWindow:setBattler(button.battler)
        end)
    else
      GUIManager.fiberList:fork(self.GUI.targetWindow.hide, self.GUI.targetWindow)
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:cellWidth.
function CallWindow:cellWidth()
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

function CallWindow:__tostring()
  return 'Call Window'
end

return CallWindow
