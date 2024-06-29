
-- ================================================================================================

--- Menu to hire or dismiss allies.
---------------------------------------------------------------------------------------------------
-- @menumod RecruitMenu
-- @extend Menu

-- ================================================================================================

-- Imports
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local GoldWindow = require('core/gui/menu/window/GoldWindow')
local Menu = require('core/gui/Menu')
local RecruitCommandWindow = require('core/gui/menu/window/interactable/RecruitCommandWindow')
local RecruitConfirmWindow = require('core/gui/menu/window/interactable/RecruitConfirmWindow')
local RecruitListWindow = require('core/gui/menu/window/interactable/RecruitListWindow')
local Troop = require('core/battle/Troop')
local Vector = require('core/math/Vector')

-- Class table.
local RecruitMenu = class(Menu)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Menu parent Parent Menu.
-- @tparam table chars Array of characters to be hired/dismissed.
-- @tparam boolean dismiss Allow to dismiss battler in the same menu.
-- @tparam Troop troop The troop recruiting new battlers.
function RecruitMenu:init(parent, chars, dismiss, troop)
  self.troop = troop or Troop()
  self.chars = chars
  self.dismiss = dismiss
  Menu.init(self, parent)
end
--- Implements `Menu:createWindow`.
-- @implement
function RecruitMenu:createWindows()
  self:createCommandWindow()
  self:createGoldWindow()
  self:createListWindow()
  self:createConfirmWindow()
  self:createDescriptionWindow()
  self:setActiveWindow(self.commandWindow)
end
--- Creates the window with the main "hire" and "dismiss" commands.
function RecruitMenu:createCommandWindow()
  local window = RecruitCommandWindow(self, #self.chars > 0, self.dismiss)
  local x = window.width / 2 - ScreenManager.width / 2 + self:windowMargin()
  local y = window.height / 2 - ScreenManager.height / 2 + self:windowMargin()
  window:setXYZ(x, y)
  self.commandWindow = window
end
--- Creates the window showing the troop's current money.
function RecruitMenu:createGoldWindow()
  local width = ScreenManager.width - self.commandWindow.width - self:windowMargin() * 3
  local height = self.commandWindow.height
  local x = ScreenManager.width / 2 - self:windowMargin() - width / 2
  local y = self.commandWindow.position.y
  self.goldWindow = GoldWindow(self, width, height, Vector(x, y))
  self.goldWindow:setGold(self.troop.money)
end
--- Creates the window with the list of battlers to hire.
function RecruitMenu:createListWindow()
  local window = RecruitListWindow(self)
  local y = window.height / 2 - ScreenManager.height / 2 +
    self.commandWindow.height + self:windowMargin() * 2
  window:setXYZ(nil, y)
  self.listWindow = window
  window:setVisible(false)
end
--- Creates the window with the number of battlers to hire.
function RecruitMenu:createConfirmWindow()
  local width = ScreenManager.width / 2
  local height = self.listWindow.height
  self.countWindow = RecruitConfirmWindow(self, width, height, self.listWindow.position)
  self.countWindow:setVisible(false)
end
--- Creates the window with the description of the selected item.
function RecruitMenu:createDescriptionWindow()
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
function RecruitMenu:showRecruitMenu()
  MenuManager.fiberList:forkMethod(self.descriptionWindow, 'show')
  Fiber:wait()
  self.listWindow:show()
  self.listWindow:activate()
end
--- Hides shop windows.
function RecruitMenu:hideRecruitMenu()
  MenuManager.fiberList:forkMethod(self.descriptionWindow, 'hide')
  Fiber:wait()
  self.listWindow:hide()
  self.commandWindow:activate()
end
--- Overrides `Menu:hide`. Saves troop modifications.
-- @override
function RecruitMenu:hide(...)
  TroopManager:saveTroop(self.troop, true)
  Menu.hide(self, ...)
end

return RecruitMenu
