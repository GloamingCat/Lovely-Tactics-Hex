
-- ================================================================================================

--- GUI-related functions that are loaded from the EventSheet.
-- ------------------------------------------------------------------------------------------------
-- @module GUIEvents

-- ================================================================================================

-- Imports
local ChoiceWindow = require('core/gui/common/window/interactable/ChoiceWindow')
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local FieldGUI = require('core/gui/menu/FieldGUI')
local NumberWindow = require('core/gui/common/window/interactable/NumberWindow')
local SaveGUI = require('core/gui/menu/SaveGUI')
local ShopGUI = require('core/gui/menu/ShopGUI')
local RecruitGUI = require('core/gui/menu/RecruitGUI')
local TextInputWindow = require('core/gui/common/window/interactable/TextInputWindow')
local Vector = require('core/math/Vector')

local GUIEvents = {}

-- ------------------------------------------------------------------------------------------------
-- Menu
-- ------------------------------------------------------------------------------------------------

--- Opens the FieldGUI.
-- @tparam table args
function GUIEvents:openFieldMenu(args)
  GUIManager:showGUIForResult(FieldGUI(nil))
end
--- Opens the SaveGUI.
-- @tparam table args
function GUIEvents:openSaveMenu(args)
  GUIManager:showGUIForResult(SaveGUI(nil))
end
--- Opens the ShopGUI.
-- @tparam table args
--  args.items (table): Array of items.
--  args.sell (boolean): Sell enabling.
function GUIEvents:openShopMenu(args)
  self.vars.hudOpen = FieldManager.hud.visible
  FieldManager.hud:hide()
  GUIManager:showGUIForResult(ShopGUI(nil, args.items, args.sell))
  if self.vars.hudOpen then
    FieldManager.hud:show()
  end
end
--- Opens the ShopGUI.
-- @tparam table args
--  args.items (table): Array of items.
--  args.sell (boolean): Sell enabling.
function GUIEvents:openRecruitMenu(args)
  self.vars.hudOpen = FieldManager.hud.visible
  FieldManager.hud:hide()
  GUIManager:showGUIForResult(RecruitGUI(nil, args.chars, args.dismiss))
  if self.vars.hudOpen then
    FieldManager.hud:show()
  end
end

-- ------------------------------------------------------------------------------------------------
-- Title Window
-- ------------------------------------------------------------------------------------------------

--- Opens a basic window with the given text. By default, it's a single-line window.
-- @tparam table args
--  args.text (number): Text inside window.
--  args.width (number): Width of the window (optional).
--  args.height (number): Height of the window (optional).
--  args.x (number): Pixel x of the window (optional).
--  args.y (number): Pixel y of the window (optional).
function GUIEvents:openTitleWindow(args)
  self:createGUI()
  local w = args.width or ScreenManager.width / 4
  local h = args.height or 24
  local x = args.x or 0
  local y = args.y or -ScreenManager.height / 2 + h / 2 + 8
  if self.gui.titleWindow then
    self.gui.titleWindow:resize(w, h)
    self.gui.titleWindow:setXYZ(x, y, 10)
  else
    self.gui.titleWindow = DescriptionWindow(self.gui, w, h, Vector(x, y, 10))
    self.gui.titleWindow.text:setMaxHeight(h - self.gui.titleWindow:paddingY() * 2)
    self.gui.titleWindow.text:setAlign('center', 'center')
  end
  self.gui.titleWindow:show()
  if args.term then
    self.gui.titleWindow:updateTerm(args.term, args.fallback)
  else
    self.gui.titleWindow:updateText(args.text)
  end
end
--- Closes and destroys title window.
-- @tparam table args
function GUIEvents:closeTitleWindow(args)
  assert(self.gui.titleWindow, 'Title windows is not open.')
  self.gui.titleWindow:hide()
  self.gui.titleWindow:destroy()
  self.gui.titleWindow:removeSelf()
end

-- ------------------------------------------------------------------------------------------------
-- Dialogue
-- ------------------------------------------------------------------------------------------------

