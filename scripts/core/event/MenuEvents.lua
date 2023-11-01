
-- ================================================================================================

--- Menu-related functions that are loaded from the EventSheet.
---------------------------------------------------------------------------------------------------
-- @module MenuEvents

-- ================================================================================================

-- Imports
local ChoiceWindow = require('core/gui/common/window/interactable/ChoiceWindow')
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local FieldMenu = require('core/gui/menu/FieldMenu')
local NumberWindow = require('core/gui/common/window/interactable/NumberWindow')
local SaveMenu = require('core/gui/menu/SaveMenu')
local ShopMenu = require('core/gui/menu/ShopMenu')
local RecruitMenu = require('core/gui/menu/RecruitMenu')
local TextInputWindow = require('core/gui/common/window/interactable/TextInputWindow')
local Vector = require('core/math/Vector')

local MenuEvents = {}

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

--- Arguments for opening a Menu.
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

--- Opens the FieldMenu.
-- @tparam MenuArguments args
function MenuEvents:openFieldMenu(args)
  MenuManager:showMenuForResult(FieldMenu(nil))
end
--- Opens the SaveMenu.
-- @tparam MenuArguments args
function MenuEvents:openSaveMenu(args)
  MenuManager:showMenuForResult(SaveMenu(nil))
end
--- Opens the ShopMenu.
-- @tparam MenuArguments args
function MenuEvents:openShopMenu(args)
  self.vars.hudOpen = FieldManager.hud.visible
  FieldManager.hud:hide()
  MenuManager:showMenuForResult(ShopMenu(nil, args.items, args.sell))
  if self.vars.hudOpen then
    FieldManager.hud:show()
  end
end
--- Opens the RecruitMenu.
-- @tparam MenuArguments args
function MenuEvents:openRecruitMenu(args)
  self.vars.hudOpen = FieldManager.hud.visible
  FieldManager.hud:hide()
  MenuManager:showMenuForResult(RecruitMenu(nil, args.items, args.sell))
  if self.vars.hudOpen then
    FieldManager.hud:show()
  end
end

-- ------------------------------------------------------------------------------------------------
-- Title Window
-- ------------------------------------------------------------------------------------------------

--- Opens a basic window with the given text. By default, it's a single-line window.
-- @tparam WindowArguments args
function MenuEvents:openTitleWindow(args)
  self:createMenu()
  local w = args.width or ScreenManager.width / 4
  local h = args.height or 24
  local x = args.x or 0
  local y = args.y or -ScreenManager.height / 2 + h / 2 + 8
  if self.menu.titleWindow then
    self.menu.titleWindow:resize(w, h)
    self.menu.titleWindow:setXYZ(x, y, 10)
  else
    self.menu.titleWindow = DescriptionWindow(self.menu, w, h, Vector(x, y, 10))
    self.menu.titleWindow.text:setMaxHeight(h - self.menu.titleWindow:paddingY() * 2)
    self.menu.titleWindow.text:setAlign('center', 'center')
  end
  self.menu.titleWindow:show()
  if args.term then
    self.menu.titleWindow:updateTerm(args.term, args.fallback)
  else
    self.menu.titleWindow:updateText(args.text)
  end
end
--- Closes and destroys title window.
-- @tparam WindowArguments args
function MenuEvents:closeTitleWindow(args)
  assert(self.menu.titleWindow, 'Title windows is not open.')
  self.menu.titleWindow:hide()
  self.menu.titleWindow:destroy()
  self.menu.titleWindow:removeSelf()
end

-- ------------------------------------------------------------------------------------------------
-- Message
-- ------------------------------------------------------------------------------------------------

--- Shows a message in the given window.
-- @tparam MessageArguments args
function MenuEvents:showMessage(args)
  self:openMessageWindow(args)
  local window = self.menu.messages[args.id]
  window:updateText(args.text)
  if args.wait then
    self.menu:setActiveWindow(window)
    self.menu:waitForResult()
  end
end
--- Closes and deletes a message window.
-- @tparam WindowArguments args
function MenuEvents:closeMessageWindow(args)
  if self.menu and self.menu.messages then
    local window = self.menu.messages[args.id]
    if window then
      window:hide()
      window:removeSelf()
      window:destroy()
      self.menu.messages[args.id] = nil
      if self.menu.activeWindow == window then
        self.menu:setActiveWindow(nil)
      end
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Dialogue
-- ------------------------------------------------------------------------------------------------

--- Shows a dialogue in the given window.
-- @tparam DialogueArguments args
function MenuEvents:showDialogue(args)
  self:openDialogueWindow(args)
  local window = self.menu.dialogues[args.id]
  self.menu:setActiveWindow(window)
  local speaker = args.name ~= '' and { name = args.name, 
    x = args.nameX, y = args.nameY }
  window:showDialogue(args.message, args.align, speaker)
end
--- Closes and deletes a dialogue window.
-- @tparam WindowArguments args
function MenuEvents:closeDialogueWindow(args)
  if self.menu and self.menu.dialogues then
    local window = self.menu.dialogues[args.id]
    if window then
      window:hide()
      window:removeSelf()
      window:destroy()
      self.menu.dialogues[args.id] = nil
      if self.menu.activeWindow == window then
        self.menu:setActiveWindow(nil)
      end
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Input
-- ------------------------------------------------------------------------------------------------

--- Opens a choice window and waits for player choice before closing and deleting.
-- @tparam InputArguments args
function MenuEvents:openChoiceWindow(args)
  self:createMenu()
  local window = ChoiceWindow(self.menu, args)
  window:setXYZ(args.x, args.y, -5)
  window:show()
  self.menu:setActiveWindow(window)
  local result = self.menu:waitForResult()
  window:hide()
  window:removeSelf()
  window:destroy()
  self.menu.activeWindow = nil
  self.vars.choiceInput = result
  if self.char then
    self.char.vars.choiceInput = result
  end
end
--- Opens a password window and waits for player choice before closing and deleting.
-- @tparam InputArguments args
function MenuEvents:openNumberWindow(args)
  self:createMenu()
  local window = NumberWindow(self.menu, args)
  window:show()
  self.menu:setActiveWindow(window)
  local result = self.menu:waitForResult()
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
function MenuEvents:openStringWindow(args)
  self:createMenu()
  local window = TextInputWindow(self.menu, args.emptyAllowed, args.cancelValue ~= nil)
  window:show()
  self.menu:setActiveWindow(window)
  local result = self.menu:waitForResult()
  window:hide()
  window:removeSelf()
  window:destroy()
  self.vars.textInput = result ~= 0 and result
  if self.char then
    self.char.vars.textInput = result
  end
end

return MenuEvents
