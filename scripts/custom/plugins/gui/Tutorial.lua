
-- ================================================================================================

--- Adds a new button to the title screen to show a tutorial window.
---------------------------------------------------------------------------------------------------
-- @plugin Tutorial

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local Menu = require('core/gui/Menu')
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local TitleCommandWindow = require('core/gui/menu/window/interactable/TitleCommandWindow')

-- Rewrites
local TitleCommandWindow_createWidgets = TitleCommandWindow.createWidgets
local TitleCommandWindow_rowCount = TitleCommandWindow.rowCount

-- Parameters
local width = args.width
local height = args.height
local texts = args.text:split()

-- ------------------------------------------------------------------------------------------------
-- Player
-- ------------------------------------------------------------------------------------------------

--- Rewrites `TitleCommandWindow:createWidgets`.
-- @rewrite
function TitleCommandWindow:createWidgets()
  TitleCommandWindow_createWidgets(self)
  local button = Button:fromKey(self, 'tutorial')
  self:moveWidget(button, button.index - 1)
end
--- Settings button.
function TitleCommandWindow:tutorialConfirm()
  self.menu.topText:setVisible(false)
  self:hide()
  local menu = Menu()
  local w = width or ScreenManager.width - DescriptionWindow:paddingX() * 2
  local h = height or ScreenManager.height - DescriptionWindow:paddingY() * 2
  local window = DescriptionWindow(menu, w, h)
  window.text:setAlign('left', 'top')
  window.text.sprite.wrap = true
  window.text.sprite.defaultFont = Fonts.menu_medium
  local text = ''
  for i = 1, #texts do
    text = text .. '    ' .. Vocab.dialogues.tutorial[texts[i]] .. "\n"
  end
  window:updateText(text)
  window.confirmSound = Config.sounds.buttonCancel
  window.cancelSound = Config.sounds.buttonCancel
  menu.windowList:add(window)
  menu.activeWindow = window
  MenuManager:showMenuForResult(menu)
  self.menu.topText:setVisible(true)
  self:show()
end
--- Rewrites `TitleCommandWindow:rowCount`.
-- @rewrite
function TitleCommandWindow:rowCount()
  return TitleCommandWindow_rowCount(self) + 1
end
