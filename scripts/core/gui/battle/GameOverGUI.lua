
--[[===============================================================================================

GameOverGUI
---------------------------------------------------------------------------------------------------
The GUI that is shown when player loses the battle.

=================================================================================================]]

-- Imports
local GUI = require('core/gui/GUI')
local GameOverWindow = require('core/gui/battle/window/interactable/GameOverWindow')
local Vector = require('core/math/Vector')
local Text = require('core/graphics/Text')

-- Alias
local floor = math.floor

local GameOverGUI = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialize
---------------------------------------------------------------------------------------------------

-- Implements GUI:createWindows.
function GameOverGUI:createWindows()
  self.name = 'Game Over GUI'
  self:createTopText()
  self.troop = TroopManager:getPlayerTroop()
  self:createMainWindow()
  self:setActiveWindow(self.mainWindow)
end
-- Creates the text at the top of the screen to show that the player won.
function GameOverGUI:createTopText()
  local prop = {
    ScreenManager.width,
    'center',
    Fonts.gui_huge }
  self.topText = Text(Vocab.lose, prop, GUIManager.renderer)
  local x = -ScreenManager.width / 2
  local y = -ScreenManager.height / 2 + self:windowMargin() * 2
  self.topText:setXYZ(x, y)
  self.topText:setVisible(false)
  self.topTextSpeed = 2
end
-- Creates the window that shows battle results.
function GameOverGUI:createMainWindow()
  local window = GameOverWindow(self)
  self.mainWindow = window
end
-- Overrides GUI:destroy to destroy top text.
function GameOverGUI:destroy(...)
  GUI.destroy(self, ...)
  self.topText:destroy()
end

---------------------------------------------------------------------------------------------------
-- Show
---------------------------------------------------------------------------------------------------

-- Show top text before openning windows.
function GameOverGUI:show(...)
  self:showTopText()
  _G.Fiber:wait(15)
  GUI.show(self, ...)
end
-- Animation that shows the text at the top.
function GameOverGUI:showTopText()
  if AudioManager.gameoverTheme then
    AudioManager:playBGM(AudioManager.gameoverTheme)
  end
  local a = 0
  self.topText:setVisible(true)
  self.topText:setRGBA(nil, nil, nil, 0)
  while a < 1 do
    a = a + GameManager:frameTime() * self.topTextSpeed
    self.topText:setRGBA(nil, nil, nil, a)
    coroutine.yield()
  end
  self.topText:setRGBA(nil, nil, nil, 1)
end

---------------------------------------------------------------------------------------------------
-- Hide
---------------------------------------------------------------------------------------------------

-- Hide top text after closing windows.
function GameOverGUI:hide(...)
  GUI.hide(self, ...)
  self:hideTopText()
end
-- Animation that shows the text at the top.
function GameOverGUI:hideTopText()
  if AudioManager.gameoverTheme then
    AudioManager:pauseBGM(120 / self.topTextSpeed)
  end
  local a = 1
  while a > 0 do
    a = a - GameManager:frameTime() * self.topTextSpeed
    self.topText:setRGBA(nil, nil, nil, a)
    coroutine.yield()
  end
  self.topText:setVisible(false)
end

return GameOverGUI
