
--[[===============================================================================================

DialogueWindow
---------------------------------------------------------------------------------------------------
Show a dialogue.

=================================================================================================]]

-- Imports
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local Dialogue = require('core/gui/widget/Dialogue')
local Vector = require('core/math/Vector')
local Window = require('core/gui/Window')

local DialogueWindow = class(Window)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(GUI : GUI) Parent GUI.
-- @param(w : number) Width of the window.
-- @param(h : number) Height of the window.
-- @param(x : number) Pixel x of the window.
-- @param(y : number) Pixel y of the window.
function DialogueWindow:init(GUI, w, h, x, y)
  self:initProperties()
  w = w or ScreenManager.width - GUI:windowMargin()
  h = h or ScreenManager.height / 4
  x = x or (w - ScreenManager.width) / 2 + GUI:windowMargin()
  y = y or (ScreenManager.height - h) / 2 - GUI:windowMargin()
  Window.init(self, GUI, w, h, Vector(x, y))
end
-- Sets window's properties.
function DialogueWindow:initProperties()
  self.nameWidth = 80
  self.nameHeight = 24
end
-- Overrides Window:createContent.
-- Creates a simple text for dialogue.
function DialogueWindow:createContent(width, height)
  Window.createContent(self, width, height)
  local pos = Vector(-width / 2 + self:paddingX(), -height / 2 + self:paddingY())
  self.dialogue = Dialogue('', pos, width - self:paddingX() * 2, 'left', Fonts.gui_dialogue)
  self.content:add(self.dialogue)
  self.nameWindow = DescriptionWindow(self.GUI, self.nameWidth, self.nameHeight)
  self.nameWindow:setVisible(false)
end
-- Changes the window's size.
-- It recreates all contents.
function DialogueWindow:resize(...)
  DescriptionWindow.resize(self, ...)
  self.dialogue.position = Vector(-self.width / 2 + self:paddingX(), -self.height / 2 + self:paddingY())
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Called when player presses a mouse button.
function DialogueWindow:onClick(button, x, y)
  self:onConfirm()
end
-- Overrides Window:hide.
function DialogueWindow:hide(...)
  self.nameWindow:setVisible(false)
  Window.hide(self, ...)
end
-- Overrides Window:destroy.
function DialogueWindow:destroy(...)
  self.nameWindow:destroy()
  self.nameWindow:removeSelf()
  Window.destroy(self, ...)
end

---------------------------------------------------------------------------------------------------
-- Dialogue
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Shows a message and waits until player presses the confirm button.
-- @param(text : string) The message.
-- @param(speaker : table) The speaker's name and position of name box (optional).
function DialogueWindow:showDialogue(text, align, speaker)
  if speaker then
    local x = speaker.x and speaker.x * self.width / 2
    local y = speaker.y and speaker.y * self.height / 2
    self:setName(speaker.name, x, y)
  end
  self.dialogue:setAlign(align)
  self.dialogue:show()
  self.dialogue:rollText(text)
  self.GUI:waitForResult()
  self.result = nil
  Fiber:wait()
end

---------------------------------------------------------------------------------------------------
-- Speaker
---------------------------------------------------------------------------------------------------

-- Shows the name of the speaker.
-- @param(text : string) Nil or empty to hide window, any other string to show.
function DialogueWindow:setName(text, x, y)
  if text and text ~= '' then
    self.nameWindow:updateText(text)
    self.nameWindow:packText()
    local nameX = x and (self.position.x + x) or self.nameWindow.position.x
    local nameY = y and (self.position.y + y) or self.nameWindow.position.y
    self.nameWindow:setVisible(true)
    self.nameWindow:setXYZ(nameX, nameY, -5)
  else
    self.nameWindow:setVisible(false)
  end
end

return DialogueWindow
