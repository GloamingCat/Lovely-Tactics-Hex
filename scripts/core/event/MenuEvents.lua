
-- ================================================================================================

--- Menu-related functions that are loaded from the EventSheet.
---------------------------------------------------------------------------------------------------
-- @module MenuEvents

-- ================================================================================================

-- Imports
local ChoiceWindow = require('core/gui/common/window/interactable/ChoiceWindow')
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local NumberWindow = require('core/gui/common/window/interactable/NumberWindow')
local TextInputWindow = require('core/gui/common/window/interactable/TextInputWindow')
local Vector = require('core/math/Vector')

local MenuEvents = {}

-- ------------------------------------------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------------------------------------------

--- Arguments for field transition.
-- @table WindowArguments
-- @tfield number id ID of the window.
-- @tfield[opt] number width Width of the window.
-- @tfield[opt] number height Height of the window.
-- @tfield[opt] number x Pixel x of the window.
-- @tfield[opt] number y Pixel y of the window.
-- @tfield[opt] string alignX Horizontal alignment of text.
-- @tfield[opt] string alignY Vertical alignment of text.

--- Arguments for opening a Menu.
-- @table MenuArguments
-- @tfield EventUtil.MenuType Which menu will be opened.
-- @tfield table items Array of items/battlers (with their IDs or keys), for `openShopMenu` and `openRecruitMenu`.
-- @tfield boolean sell Enables sell/dismiss option, for `openShopMenu` and `openRecruitMenu`.

--- Arguments for dialogue commands.
-- @table DialogueArguments
-- @extend WindowArguments
-- @tfield string message Dialogue text.
-- @tfield boolean wait Flag to wait for player input.
-- @tfield[opt] string name Speaker name.
-- @tfield[opt] number nameX Speaker window X in relation to the main window, from -1 to 1.
-- @tfield[opt] number nameY Speaker window Y in relation to the main window, from -1 to 1.

--- Arguments for title/message commands.
-- @table MessageArguments
-- @extend WindowArguments
-- @tfield string text Text inside window.
-- @tfield boolean wait Flag to wait for player input.

--- Arguments for choice/number/input commands.
-- @table InputCommands
-- @extend WindowArguments
-- @tfield table choices Array with the name of each choice, for `openChoiceWindow`.
-- @tfield number length Number of digits for number input, for `openNumberWindow`.
-- @tfield boolean emptyAllowed Whether it is allowed to leave the text empty, for `openStringWindow`
-- @tfield unknown cancelValue Value/index returned when player presses a cancel button.

-- ------------------------------------------------------------------------------------------------
-- Menu
-- ------------------------------------------------------------------------------------------------

--- Opens a menu.
-- @coroutine
-- @tparam MenuArguments args Argument table.
function MenuEvents:openFieldMenu(args)
  self:openMenu(args.menu)
end
--- Opens the Shop Menu.
-- @coroutine
-- @tparam MenuArguments args Argument table.
function MenuEvents:openShopMenu(args)
  self:openMenu(self.MenuType.shop, args.items, args.sell)
end
--- Opens the Recruit Menu.
-- @coroutine
-- @tparam MenuArguments args Argument table.
function MenuEvents:openRecruitMenu(args)
  self:openMenu(self.MenuType.recruit, args.items, args.sell)
end
--- Changes the visibility of the field's HUD.
-- @tparam table args Table with the boolean field `visible`.
function MenuEvents:setHudVisibility(args)
  if args.visible then
    FieldManager.hud:show()
  else
    FieldManager.hud:hide()
  end
end

-- ------------------------------------------------------------------------------------------------
-- Title Window
-- ------------------------------------------------------------------------------------------------

--- Opens a basic window with the given text. By default, it's a single-line window.
-- @tparam MessageArguments args Argument table.
function MenuEvents:openTitleWindow(args)
  self:createMenu()
  local w = args.width and args.width > 0
  local h = args.height and args.height > 0
  w = w and args.width or ScreenManager.width / 4
  h = h and args.height or 24
  local x = args.x or 0
  local y = (args.y or 0) + -ScreenManager.height / 2 + h / 2 + 8
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
-- @tparam WindowArguments args Argument table.
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
-- @coroutine
-- @tparam MessageArguments args Argument table.
function MenuEvents:openMessageWindow(args)
  self:createMessageWindow(args)
  local window = self.menu.messages[args.id]
  window:updateText(args.text)
  if args.wait then
    self.menu:setActiveWindow(window)
    self.menu:waitForResult()
  end
