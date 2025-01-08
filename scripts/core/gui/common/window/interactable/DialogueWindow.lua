
-- ================================================================================================

--- A window that shows a `Dialogue`.
---------------------------------------------------------------------------------------------------
-- @windowmod DialogueWindow
-- @extend Window

-- ================================================================================================

-- Imports
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local Dialogue = require('core/gui/widget/Dialogue')
local Vector = require('core/math/Vector')
local Window = require('core/gui/Window')

-- Class table.
local DialogueWindow = class(DescriptionWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Menu menu Parent Menu.
-- @tparam[opt] number w Width of the window.
-- @tparam[opt] number h Height of the window.
-- @tparam[opt] Vector pos The position of the center of the window.
function DialogueWindow:init(menu, w, h, pos)
  self:initProperties()
  w = w or ScreenManager.width - menu:windowMargin()
  h = h or ScreenManager.height / 4
  pos = pos or Vector((w - ScreenManager.width) / 2 + menu:windowMargin(),
    (ScreenManager.height - h) / 2 - menu:windowMargin())
  Window.init(self, menu, w, h, pos)
end
--- Sets window's properties.
function DialogueWindow:initProperties()
  self.nameWidth = 80
  self.nameHeight = 24
  self.nameX = -0.70
  self.nameY = -1.25
end
--- Overrides `Window:createContent`. Creates a simple text for dialogue.
-- @override
function DialogueWindow:createContent(width, height)
  Window.createContent(self, width, height)
  self.dialogue = Dialogue('', nil, nil, 'left', Fonts.menu_dialogue)
  self.dialogue:setMaxHeight(height - self:paddingY() * 2)
  self.text = self.dialogue
  self.content:add(self.dialogue)
  self.nameWindow = DescriptionWindow(self.menu, self.nameWidth, self.nameHeight)
  self.nameWindow:setVisible(false)
  self:packToWindow()
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Called when player presses a mouse button.
function DialogueWindow:onClick(button, x, y)
  self:onConfirm()
end
--- Overrides `Window:hide`. 
-- @override
function DialogueWindow:hide(...)
  self.nameWindow:setVisible(false)
  Window.hide(self, ...)
end
--- Overrides `Window:destroy`. 
-- @override
function DialogueWindow:destroy(...)
  self.nameWindow:destroy()
  self.nameWindow:removeSelf()
  Window.destroy(self, ...)
end

-- ------------------------------------------------------------------------------------------------
-- Dialogue
-- ------------------------------------------------------------------------------------------------

--- Shows a message and waits until player presses the confirm button.
-- @coroutine
-- @tparam string text The message.
-- @tparam string align The text's horizontal alignment ('left', 'right' or 'center').
-- @tparam[opt] table speaker The speaker's name and position of name box.
function DialogueWindow:showDialogue(text, align, speaker)
  if speaker then
    self:setName(speaker.name, speaker.x, speaker.y)
  end
  self.dialogue:setAlign(align)
  self.dialogue:show()
  self.dialogue:rollText(text)
end

-- ------------------------------------------------------------------------------------------------
-- Speaker
-- ------------------------------------------------------------------------------------------------

--- Shows the name of the speaker.
-- @tparam string text The text that will appear in the window. Pass nil or empty to hide the window.
-- @tparam[opt=0] number x The window's x position relative to the parent DialogueWindow's position, in percentage.
-- @tparam[opt=0] number y The window's y position relative to the parent DialogueWindow's position, in percentage.
function DialogueWindow:setName(text, x, y)
  if text and text ~= '' then
    x = (x or 0) / 100
    y = (y or 0) / 100
    local nx = (x + self.nameX) * self.width / 2
    local ny = (y + self.nameY) * self.height / 2
    self.nameWindow:updateText(text)
    self.nameWindow:packToText()
    local nameX = self.position.x + nx or self.nameWindow.position.x
    local nameY = self.position.y + ny or self.nameWindow.position.y
    self.nameWindow:setVisible(true)
    self.nameWindow:setXYZ(nameX, nameY, -5)
  else
    self.nameWindow:setVisible(false)
  end
end

return DialogueWindow
