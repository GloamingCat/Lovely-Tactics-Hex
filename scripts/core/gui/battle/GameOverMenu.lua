
-- ================================================================================================

--- Opens when player loses the battle.
---------------------------------------------------------------------------------------------------
-- @menumod GameOverMenu
-- @extend Menu

-- ================================================================================================

-- Imports
local Menu = require('core/gui/Menu')
local GameOverWindow = require('core/gui/battle/window/interactable/GameOverWindow')
local Vector = require('core/math/Vector')
local Text = require('core/graphics/Text')

-- Alias
local floor = math.floor

-- Class table.
local GameOverMenu = class(Menu)

-- ------------------------------------------------------------------------------------------------
-- Initialize
-- ------------------------------------------------------------------------------------------------

--- Implements `Menu:createWindows`.
-- @implement
function GameOverMenu:createWindows()
  self.name = 'Game Over Menu'
  self:createTopText()
  self.troop = TroopManager:getPlayerTroop()
  self:createMainWindow()
  self:setActiveWindow(self.mainWindow)
end
--- Creates the text at the top of the screen to show that the player won.
function GameOverMenu:createTopText()
  local prop = {
    ScreenManager.width,
    'center',
    Fonts.menu_huge }
  self.topText = Text(Vocab.lose, prop, MenuManager.renderer)
  local x = -ScreenManager.width / 2
  local y = -ScreenManager.height / 2 + self:windowMargin() * 2
  self.topText:setXYZ(x, y)
  self.topText:setVisible(false)
  self.topTextSpeed = 2
end
--- Creates the window that shows battle results.
function GameOverMenu:createMainWindow()
  local window = GameOverWindow(self)
  self.mainWindow = window
end
--- Overrides `Menu:destroy`. Destroys top text.
-- @override
function GameOverMenu:destroy(...)
  Menu.destroy(self, ...)
  self.topText:destroy()
end

-- ------------------------------------------------------------------------------------------------
-- Show
-- ------------------------------------------------------------------------------------------------

--- Show top text before openning windows.
function GameOverMenu:show(...)
  self:showTopText()
  _G.Fiber:wait(15)
  Menu.show(self, ...)
end
--- Animation that shows the text at the top.
function GameOverMenu:showTopText()
  if AudioManager.gameoverTheme then
    AudioManager:playBGM(AudioManager.gameoverTheme)
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
function GameOverMenu:hide(...)
  Menu.hide(self, ...)
  self:hideTopText()
end
--- Animation that shows the text at the top.
function GameOverMenu:hideTopText()
  if AudioManager.gameoverTheme then
    AudioManager:pauseBGM(120 / self.topTextSpeed)
  end
  local a = 1
  while a > 0 do
    a = a - GameManager:frameTime() * self.topTextSpeed
    self.topText:setRGBA(nil, nil, nil, a)
    Fiber:wait()
  end
  self.topText:setVisible(false)
end

return GameOverMenu
