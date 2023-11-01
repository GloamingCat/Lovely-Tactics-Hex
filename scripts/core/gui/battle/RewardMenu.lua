
-- ================================================================================================

--- Opens after the end of the battle, if the player wins.
---------------------------------------------------------------------------------------------------
-- @menumod RewardMenu
-- @extend Menu

-- ================================================================================================

-- Imports
local Menu = require('core/gui/Menu')
local RewardEXPWindow = require('core/gui/battle/window/RewardEXPWindow')
local RewardItemWindow = require('core/gui/battle/window/RewardItemWindow')
local Vector = require('core/math/Vector')
local Text = require('core/graphics/Text')

-- Alias
local floor = math.floor

-- Class table.
local RewardMenu = class(Menu)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Implements `Menu:createWindows`.
-- @implement
function RewardMenu:createWindows()
  self.name = 'Reward Menu'
  self:createTopText()
  -- Reward windows
  local w = (ScreenManager.width - self:windowMargin() * 3) / 2
  local h = ScreenManager.height - self.topText:getHeight() - self:windowMargin() * 3
  local x = ScreenManager.width / 2 - w / 2 - self:windowMargin()
  local y = ScreenManager.height / 2 - h / 2 - self:windowMargin()
  self.troop = TroopManager:getPlayerTroop()
  self.rewards = BattleManager:getBattleRewards(TroopManager.playerParty)
  self:createEXPWindow(x, y, w, h)
  self:createItemWindow(x, y, w, h)
  self:setActiveWindow(self.expWindow)
  -- Gold / items
  self.troop.money = self.troop.money + self.rewards.money
  self.troop.inventory:addAllItems(self.rewards.items)
end
--- Creates the text at the top of the screen to show that the player won.
function RewardMenu:createTopText()
  local prop = { ScreenManager.width,
    'center', Fonts.menu_huge }
  self.topText = Text(Vocab.win, prop, MenuManager.renderer)
  local x = -ScreenManager.width / 2
  local y = -ScreenManager.height / 2 + self:windowMargin() * 2
  self.topText:setXYZ(x, y)
  self.topText:setVisible(false)
  self.topTextSpeed = 2
end
--- Creates the window that shows battle results.
function RewardMenu:createEXPWindow(x, y, w, h)
  local pos = Vector(-x, y)
  local window = RewardEXPWindow(self, w, h, pos)
  self.expWindow = window
end
--- Creates the window that shows battle results.
function RewardMenu:createItemWindow(x, y, w, h)
  local pos = Vector(x, y)
  local window = RewardItemWindow(self, w, h, pos)
  self.itemWindow = window
end

-- ------------------------------------------------------------------------------------------------
-- Show
-- ------------------------------------------------------------------------------------------------

--- Show top text before openning windows.
function RewardMenu:show(...)
  self:showTopText()
  _G.Fiber:wait(15)
  Menu.show(self, ...)
end
--- Animation that shows the text at the top.
function RewardMenu:showTopText()
  if AudioManager.victoryTheme then
    AudioManager:playBGM(AudioManager.victoryTheme)
  end
  local a = 0
  self.topText:setVisible(true)
  self.topText:setRGBA(nil, nil, nil, 0)
  while a < 1 do
    a = a + GameManager:frameTime() * self.topTextSpeed
    self.topText:setRGBA(nil, nil, nil, a)
    Fiber:wait()
  end
  self.topText:setRGBA(nil, nil, nil, 1)
end

-- ------------------------------------------------------------------------------------------------
-- Hide
-- ------------------------------------------------------------------------------------------------

--- Hide top text after closing windows.
function RewardMenu:hide(...)
  Menu.hide(self, ...)
  self:hideTopText()
end
--- Animation that shows the text at the top.
function RewardMenu:hideTopText()
  if AudioManager.victoryTheme then
    AudioManager:pauseBGM(120 / self.topTextSpeed, true)
  end
  local a = 1
  while a > 0 do
    a = a - GameManager:frameTime() * self.topTextSpeed
    self.topText:setRGBA(nil, nil, nil, a)
    Fiber:wait()
  end
  self.topText:setVisible(false)
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Overrides `Menu:destroy`. Destroys top text.
-- @override
function RewardMenu:destroy(...)
  Menu.destroy(self, ...)
  self.topText:destroy()
end

return RewardMenu
