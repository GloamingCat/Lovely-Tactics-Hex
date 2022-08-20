
--[[===============================================================================================

TitleGUI
---------------------------------------------------------------------------------------------------
The GUI that is shown in the end of the battle.

=================================================================================================]]

-- Imports
local GUI = require('core/gui/GUI')
local LoadWindow = require('core/gui/menu/window/interactable/LoadWindow')
local Sprite = require('core/graphics/Sprite')
local Text = require('core/graphics/Text')
local TitleCommandWindow = require('core/gui/menu/window/interactable/TitleCommandWindow')

local TitleGUI = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialize
---------------------------------------------------------------------------------------------------

-- Implements GUI:createWindows.
function TitleGUI:createWindows()
  self.name = 'Title GUI'
  self.coverSpeed = 2
  self:createCover()
  self:createTopText()
  self:createCommandWindow()
  self:createLoadWindow()
  self:setActiveWindow(self.commandWindow)
end
-- Creates cover sprite.
function TitleGUI:createCover()
  local id = Config.screen.coverID
  if id and id >= 0 then
    self.cover = ResourceManager:loadSprite(Database.animations[id], GUIManager.renderer)
    self.cover:setXYZ(0, 0, 10)
    self.cover.texture:setFilter('linear', 'linear')
    self.cover:setRGBA(nil, nil, nil, 0)
  end
end
-- Creates the text at the top of the screen to show that the player won.
function TitleGUI:createTopText()
  local prop = {
    ScreenManager.width,
    'center',
    Fonts.gui_title }
  self.topText = Text(Config.name, prop, GUIManager.renderer)
  local x = -ScreenManager.width / 2
  local y = -ScreenManager.height / 2 + self:windowMargin() * 2
  self.topText:setXYZ(x, y, 9)
  self.topText:setRGBA(nil, nil, nil, 0)
end
-- Creates the main window with New / Load / etc.
function TitleGUI:createCommandWindow()
  local window = TitleCommandWindow(self)
  window:setXYZ((window.width - ScreenManager.width) / 2 + self:windowMargin(),
    (ScreenManager.height - window.height) / 2 - self:windowMargin())
  self.commandWindow = window
end
-- Creates the window with the save files to load.
function TitleGUI:createLoadWindow()
  if next(SaveManager.saves) ~= nil then
    local window = LoadWindow(self)
    window:setVisible(false)
    self.loadWindow = window
  end
end

---------------------------------------------------------------------------------------------------
-- Cover
---------------------------------------------------------------------------------------------------

-- Overrides GUI:show to show cover before windows.
function TitleGUI:show(...)
  if not self.cover or self.cover.color.alpha == 0 then
    self:showCover()
  end
  GUI.show(self, ...)
end
-- Fades in cover and title.
function TitleGUI:showCover()
  if AudioManager.titleTheme then
    AudioManager:playBGM(AudioManager.titleTheme, 60 / self.coverSpeed)
  end
  local time = 0
  while time < 1 do
    time = math.min(1, time + GameManager:frameTime() * self.coverSpeed)
    self.topText:setRGBA(nil, nil, nil, time)
    if self.cover then
      self.cover:setRGBA(nil, nil, nil, time)
    end
    Fiber:wait()
  end
end
-- Faces out cover and title.
function TitleGUI:hideCover()
  if Config.sounds.titleTheme then
    AudioManager:pauseBGM(60 / self.coverSpeed)
  end
  local time = 1
  while time > 0 do
    time = math.max(0, time - GameManager:frameTime() * self.coverSpeed)
    self.topText:setRGBA(nil, nil, nil, time)
    if self.cover then
      self.cover:setRGBA(nil, nil, nil, time)
    end
    Fiber:wait()
  end
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Overrides GUI:destroy to destroy top text.
function TitleGUI:destroy(...)
  GUI.destroy(self, ...)
  self.topText:destroy()
  if self.cover then
    self.cover:destroy()
  end
end
-- Overrides GUI:windowMargin.
function TitleGUI:windowMargin()
  return 10
end

return TitleGUI
