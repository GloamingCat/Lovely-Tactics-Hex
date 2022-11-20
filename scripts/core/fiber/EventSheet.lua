
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
    self.data.running = true
  end
  self.events = {}
  Fiber.init(self, root, nil)
end
-- @ret(string) String identification.
function EventSheet:__tostring()
  local name = self.data and self.data.name
  name = name and (' ' .. name) or ''
  return 'EventSheet' .. name ..  ' from ' .. tostring(self.origin.name)
end

---------------------------------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------------------------------

-- Adds an event to the execution list.
-- @param(func : functtion) The function to be executed.
-- @param(condition : unknown) A condition to execute the command.
--  Can be either a constant or a function to be computed before the event executes.
-- @param(...) Any aditional argumentes to the event's function.
function EventSheet:addEvent(func, condition, ...)
  if condition ~= nil and type(condition) ~= 'function' then
    local value = condition
    condition = function() return value end
  end
  self.events[#self.events + 1] = {
    execute = func,
    args = {...},
    condition = condition
  }
end
-- Changes the running index to skip a number of events.
-- @param(n : number) Number of events to skip.
function EventSheet:skipEvents(n)
  self.vars.runningIndex = self.vars.runningIndex + n
end
-- Directly sets the running index.
-- @param(n : number) Index of the next event.
function EventSheet:setEvent(i)
  self.vars.runningIndex = i - 1
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Runs the script commands.
function EventSheet:execute()
  self:setUp()
  self:commands()
  if self.vars then
    self:runEvents()
  end
end
-- Runs the event created from the command execution.
function EventSheet:runEvents()
  self.vars.runningIndex = self.vars.runningIndex or 0
  while self.vars.runningIndex < #self.events do
    self.vars.runningIndex = self.vars.runningIndex + 1
    self:runCurrentEvent()
    if not self:running() or not self.vars.runningIndex then
      return
    end
  end
  self.vars.runningIndex = nil
end
-- Executes the event indicated by the current running index.
function EventSheet:runCurrentEvent()
  local event = self.events[self.vars.runningIndex]
  if not event.condition or event.condition(self) then
    event.execute(self, unpack(event.args))
  end
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
    GUIManager:removeGUI(self.gui)
    self.gui = nil
  end
  if self.data then
    if self.data.block then
      FieldManager.player.waitList:removeElement(self)
    end
    self.data.running = nil
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

return EventSheet
