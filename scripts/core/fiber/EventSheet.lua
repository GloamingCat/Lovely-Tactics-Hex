
--[[===============================================================================================

EventSheet
---------------------------------------------------------------------------------------------------
A fiber that processes a list of sequential commands.

=================================================================================================]]

-- Imports
local EventUtil = require('core/event/EventUtil')
local Fiber = require('core/fiber/Fiber')

local EventSheet = class(Fiber, EventUtil)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(root : FiberList) The FiberList that originated this fiber.
-- @param(script : table) Table with name (or func) and tags. 
-- @param(char : Character) Character associated with this fiber (optional).
function EventSheet:init(root, data, char)
  if data.func then
    self.commands = data.func
  else
    local func = require('custom/' .. data.name)
    assert(func, "Could not load event sheet file: " .. tostring(data.name))
    self.commands = func
  end
  self.data = data
  self.vars = data and data.vars
  self.args = Database.loadTags(data.tags)
  self.char = char
  if self.data then
    self.data.runningIndex = 0
  end
  Fiber.init(self, root, nil)
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Runs the script commands.
function EventSheet:execute()
  self:setUp()
  self:commands()
end
-- Sets any variable needed to indicate that this script is running.
function EventSheet:setUp()
  if self.data then
    if self.data.block then
      FieldManager.player.waitList:add(self)
    end
  end
end
-- Resets any variable that indicates that this script is running.
function EventSheet:clear()
  if self.gui then
    GUIManager:returnGUI()
    self.gui = nil
  end
  if self.data then
    if self.data.block then
      FieldManager.player.waitList:removeElement(self)
    end
    self.data.runningIndex = nil
  end
end
-- Overrides Fiber:finish.
function EventSheet:finish()
  Fiber.finish(self)
  self:clear()
end
-- Creates a new fiber in from the same root that executes given script.
-- @param(script : table) Table with name (or func) and tags. 
-- @ret(Fiber) Newly created Fiber.
function EventSheet:forkFromScript(script, ...)
  return self.root:forkFromScript(script, self.char, ...)
end

---------------------------------------------------------------------------------------------------
-- Commands
---------------------------------------------------------------------------------------------------

-- Lists of event commands files
local eventCommands = {}
for i, file in ipairs({'General', 'GUI', 'Character', 'Screen', 'Sound', 'Party'}) do
  eventCommands[i] = require('core/event/' .. file .. 'Events')
end
local meta = getmetatable(EventSheet) 
local meta_index = meta.__index
local funcMap = {}
function meta:__index(k)
  local v = meta_index(self, k)
  if v then
    return v
  end
  -- Look for event commands
  for i = 1, #eventCommands do
    if eventCommands[i][k] then
      if not funcMap[k] then
        funcMap[k] = function(script, ...)
          -- TODO: stuff to count event commands
          eventCommands[i][k](script, ...)
        end
      end
      return funcMap[k]
    end
  end
end

return EventSheet
