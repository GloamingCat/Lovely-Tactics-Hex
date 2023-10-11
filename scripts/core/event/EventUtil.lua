
--[[===============================================================================================

Event Utilities
---------------------------------------------------------------------------------------------------
Functions that are loaded from the EventSheet.

Do not call require on this script directly. When overriding a utility function, override it on
EventSheet class instead.

=================================================================================================]]

-- Imports
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local DialogueWindow = require('core/gui/common/window/interactable/DialogueWindow')
local GUI = require('core/gui/GUI')
local Vector = require('core/math/Vector')

local EventSheet = class()

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Searches for the character with the given key.
-- @param(key : string) Character's key.
-- @param(optional : boolean) If true, does not throw error if not found.
-- @ret(Character) Character with given key, nil if optional and not found.
function EventSheet:findCharacter(key, optional)
  if key == 'self' then
    key = self.char.key
  end
  local char = FieldManager:search(key)
  assert(char or optional, 'Character not found: ' .. tostring(key))
  return char
end
-- Checks if the script's character (if any) collided with given character.
-- @param(key : string) Character's key.
-- @ret(boolean)
function EventSheet:collidedWith(key)
  return self.char and (self.char.collided == key or self.char.collider == key)
end
-- Checks the position of given character.
-- @param(key : string) Character's key.
-- @param(i : number | string) Other character's key or tile x position.
-- @param(j : number) Tile y position (optional if i is a string).
-- @param(h : number) Tile height (optional if i is a string).
-- @ret(boolean)
function EventSheet:checkTile(key, i, j, h)
  local char = FieldManager:search(key)
  if type(i) == 'string' then
    i, j, h = FieldManager:search(i):getTile():coordinates()
  end
  local i2, j2, h2 = char:getTile():coordinates()
  return i == i2 and j == j2 and h == h2
end

---------------------------------------------------------------------------------------------------
-- GUI
---------------------------------------------------------------------------------------------------

-- Creates an empty GUI for the sheet if not already created.
function EventSheet:createGUI()
  if not self.gui then
    self.gui = GUI()
    self.gui.name = "Event GUI from " .. tostring(self)
    self.gui.dialogues = {}
    self.gui.messages = {}
    GUIManager:showGUI(self.gui)
  end
end
-- Creates a message window with default size and position for given ID.
-- @param(id : number) Window ID.
--  1: Window at the top of the screen, full width;
--  2: Window at the width of the screen, full width;
--  3+: Window in the middle of the screen, 3/4 width.
-- @ret(DescriptionWindow)
function EventSheet:createDefaultMessageWindow(id)
  local x, y = 0, 0
  local w, h = ScreenManager.width, ScreenManager.height / 3
  if id == 2 then -- Top.
    y = ScreenManager.height / 3
  elseif id == 1 then -- Bottom.
    y = -ScreenManager.height / 3
  else -- Center.
    w = ScreenManager.width * 3 / 4
  end
  return DescriptionWindow(self.gui, w, h, Vector(x, y))
end
-- Opens a new message window and stores in the given ID.
-- @param(args.width : number) Width of the window (optional).
-- @param(args.height : number) Height of the window (optional).
-- @param(args.x : number) Pixel x of the window (optional).
-- @param(args.y : number) Pixel y of the window (optional).
-- @param(args.alignX : string) Horizontal alignment of text (optional).
-- @param(args.alignY : string) Vertical alignment of text (optional).
function EventSheet:openMessageWindow(args)
  self:createGUI()
  local msgs = self.gui.messages
  local window = msgs[args.id]
  if not window then
    window = self:createDefaultMessageWindow(args.id)
    msgs[args.id] = window
  end
  window.text:setAlign(args.alignX or 'center', args.alignY or 'center')
  window:resize(args.width, args.height)
  window:setXYZ(args.x, args.y)
  if window.closed then
    window:setVisible(false)
    window:show()
  end
end
-- Creates a dialogue window with default size and position for given ID.
-- @param(id : number) Window ID.
--  1: Window at the bottom of the screen, full width;
--  2: Window at the top of the screen, full width;
--  3+: Window in the middle of the screen, 3/4 width.
-- @ret(DialogueWindow)
function EventSheet:createDefaultDialogueWindow(id)
  local x, y = 0, 0
  local w, h = ScreenManager.width, ScreenManager.height / 3
  if id == 1 then -- Bottom.
    y = ScreenManager.height / 3
  elseif id == 2 then -- Top.
    y = -ScreenManager.height / 3
  else -- Center.
    w = ScreenManager.width * 3 / 4
  end
  return DialogueWindow(self.gui, w, h, x, y)
end
-- Opens a new dialogue window and stores in the given ID.
-- @param(args.width : number) Width of the window (optional).
-- @param(args.height : number) Height of the window (optional).
-- @param(args.x : number) Pixel x of the window (optional).
-- @param(args.y : number) Pixel y of the window (optional).
function EventSheet:openDialogueWindow(args)
  self:createGUI()
  local dialogues = self.gui.dialogues
  local window = dialogues[args.id]
  if not window then
    window = self:createDefaultDialogueWindow(args.id)
    dialogues[args.id] = window
  end
  window:resize(args.width, args.height)
  window:setXYZ(args.x, args.y)
  if window.closed then
    window:setVisible(false)
    window:show()
  end
  self.gui:setActiveWindow(window)
end

return EventSheet