end
--- Closes and deletes a message window.
-- @coroutine
-- @tparam WindowArguments args Argument table.
function MenuEvents:closeMessageWindow(args)
  if self.menu and self.menu.messages then
    local window = self.menu.messages[args.id]
    if window then
      local fiber = self:fork(function()
        window:hide()
        window:removeSelf()
        window:destroy()
        self.menu.messages[args.id] = nil
        if self.menu.activeWindow == window then
          self.menu:setActiveWindow(nil)
        end
      end)
      if args.wait then
        fiber:waitForEnd()
      end
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Dialogue
-- ------------------------------------------------------------------------------------------------

--- Shows a dialogue in the given window.
-- @coroutine
-- @tparam DialogueArguments args Argument table.
function MenuEvents:openDialogueWindow(args)
  self:createDialogueWindow(args)
  local window = self.menu.dialogues[args.id]
  window.result = nil
  self.menu:setActiveWindow(window)
  local speaker = args.name ~= '' and { name = args.name, 
    x = args.nameX, y = args.nameY }
  if args.wait then
    window:showDialogue(args.message, args.align, speaker)
    self.menu:waitForResult()
    window.result = nil
    self:wait()
  else
    self:forkMethod(window, 'showDialogue', args.message, args.align, speaker)
  end
end
--- Closes and deletes a dialogue window.
-- @coroutine
-- @tparam WindowArguments args Argument table.
function MenuEvents:closeDialogueWindow(args)
  if self.menu and self.menu.dialogues then
    local window = self.menu.dialogues[args.id]
    if window then
      local fiber = self:fork(function()
        window:hide()
        window:removeSelf()
        window:destroy()
        self.menu.dialogues[args.id] = nil
        if self.menu.activeWindow == window then
          self.menu:setActiveWindow(nil)
        end
      end)
      if args.wait then
        fiber:waitForEnd()
      end
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Input
-- ------------------------------------------------------------------------------------------------

--- Opens a choice window and waits for player choice before closing and deleting.
-- @coroutine
-- @tparam InputArguments args Argument table.
function MenuEvents:openChoiceWindow(args)
  self:createMenu()
  local w = args.width and args.width > 0
  local window = ChoiceWindow(self.menu, args.choices, args.cancel,
    args.pos, w and args.width, args.align)
  window:setXYZ(args.x, args.y, -5)
  window:show()
  self.menu:setActiveWindow(window)
  local result = self.menu:waitForResult()
  window:hide()
  window:removeSelf()
  window:destroy()
  self.menu.activeWindow = nil
  local var = args.variable or 'choiceInput'
  self.vars[var] = result
  if self.char then
    self.char.vars[var] = result
  end
end
--- Opens a password window and waits for player choice before closing and deleting.
-- @coroutine
-- @tparam InputArguments args Argument table.
function MenuEvents:openNumberWindow(args)
  self:createMenu()
  local w = args.width and args.width > 0
  local window = NumberWindow(self.menu, args.length, args.cancel,
    args.pos, w and args.width, args.align)
  window:setXYZ(args.x, args.y, -5)
  window:show()
  self.menu:setActiveWindow(window)
  local result = self.menu:waitForResult()
  window:hide()
  window:removeSelf()
  window:destroy()
  self.menu.activeWindow = nil
  local var = args.variable or 'numberInput'
  self.vars[var] = result
  if self.char then
    self.char.vars[var] = result
  end
end
--- Opens a text window and waits for player choice before closing and deleting.
-- @coroutine
-- @tparam InputArguments args Argument table.
function MenuEvents:openStringWindow(args)
  self:createMenu()
  local w = args.width and args.width > 0
  local window = TextInputWindow(self.menu, args.min, args.max, 
    args.cancelValue ~= nil, w and args.width)
  window:setXYZ(args.x, args.y, -5)
  window:show()
  self.menu:setActiveWindow(window)
  local result = self.menu:waitForResult()
  window:hide()
  window:removeSelf()
  window:destroy()
  self.menu.activeWindow = nil
  local var = args.variable or 'textInput'
  self.vars[var] = result ~= 0 and result
  if self.char then
    self.char.vars[var] = result ~= 0 and result
  end
end

return MenuEvents
