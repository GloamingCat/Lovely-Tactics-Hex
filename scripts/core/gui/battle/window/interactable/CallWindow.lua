
-- ================================================================================================

--- Window with the list of battles in the party backup.
---------------------------------------------------------------------------------------------------
-- @windowmod CallWindow
-- @extend GridWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')

-- Alias
local max = math.max

-- Class table.
local CallWindow = class(GridWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
function CallWindow:init(Menu, troop, allMembers)
  self.troop = troop
  self.allMembers = allMembers
  GridWindow.init(self, Menu)
end
--- Creates a button for each backup member.
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
--- Creates a button to call a given battler.
-- @tparam Battler battler Battler associated with this button.
-- @treturn Button Created button.
function CallWindow:createBattlerButton(battler)
  local button = Button(self)
  button:createText('data.battler.' .. battler.key, battler.name)
  button.battler = battler
  button.memberKey = battler.key
  return button
end
--- Creates a button to remove the current battler.
-- @treturn Button Created button.
function CallWindow:createNoneButton()
  local button = Button(self)
  button:createText('none', '')
  button.memberKey = ''
  if self.menu.targetWindow then
    self.menu.targetWindow:setVisible(false)
  end
  return button
end

-- ------------------------------------------------------------------------------------------------
-- Callbacks
-- ------------------------------------------------------------------------------------------------

--- Confirm callback for each button, returns the chosen battle.
-- @tparam Button button Selected button.
function CallWindow:onButtonConfirm(button)
  self.result = button.memberKey
end
--- Select callback for each button, show the battler's info.
-- @tparam Button button Selected button.
function CallWindow:onButtonSelect(button)
  if self.menu.targetWindow then
    if button.battler then 
      MenuManager.fiberList:fork(function()
          self.menu.targetWindow:show()
          self.menu.targetWindow:setBattler(button.battler)
        end)
    else
      MenuManager.fiberList:forkMethod(self.menu.targetWindow, 'hide')
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:cellWidth`. 
-- @override
function CallWindow:cellWidth()
  return 70
end
--- Overrides `GridWindow:colCount`. 
-- @override
function CallWindow:colCount()
  return 1
end
--- Overrides `GridWindow:rowCount`. 
-- @override
function CallWindow:rowCount()
  return 4
end
-- For debugging.
function CallWindow:__tostring()
  return 'Call Window'
end

return CallWindow
