
--[[===============================================================================================

EventSheet
---------------------------------------------------------------------------------------------------
A fiber that processes a list of sequential commands.

=================================================================================================]]

-- Imports
local Fiber = require('core/fiber/Fiber')

local EventSheet = class(Fiber)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(root : FiberList) The FiberList that originated this fiber.
-- @param(script : table) Table with name (or func) and tags. 
-- @param(char : Character) Character associated with this fiber (optional).
function EventSheet:init(root, script, char)
  if script.func then
    self.commands = script.func
  else
    local func = require('custom/' .. script.name)
    assert(func, "Could not load event sheet file: " .. tostring(script.name))
    self.commands = func
  end
  self.data = script
  self.vars = script and script.vars
  self.block = script and script.block
  self.args = Database.loadTags(script.tags)
  self.char = char
  self.player = FieldManager.player
  Fiber.init(self, root, nil)
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Runs the script commands.
function EventSheet:execute()
  self:setUp()
  self:commands()
  self:clear()
end
-- Sets any variable needed to indicate that this script is running.
function EventSheet:setUp()
  if self.data then
    self.data.running = true
  end
  if self.block then
    self.player.waitList:add(self)
  end
end
-- Resets any variable that indicates that this script is running.
function EventSheet:clear()
  if self.gui then
    GUIManager:returnGUI()
    self.gui = nil
  end
  if self.block then
    self.player.waitList:removeElement(self)
  end
  if self.data then
    self.data.running = false
  end
end
-- Overrides Fiber:finish.
function EventSheet:finish()
  Fiber.finish(self)
  self:clear()
end

---------------------------------------------------------------------------------------------------
-- Commands
---------------------------------------------------------------------------------------------------

-- Creates a new fiber in from the same root that executes given script.
-- @param(script : table) Table with name (or func) and tags. 
-- @ret(Fiber) Newly created Fiber.
function EventSheet:forkFromScript(script, ...)
  return self.root:forkFromScript(script, self.char, ...)
end
-- Searches for the character with the given key.
-- @param(key : string) Character's key.
-- @param(optional : boolean) If true, does not throw error if not found.
-- @ret(Character) Character with given key, nil if optional and not found.
function EventSheet:findCharacter(key, optional)
  if key == 'self' then
    return self.char
  end
  local char = FieldManager:search(key)
  assert(char or optional, 'Character not found: ' .. tostring(key))
  return char
end
-- Load other commands.
local files = {'General', 'GUI', 'Character', 'Screen', 'Sound', 'Party'}
for i = 1, #files do
  local commands = require('core/event/' .. files[i] .. 'Events')
  for k, v in pairs(commands) do
    EventSheet[k] = v
  end
end

return EventSheet
