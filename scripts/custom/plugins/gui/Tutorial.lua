
--[[===============================================================================================

Tutorial
---------------------------------------------------------------------------------------------------
Adds a new button to the title screen to show a tutorial window.

=================================================================================================]]

-- Imports
local Button = require('core/gui/widget/control/Button')
local GUI = require('core/gui/GUI')
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local TitleCommandWindow = require('core/gui/menu/window/interactable/TitleCommandWindow')

-- Parameters
local width = args.width
local height = args.height
local texts = args.text:split()

---------------------------------------------------------------------------------------------------
-- Player
---------------------------------------------------------------------------------------------------

-- Overrides TitleCommandWindow:createWidgets.
local TitleCommandWindow_createWidgets = TitleCommandWindow.createWidgets
function TitleCommandWindow:createWidgets()
  TitleCommandWindow_createWidgets(self)
  local button = Button:fromKey(self, 'tutorial')
  self:moveWidget(button, button.index - 1)
end
-- Settings button.
function TitleCommandWindow:tutorialConfirm()
  self.GUI.topText:setVisible(false)
  self:hide()
  local gui = GUI()
  local w = width or ScreenManager.width - DescriptionWindow:paddingX() * 2
  local h = height or ScreenManager.height - DescriptionWindow:paddingY() * 2
  local window = DescriptionWindow(gui, w, h)
  window.text:setAlign('left', 'top')
  window.text.sprite.wrap = true
  window.text.sprite.defaultFont = Fonts.gui_medium
  local text = ''
  for i = 1, #texts do
    text = text .. '    ' .. Vocab.dialogues.tutorial[texts[i]] .. "\n"
  end
  window:updateText(text)
  window.confirmSound = Config.sounds.buttonCancel
  window.cancelSound = Config.sounds.buttonCancel
  gui.windowList:add(window)
  gui.activeWindow = window
  GUIManager:showGUIForResult(gui)
  self.GUI.topText:setVisible(true)
  self:show()
end
-- Overrides TitleCommandWindow:rowCount.
local TitleCommandWindow_rowCount = TitleCommandWindow.rowCount
function TitleCommandWindow:rowCount()
  return TitleCommandWindow_rowCount(self) + 1
end
