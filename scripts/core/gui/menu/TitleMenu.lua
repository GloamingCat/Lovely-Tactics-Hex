
-- ================================================================================================

--- Opens at the start of the game.
---------------------------------------------------------------------------------------------------
-- @menumod TitleMenu
-- @extend Menu

-- ================================================================================================

-- Imports
local Menu = require('core/gui/Menu')
local LoadWindow = require('core/gui/menu/window/interactable/LoadWindow')
local Sprite = require('core/graphics/Sprite')
local Text = require('core/graphics/Text')
local TitleCommandWindow = require('core/gui/menu/window/interactable/TitleCommandWindow')

-- Class table.
local TitleMenu = class(Menu)

-- ------------------------------------------------------------------------------------------------
-- Initialize
-- ------------------------------------------------------------------------------------------------

--- Implements `Menu:createWindows`.
-- @implement
function TitleMenu:createWindows()
  self.name = 'Title Menu'
  self.coverSpeed = 2
  self:createCover()
  self:createTopText()
  self:createLoadWindow()
  self:createCommandWindow()
  self:setActiveWindow(self.commandWindow)
end
--- Creates cover sprite.
function TitleMenu:createCover()
  local id = Config.coverID
  if id and id >= 0 then
    self.cover = ResourceManager:loadSprite(Database.animations[id], MenuManager.renderer)
    self.cover:setXYZ(0, 0, 10)
    self.cover.texture:setFilter('linear', 'linear')
    self.cover:setRGBA(nil, nil, nil, 0)
  end
end
--- Creates the text at the top of the screen to show that the player won.
function TitleMenu:createTopText()
  local id = Config.logoID
  if id and id >= 0 then
    self.topText = ResourceManager:loadSprite(Database.animations[id], MenuManager.renderer)
    self.topText.texture:setFilter('linear', 'linear')
    self.topText:setXYZ(0, 0, 9)
  else 
    local prop = {
      ScreenManager.width,
      'center',
      Fonts.menu_title }
    self.topText = Text(Vocab.data.conf.title or Config.name, prop, MenuManager.renderer)
    local x = -ScreenManager.width / 2
    local y = -ScreenManager.height / 2 + self:windowMargin() * 2
    self.topText:setXYZ(x, y, 9)
  end
  self.topText:setRGBA(nil, nil, nil, 0)
end
--- Creates the main window with New / Load / etc.
function TitleMenu:createCommandWindow()
  local window = TitleCommandWindow(self)
  window:setXYZ((window.width - ScreenManager.width) / 2 + self:windowMargin(),
    (ScreenManager.height - window.height) / 2 - self:windowMargin())
  self.commandWindow = window
end
--- Creates the window with the save files to load.
function TitleMenu:createLoadWindow()
  if SaveManager:hasSaves() then
    local window = LoadWindow(self)
    window:setVisible(false)
    self.loadWindow = window
  end
end

-- ------------------------------------------------------------------------------------------------
-- Cover
-- ------------------------------------------------------------------------------------------------

--- Overrides `Menu:show`. Shows cover before windows.
-- @override
function TitleMenu:show(...)
  if not self.cover or self.cover.color.a == 0 then
    self:playBGM()
    self:showCover(false, true)
    self:showCover(true, false)
  end
  Menu.show(self, ...)
end
--- Fades in cover and title.
function TitleMenu:showCover(title, cover)
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
function TitleMenu:hideCover(title, cover)
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
function TitleMenu:playBGM()
  if AudioManager.titleTheme then
    AudioManager:playBGM(AudioManager.titleTheme, 60 / self.coverSpeed)
  end
end
--- Stops playing the title theme, if any.
function TitleMenu:pauseBGM()
  if Config.sounds.titleTheme then
    AudioManager:pauseBGM(60 / self.coverSpeed)
  end
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Overrides `Menu:refresh`. Refreshes title.
-- @override
function TitleMenu:refresh()
  Menu.refresh(self)
  if self.topText and self.topText.text then
    self.topText:setText(Vocab.data.conf.title or Config.name)
  end
end
--- Overrides `Menu:destroy`. Destroys top text.
-- @override
function TitleMenu:destroy(...)
  Menu.destroy(self, ...)
  self.topText:destroy()
  if self.cover then
    self.cover:destroy()
  end
end
--- Overrides `Menu:windowMargin`. 
-- @override
function TitleMenu:windowMargin()
  return 10
end

return TitleMenu