-- General parameters:


--- Shows a dialogue in the given window.
-- @tparam table args
--  args.id (number): ID of the dialogue window.
--  args.message (string): Dialogue text.
--  args.name (string): Speaker name (optional).
--  args.nameX (string): Speaker name X, from -1 to 1 (optional).
--  args.nameY (string): Speaker name Y, from -1 to 1 (optional).
function GUIEvents:showDialogue(args)
  self:openDialogueWindow(args)
  local window = self.gui.dialogues[args.id]
  self.gui:setActiveWindow(window)
  local speaker = args.name ~= '' and { name = args.name, 
    x = args.nameX, y = args.nameY }
  window:showDialogue(args.message, args.align, speaker)
end
--- Closes and deletes a dialogue window.
-- @tparam table args
--  args.id (number): ID of the dialogue window.
function GUIEvents:closeDialogueWindow(args)
  if self.gui and self.gui.dialogues then
    local window = self.gui.dialogues[args.id]
    if window then
      window:hide()
      window:removeSelf()
      window:destroy()
      self.gui.dialogues[args.id] = nil
      if self.gui.activeWindow == window then
        self.gui:setActiveWindow(nil)
      end
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Message
-- ------------------------------------------------------------------------------------------------

--- Shows a message in the given window.
-- @tparam table args
--  args.id (number): ID of the message window.
--  args.message (string): Message text.
--  args.wait (boolean): True to wait for player input.
function GUIEvents:showMessage(args)
  self:openMessageWindow(args)
  local window = self.gui.messages[args.id]
  window:updateText(args.message)
  if args.wait then
    self.gui:setActiveWindow(window)
    self.gui:waitForResult()
  end
end
--- Closes and deletes a message window.
-- @tparam table args
--  args.id (number): ID of the message window.
function GUIEvents:closeMessageWindow(args)
  if self.gui and self.gui.messages then
    local window = self.gui.messages[args.id]
    if window then
      window:hide()
      window:removeSelf()
      window:destroy()
      self.gui.messages[args.id] = nil
      if self.gui.activeWindow == window then
        self.gui:setActiveWindow(nil)
      end
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Input
-- ------------------------------------------------------------------------------------------------

--- Opens a choice window and waits for player choice before closing and deleting.
-- @tparam table args
--  args.choices (table): Array with the name of each choice.
function GUIEvents:openChoiceWindow(args)
  self:createGUI()
  local window = ChoiceWindow(self.gui, args)
  window:setXYZ(args.x, args.y, -5)
  window:show()
  self.gui:setActiveWindow(window)
  local result = self.gui:waitForResult()
  window:hide()
  window:removeSelf()
  window:destroy()
  self.gui.activeWindow = nil
  self.vars.choiceInput = result
  if self.char then
    self.char.vars.choiceInput = result
  end
end
--- Opens a password window and waits for player choice before closing and deleting.
-- @tparam table args
--  args.length (number): Number of digits.
--  args.width (number): Window width.
--  args.pos Vector Window center's position.
--  args.cancelValue (number): Index returned when player presses a cancel button.
function GUIEvents:openNumberWindow(args)
  self:createGUI()
  local window = NumberWindow(self.gui, args)
  window:show()
  self.gui:setActiveWindow(window)
  local result = self.gui:waitForResult()
  window:hide()
  window:removeSelf()
  window:destroy()
  self.vars.numberInput = result
  if self.char then
    self.char.vars.numberInput = result
  end
end
--- Opens a text window and waits for player choice before closing and deleting.
-- @tparam table args
function GUIEvents:openStringWindow(args)
  self:createGUI()
  local window = TextInputWindow(self.gui, args.emptyAllowed, args.cancelAllowed)
  window:show()
  self.gui:setActiveWindow(window)
  local result = self.gui:waitForResult()
  window:hide()
  window:removeSelf()
  window:destroy()
  self.vars.textInput = result ~= 0 and result
  if self.char then
    self.char.vars.textInput = result
  end
end

return GUIEvents
