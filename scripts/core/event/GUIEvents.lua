
--[[===============================================================================================

GUI Events
---------------------------------------------------------------------------------------------------
Functions that are loaded from the EventSheet.

=================================================================================================]]

-- Imports
local ChoiceWindow = require('core/gui/common/window/interactable/ChoiceWindow')
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local FieldGUI = require('core/gui/menu/FieldGUI')
local NumberWindow = require('core/gui/common/window/interactable/NumberWindow')
local SaveGUI = require('core/gui/menu/SaveGUI')
local ShopGUI = require('core/gui/menu/ShopGUI')
local TextInputWindow = require('core/gui/common/window/interactable/TextInputWindow')
local Vector = require('core/math/Vector')

local EventSheet = {}

---------------------------------------------------------------------------------------------------
-- Menu
---------------------------------------------------------------------------------------------------

-- Opens the FieldGUI.
function EventSheet:openFieldMenu(args)
  GUIManager:showGUIForResult(FieldGUI(nil))
end
-- Opens the SaveGUI.
function EventSheet:openSaveMenu(args)
  GUIManager:showGUIForResult(SaveGUI(nil))
end
-- Opens the ShopGUI.
-- @param(args.items : table) Array of items.
-- @param(args.sell : boolean) Sell enabling.
function EventSheet:openShopMenu(args)
  if not args.keepHud then
    FieldManager.hud:hide()
  end
  GUIManager:showGUIForResult(ShopGUI(nil, args.items, args.sell))
  if not args.keepHud then
    FieldManager.hud:show()
  end
end

---------------------------------------------------------------------------------------------------
-- Title Window
---------------------------------------------------------------------------------------------------

-- Opens a basic window with the given text. By default, it's a single-line window.
-- @param(args.text : number) Text inside window.
-- @param(args.width : number) Width of the window (optional).
-- @param(args.height : number) Height of the window (optional).
-- @param(args.x : number) Pixel x of the window (optional).
-- @param(args.y : number) Pixel y of the window (optional).
function EventSheet:openTitleWindow(args)
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
  self.gui.titleWindow:updateText(args.text)
end
-- Closes and destroys title window.
function EventSheet:closeTitleWindow(args)
  assert(self.gui.titleWindow, 'Title windows is not open.')
  self.gui.titleWindow:hide()
  self.gui.titleWindow:destroy()
  self.gui.titleWindow:removeSelf()
end

---------------------------------------------------------------------------------------------------
-- Dialogue
---------------------------------------------------------------------------------------------------

-- General parameters:
-- @param(args.id : number) ID of the dialogue window.

-- Shows a dialogue in the given window.
-- @param(args.message : string) Dialogue text.
-- @param(args.name : string) Speaker name (optional).
-- @param(args.nameX : string) Speaker name X, from -1 to 1 (optional).
-- @param(args.nameY : string) Speaker name Y, from -1 to 1 (optional).
function EventSheet:showDialogue(args)
  self:openDialogueWindow(args)
  local window = self.gui.dialogues[args.id]
  self.gui:setActiveWindow(window)
  local speaker = args.name ~= '' and { name = args.name, 
    x = args.nameX, y = args.nameY }
  window:showDialogue(args.message, args.align, speaker)
end
-- Closes and deletes a dialogue window.
function EventSheet:closeDialogueWindow(args)
  if self.gui and self.gui.dialogues then
    local window = self.gui.dialogues[args.id]
    if window then
      window:hide()
      window:removeSelf()
      window:destroy()
      self.gui.dialogues[args.id] = nil
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Input
---------------------------------------------------------------------------------------------------

-- Opens a choice window and waits for player choice before closing and deleting.
-- @param(args.choices : table) Array with the name of each choice.
function EventSheet:openChoiceWindow(args)
  self:createGUI()
  local window = ChoiceWindow(self.gui, args)
  window:show()
  self.gui:setActiveWindow(window)
  local result = self.gui:waitForResult()
  window:hide()
  window:removeSelf()
  window:destroy()
  self.gui.activeWindow = nil
  self.vars.choiceInput = result
end
-- Opens a password window and waits for player choice before closing and deleting.
-- @param(args.length : number) Number of digits.
-- @param(args.width : number) Window width.
-- @param(args.pos : Vector) Window center's position.
-- @param(args.cancelValue : number) Index returned when player presses a cancel button.
function EventSheet:openNumberWindow(args)
  self:createGUI()
  local window = NumberWindow(self.gui, args)
  window:show()
  self.gui:setActiveWindow(window)
  local result = self.gui:waitForResult()
  window:hide()
  window:removeSelf()
  window:destroy()
  self.vars.numberInput = result
end
-- Opens a text window and waits for player choice before closing and deleting.
function EventSheet:openStringWindow(args)
  self:createGUI()
  local window = TextInputWindow(self.gui, args.emptyAllowed, args.cancelAllowed)
  window:show()
  self.gui:setActiveWindow(window)
  local result = self.gui:waitForResult()
  window:hide()
  window:removeSelf()
  window:destroy()
  self.vars.textInput = result ~= 0 and result
end

return EventSheet
