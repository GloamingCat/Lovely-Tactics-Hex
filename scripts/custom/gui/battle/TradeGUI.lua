
--[[===============================================================================================

TradeGUI
---------------------------------------------------------------------------------------------------
GUI that is shown when player selects a battler during Visualize action.

=================================================================================================]]

-- Imports
local GUI = require('core/gui/GUI')
local TradeWindow = require('core/gui/battle/TradeWindow')
local TradeCountWindow = require('core/gui/battle/TradeCountWindow')

local TradeGUI = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(char1 : Character)
-- @param(char2 : Character)
function TradeGUI:init(char1, char2)
  self.name = 'Trade GUI'
  self.char1 = char1
  self.char2 = char2
  GUI.init(self)
end
-- Overrides GUI:createWindows.
-- Creates both trade window and the count window.
function TradeGUI:createWindows()
  -- Left/right trade windows
  local leftWindow = self:newTradeWindow(self.char1)
  local rightWindow = self:newTradeWindow(self.char2)
  leftWindow.right = rightWindow
  rightWindow.left = leftWindow
  -- Set positions
  local margin = 40
  leftWindow:setXYZ(-leftWindow.width / 2 - margin)
  rightWindow:setXYZ(rightWindow.width / 2 + margin)
  -- Add to active windows list
  self.windowList:add(leftWindow)
  self.windowList:add(rightWindow)
  if #leftWindow.buttonMatrix > 0 then
    self:setActiveWindow(leftWindow)
  else
    self:setActiveWindow(rightWindow)
  end
  -- Auxiliar Count window
  self.countWindow = TradeCountWindow(self)
  local y = -(ScreenManager.height + leftWindow.height) / 4
  self.countWindow:setXYZ(0, y)
end
-- Creates a new trade window for the given char's inventory.
-- @param(char : Character)
function TradeGUI:newTradeWindow(char)
  local str = char.battler.maxWeight()
  return TradeWindow(self, char.battler.inventory, str)
end

return TradeGUI
