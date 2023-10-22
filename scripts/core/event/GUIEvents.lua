
-- ================================================================================================

--- GUI-related functions that are loaded from the EventSheet.
---------------------------------------------------------------------------------------------------
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
-- Tables
-- ------------------------------------------------------------------------------------------------

--- Arguments for field transition.
-- @table WindowArguments
-- @tfield number id ID of the window.
-- @tfield number width Width of the window (optional).
-- @tfield number height Height of the window (optional).
-- @tfield number x Pixel x of the window (optional).
-- @tfield number y Pixel y of the window (optional).
-- @tfield string alignX Horizontal alignment of text (optional).
-- @tfield string alignY Vertical alignment of text (optional).

--- Arguments for opening a GUI.
-- @table MenuArguments
-- @tfield table items Array of items/battlers (with their IDs or keys), for `openShopMenu` and `openRecruitMenu`.
-- @tfield boolean sell Enables sell/dismiss option, for `openShopMenu` and `openRecruitMenu`.

--- Arguments for dialogue commands. Extends `WindowArguments`.
-- @table DialogueArguments
-- @tfield string message Dialogue text.
-- @tfield string name Speaker name (optional).
-- @tfield number nameX Speaker window X in relation to the main window, from -1 to 1 (optional).
-- @tfield number nameY Speaker window Y in relation to the main window, from -1 to 1 (optional).

--- Arguments for title/message commands. Extends `WindowArguments`.
-- @table MessageArguments
-- @tfield string text Text inside window.
-- @tfield boolean wait Flag to wait for player input.

--- Arguments for choice/number/input commands. Extends `WindowArguments`.
-- @table InputCommands
-- @tfield table choices Array with the name of each choice, for `openChoiceWindow`.
-- @tfield number length Number of digits for number input, for `openNumberWindow`
-- @tfield boolean emptyAllowed Whether it is allowed to leave the text empty, for `openStringWindow`
-- @tfield unknown cancelValue Value/index returned when player presses a cancel button.

-- ------------------------------------------------------------------------------------------------
-- Menu
-- ------------------------------------------------------------------------------------------------

--- Opens the FieldGUI.
-- @tparam MenuArguments args
function GUIEvents:openFieldMenu(args)
  GUIManager:showGUIForResult(FieldGUI(nil))
end
--- Opens the SaveGUI.
-- @tparam MenuArguments args
function GUIEvents:openSaveMenu(args)
  GUIManager:showGUIForResult(SaveGUI(nil))
end
--- Opens the ShopGUI.
-- @tparam MenuArguments args
function GUIEvents:openShopMenu(args)
  self.vars.hudOpen = FieldManager.hud.visible
  FieldManager.hud:hide()
  GUIManager:showGUIForResult(ShopGUI(nil, args.items, args.sell))
  if self.vars.hudOpen then
    FieldManager.hud:show()
  end
end
--- Opens the RecruitGUI.
-- @tparam MenuArguments args
function GUIEvents:openRecruitMenu(args)
  self.vars.hudOpen = FieldManager.hud.visible
  FieldManager.hud:hide()
  GUIManager:showGUIForResult(RecruitGUI(nil, args.items, args.sell))
  if self.vars.hudOpen then
    FieldManager.hud:show()
  end
end

-- ------------------------------------------------------------------------------------------------
-- Title Window
-- ------------------------------------------------------------------------------------------------

--- Opens a basic window with the given text. By default, it's a single-line window.
-- @tparam WindowArguments args
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
-- @tparam WindowArguments args
function GUIEvents:closeTitleWindow(args)
  assert(self.gui.titleWindow, 'Title windows is not open.')
  self.gui.titleWindow:hide()
  self.gui.titleWindow:destroy()
  self.gui.titleWindow:removeSelf()
end

-- ------------------------------------------------------------------------------------------------
-- Message
-- ------------------------------------------------------------------------------------------------

--- Shows a message in the given window.
-- @tparam MessageArguments args
function GUIEvents:showMessage(args)
  self:openMessageWindow(args)
  local window = self.gui.messages[args.id]
  window:updateText(args.text)
  if args.wait then
    self.gui:setActiveWindow(window)
    self.gui:waitForResult()
  end
end
--- Closes and deletes a message window.
-- @tparam WindowArguments args
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
-- Dialogue
-- ------------------------------------------------------------------------------------------------

--- Shows a dialogue in the given window.
-- @tparam DialogueArguments args
function GUIEvents:showDialogue(args)
  self:openDialogueWindow(args)
  local window = self.gui.dialogues[args.id]
  self.gui:setActiveWindow(window)
  local speaker = args.name ~= '' and { name = args.name, 
    x = args.nameX, y = args.nameY }
  window:showDialogue(args.message, args.align, speaker)
end
--- Closes and deletes a dialogue window.
-- @tparam WindowArguments args
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
-- Input
-- ------------------------------------------------------------------------------------------------

--- Opens a choice window and waits for player choice before closing and deleting.
-- @tparam InputArguments args
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
-- @tparam InputArguments args
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
-- @tparam InputArguments args
function GUIEvents:openStringWindow(args)
  self:createGUI()
  local window = TextInputWindow(self.gui, args.emptyAllowed, args.cancelValue ~= nil)
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
