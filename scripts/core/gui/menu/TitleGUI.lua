
-- ================================================================================================

--- The GUI that is shown in the end of the battle.
-- ------------------------------------------------------------------------------------------------
-- @classmod TitleGUI

-- ================================================================================================

-- Imports
local GUI = require('core/gui/GUI')
local LoadWindow = require('core/gui/menu/window/interactable/LoadWindow')
local Sprite = require('core/graphics/Sprite')
local Text = require('core/graphics/Text')
local TitleCommandWindow = require('core/gui/menu/window/interactable/TitleCommandWindow')

-- Class table.
local TitleGUI = class(GUI)

-- ------------------------------------------------------------------------------------------------
-- Initialize
-- ------------------------------------------------------------------------------------------------

--- Implements GUI:createWindows.
function TitleGUI:createWindows()
  self.name = 'Title GUI'
  self.coverSpeed = 2
  self:createCover()
  self:createTopText()
  self:createLoadWindow()
  self:createCommandWindow()
  self:setActiveWindow(self.commandWindow)
end
--- Creates cover sprite.
function TitleGUI:createCover()
  local id = Config.coverID
  if id and id >= 0 then
    self.cover = ResourceManager:loadSprite(Database.animations[id], GUIManager.renderer)
    self.cover:setXYZ(0, 0, 10)
    self.cover.texture:setFilter('linear', 'linear')
    self.cover:setRGBA(nil, nil, nil, 0)
  end
end
--- Creates the text at the top of the screen to show that the player won.
function TitleGUI:createTopText()
  local id = Config.logoID
  if id and id >= 0 then
    self.topText = ResourceManager:loadSprite(Database.animations[id], GUIManager.renderer)
    self.topText.texture:setFilter('linear', 'linear')
    self.topText:setXYZ(0, 0, 9)
  else 
    local prop = {
      ScreenManager.width,
      'center',
      Fonts.gui_title }
    self.topText = Text(Vocab.data.conf.title or Config.name, prop, GUIManager.renderer)
    local x = -ScreenManager.width / 2
    local y = -ScreenManager.height / 2 + self:windowMargin() * 2
    self.topText:setXYZ(x, y, 9)
  end
  self.topText:setRGBA(nil, nil, nil, 0)
end
--- Creates the main window with New / Load / etc.
function TitleGUI:createCommandWindow()
  local window = TitleCommandWindow(self)
  window:setXYZ((window.width - ScreenManager.width) / 2 + self:windowMargin(),
    (ScreenManager.height - window.height) / 2 - self:windowMargin())
  self.commandWindow = window
end
--- Creates the window with the save files to load.
function TitleGUI:createLoadWindow()
  if SaveManager:hasSaves() then
    local window = LoadWindow(self)
    window:setVisible(false)
    self.loadWindow = window
  end
end

-- ------------------------------------------------------------------------------------------------
-- Cover
-- ------------------------------------------------------------------------------------------------

--- Overrides GUI:show to show cover before windows.
function TitleGUI:show(...)
  if not self.cover or self.cover.color.alpha == 0 then
    self:playBGM()
    self:showCover(false, true)
    self:showCover(true, false)
  end
  GUI.show(self, ...)
end
--- Fades in cover and title.
function TitleGUI:showCover(title, cover)
  if not title and not (self.cover and cover) then
    return
  end
  local time = 0
  while time < 1 do
    time = math.min(1, time + GameManager:frameTime() * self.coverSpeed)
    if title then
      self.topText:setRGBA(nil, nil, nil, time)
    end
    if self.cover and cover then
      self.cover:setRGBA(nil, nil, nil, time)
    end
    Fiber:wait()
  end
end
--- Faces out cover and title.
function TitleGUI:hideCover(title, cover)
  if not title and not (self.cover and cover) then
    return
  end
  local time = 1
  while time > 0 do
    time = math.max(0, time - GameManager:frameTime() * self.coverSpeed)
    if title then
      self.topText:setRGBA(nil, nil, nil, time)
    end
    if self.cover and cover then
      self.cover:setRGBA(nil, nil, nil, time)
    end
    Fiber:wait()
  end
end
--- Starts playing the title theme, if any.
function TitleGUI:playBGM()
  if AudioManager.titleTheme then
    AudioManager:playBGM(AudioManager.titleTheme, 60 / self.coverSpeed)
  end
end
--- Stops playing the title theme, if any.
function TitleGUI:pauseBGM()
  if Config.sounds.titleTheme then
    AudioManager:pauseBGM(60 / self.coverSpeed)
  end
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Overrides GUI:refresh. Refreshes title.
function TitleGUI:refresh()
  GUI.refresh(self)
  if self.topText and self.topText.text then
    self.topText:setText(Vocab.data.conf.title or Config.name)
  end
end
--- Overrides GUI:destroy to destroy top text.
function TitleGUI:destroy(...)
  GUI.destroy(self, ...)
  self.topText:destroy()
  if self.cover then
    self.cover:destroy()
  end
end
--- Overrides GUI:windowMargin.
function TitleGUI:windowMargin()
  return 10
end

return TitleGUI
