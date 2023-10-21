
-- ================================================================================================

--- Menu to hire or dismiss allies.
---------------------------------------------------------------------------------------------------
-- @classmod RecruitGUI
-- @extend GUI

-- ================================================================================================

-- Imports
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local GoldWindow = require('core/gui/menu/window/GoldWindow')
local GUI = require('core/gui/GUI')
local RecruitCommandWindow = require('core/gui/menu/window/interactable/RecruitCommandWindow')
local RecruitConfirmWindow = require('core/gui/menu/window/interactable/RecruitConfirmWindow')
local RecruitListWindow = require('core/gui/menu/window/interactable/RecruitListWindow')
local Troop = require('core/battle/Troop')
local Vector = require('core/math/Vector')

-- Class table.
local RecruitGUI = class(GUI)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `GUI:init`. 
-- @override
-- @tparam GUI parent Parent GUI.
-- @tparam table chars Array of characters to be hired/dismissed.
-- @tparam Troop troop The troop recruiting new battlers.
function RecruitGUI:init(parent, chars, troop)
  self.troop = troop or Troop()
  self.chars = chars
  GUI.init(self, parent)
end
--- Implements `GUI:createWindow`.
-- @implement
function RecruitGUI:createWindows()
  self:createCommandWindow()
  self:createGoldWindow()
  self:createListWindow()
  self:createConfirmWindow()
  self:createDescriptionWindow()
  self:setActiveWindow(self.commandWindow)
end
--- Creates the window with the main "hire" and "dismiss" commands.
function RecruitGUI:createCommandWindow()
  local window = RecruitCommandWindow(self, #self.chars > 0, true)
  local x = window.width / 2 - ScreenManager.width / 2 + self:windowMargin()
  local y = window.height / 2 - ScreenManager.height / 2 + self:windowMargin()
  window:setXYZ(x, y)
  self.commandWindow = window
end
--- Creates the window showing the troop's current money.
function RecruitGUI:createGoldWindow()
  local width = ScreenManager.width - self.commandWindow.width - self:windowMargin() * 3
  local height = self.commandWindow.height
  local x = ScreenManager.width / 2 - self:windowMargin() - width / 2
  local y = self.commandWindow.position.y
  self.goldWindow = GoldWindow(self, width, height, Vector(x, y))
  self.goldWindow:setGold(self.troop.money)
end
--- Creates the window with the list of battlers to hire.
function RecruitGUI:createListWindow()
  local window = RecruitListWindow(self)
  local y = window.height / 2 - ScreenManager.height / 2 +
    self.commandWindow.height + self:windowMargin() * 2
  window:setXYZ(nil, y)
  self.listWindow = window
  window:setVisible(false)
end
--- Creates the window with the number of battlers to hire.
function RecruitGUI:createConfirmWindow()
  local width = ScreenManager.width / 2
  local height = self.listWindow.height
  self.countWindow = RecruitConfirmWindow(self, width, height, self.listWindow.position)
  self.countWindow:setVisible(false)
end
--- Creates the window with the description of the selected item.
function RecruitGUI:createDescriptionWindow()
  local width = ScreenManager.width - self:windowMargin() * 2
  local height = ScreenManager.height - self:windowMargin() * 4 - 
    self.commandWindow.height - self.listWindow.height
  local y = ScreenManager.height / 2 - height / 2 - self:windowMargin()
  self.descriptionWindow = DescriptionWindow(self, width, height, Vector(0, y))
  self.descriptionWindow:setVisible(false)
end

-- ------------------------------------------------------------------------------------------------
-- Show / Hide
-- ------------------------------------------------------------------------------------------------

--- Shows shop windows.
function RecruitGUI:showRecruitGUI()
  GUIManager.fiberList:fork(self.descriptionWindow.show, self.descriptionWindow)
  Fiber:wait()
  self.listWindow:show()
  self.listWindow:activate()
end
--- Hides shop windows.
function RecruitGUI:hideRecruitGUI()
  GUIManager.fiberList:fork(self.descriptionWindow.hide, self.descriptionWindow)
  Fiber:wait()
  self.listWindow:hide()
  self.commandWindow:activate()
end
--- Overrides `GUI:hide`. Saves troop modifications.
-- @override
function RecruitGUI:hide(...)
  TroopManager:saveTroop(self.troop, true)
  GUI.hide(self, ...)
end

return RecruitGUI
