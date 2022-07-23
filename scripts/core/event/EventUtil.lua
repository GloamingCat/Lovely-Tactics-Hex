
--[[===============================================================================================

Event Utilities
---------------------------------------------------------------------------------------------------
Functions that are loaded from the EventSheet.

=================================================================================================]]

-- Imports
local DialogueWindow = require('core/gui/common/window/interactable/DialogueWindow')
local GUI = require('core/gui/GUI')

local EventSheet = {}

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

---------------------------------------------------------------------------------------------------
-- GUI
---------------------------------------------------------------------------------------------------

-- Creates an empty GUI for the sheet if not already created.
function EventSheet:createGUI()
  if not self.gui then
    self.gui = GUI()
    self.gui.name = "Event GUI"
    self.gui.dialogues = {}
    GUIManager:showGUI(self.gui)
  end
end
-- Creates a dialogue window with default size and position for given ID.
-- @param(id : number) Window ID.
--  1: Speech in the bottom of the screen, full width;
--  2: Speech in the top of the screen, full width;
--  3+: Speech in the middle of the screen, 3/4 width.
-- @ret(DialogueWindow)
function EventSheet:createDefaultDialogueWindow(id)
  local x, y = 0, 0
  local w, h = ScreenManager.width, ScreenManager.height / 3
  if id == 1 then -- Bottom speech.
    y = ScreenManager.height / 3
  elseif id == 2 then -- Top speech.
    y = -ScreenManager.height / 3
  else -- Center message.
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
  window:show()
  self.gui:setActiveWindow(window)
end

return EventSheet
