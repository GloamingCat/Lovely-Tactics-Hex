
-- ================================================================================================

--- Utility functions that are loaded from the EventSheet.
-- This is intended to be a private module. Do not call require on this script directly from a
-- plugin.
-- When overriding a utility function, override it on EventSheet class instead.
---------------------------------------------------------------------------------------------------
-- @module EventUtil

-- ================================================================================================

-- Imports
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local DialogueWindow = require('core/gui/common/window/interactable/DialogueWindow')
local Menu = require('core/gui/Menu')
local Vector = require('core/math/Vector')

-- Class table.
local EventUtil = class()

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Searches for the character with the given key.
-- @tparam string key Character's key.
-- @tparam[opt] boolean optional Flag to not throw error if not found.
-- @treturn Character Character with given key, nil if optional and not found.
function EventUtil:findCharacter(key, optional)
  if key == 'self' then
    key = self.char.key
  end
  local char = FieldManager:search(key)
  assert(char or optional, 'Character not found: ' .. tostring(key))
  return char
end
--- Checks if the script's character (if any) collided with given character.
-- @tparam string key Character's key.
-- @treturn boolean
function EventUtil:collidedWith(key)
  return self.char and (self.char.collided == key or self.char.collider == key)
end
--- Checks the position of given character.
-- @tparam string key Character's key.
-- @tparam number|string i Other character's key or tile x position.
--  If it's a string, ignores parameters `j` and `h`.
-- @tparam[opt] number j Tile y position.
-- @tparam[opt] number h Tile height.
-- @treturn boolean
function EventUtil:checkTile(key, i, j, h)
  local char = FieldManager:search(key)
  if type(i) == 'string' then
    i, j, h = FieldManager:search(i):getTile():coordinates()
  end
  local i2, j2, h2 = char:getTile():coordinates()
  return i == i2 and j == j2 and h == h2
end

-- ------------------------------------------------------------------------------------------------
-- Menu
-- ------------------------------------------------------------------------------------------------

--- Creates an empty Menu for the sheet if not already created.
function EventUtil:createMenu()
  if not self.menu then
    self.menu = Menu()
    self.menu.name = "Event Menu from " .. tostring(self)
    self.menu.dialogues = {}
    self.menu.messages = {}
    MenuManager:showMenu(self.menu)
  end
end
--- Creates a message window with default size and position for given ID.
-- @tparam number id Window ID.  
--  For 1: top of the screen, full width;  
--  For 2: bottom of the screen, full width;  
--  For 3+: middle of the screen, 3/4 width.  
-- @treturn DescriptionWindow
function EventUtil:createDefaultMessageWindow(id)
  local x, y = 0, 0
  local w, h = ScreenManager.width, ScreenManager.height / 3
  if id == 2 then -- Top.
    y = ScreenManager.height / 3
  elseif id == 1 then -- Bottom.
    y = -ScreenManager.height / 3
  else -- Center.
    w = ScreenManager.width * 3 / 4
  end
  return DescriptionWindow(self.menu, w, h, Vector(x, y))
end
--- Opens a new message window and stores in the given ID.
-- @tparam WindowArguments args
function EventUtil:openMessageWindow(args)
  self:createMenu()
  local msgs = self.menu.messages
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
--- Creates a dialogue window with default size and position for given ID.
-- @tparam number id Window ID.  
--  For 1: bottom of the screen, full width;  
--  For 2: top of the screen, full width;  
--  For 3+: middle of the screen, 3/4 width.  
-- @treturn DialogueWindow
function EventUtil:createDefaultDialogueWindow(id)
  local x, y = 0, 0
  local w, h = ScreenManager.width, ScreenManager.height / 3
  if id == 1 then -- Bottom.
    y = ScreenManager.height / 3
  elseif id == 2 then -- Top.
    y = -ScreenManager.height / 3
  else -- Center.
    w = ScreenManager.width * 3 / 4
  end
  return DialogueWindow(self.menu, w, h, x, y)
end
--- Opens a new dialogue window and stores in the given ID.
-- @tparam WindowArguments args
function EventUtil:openDialogueWindow(args)
  self:createMenu()
  local dialogues = self.menu.dialogues
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
  self.menu:setActiveWindow(window)
end

return EventUtil
