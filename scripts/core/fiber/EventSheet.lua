
--[[===============================================================================================

@classmod EventSheet
---------------------------------------------------------------------------------------------------
A fiber that processes a list of sequential commands.

=================================================================================================]]

-- Imports
local EventUtil = require('core/event/EventUtil')
local Fiber = require('core/fiber/Fiber')

-- Class table.
local EventSheet = class(Fiber, EventUtil)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam FiberList root The FiberList that originated this fiber.
-- @tparam table script Table with name (or func) and tags.
-- @tparam Character char Character associated with this fiber (optional).
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
  self.labels = {}
  Fiber.init(self, root, nil)
end
-- @treturn string String identification.
function EventSheet:__tostring()
  local name = self.data and self.data.name
  name = name and (' ' .. name) or ''
  return 'EventSheet' .. name ..  ' from ' .. tostring(self.origin.name)
end

-- ------------------------------------------------------------------------------------------------
-- Events
-- ------------------------------------------------------------------------------------------------

--- Adds an event to the execution list.
-- @tparam functtion|string func The function to be executed, the name of the event, or the
--  the function's code.
-- @tparam function|unknown condition A condition to execute the command, either a function or
--  a constant value.
--  Can be either a constant or a function to be computed before the event executes.
-- @tparam(...) Any aditional argumentes to the event's function.
function EventSheet:addEvent(func, condition, ...)
  if condition ~= nil and type(condition) ~= 'function' then
    local value = condition
    condition = function() return value end
  end
  if type(func) == 'string' then
    if self[func] then
      func = self[func]
    else
      func = loadfunction(func, 'script, args')
    end
  end
  self.events[#self.events + 1] = {
    execute = func,
    args = {...},
    condition = condition
  }
end
--- Changes the running index to skip a number of events.
-- @tparam number n Number of events to skip.
function EventSheet:skipEvents(n)
  self.vars.runningIndex = self.vars.runningIndex + n
end
--- Directly sets the running index.
-- @tparam number i Index of the next event.
function EventSheet:setEvent(i)
  self.vars.runningIndex = i - 1
end
--- Stores a label name.
-- @tparam string name Name of the label.
-- @tparam number i The index that the label points to (optional, last event by default).
function EventSheet:setLabel(name, i)
  i = i or #self.events + 1
  self.labels[name] = i
end
--- Sets the next event to the one pointed by the given label.
-- @tparam string name Name of the label.
function EventSheet:jumpTo(name)
  assert(self.labels[name], 'Label not defined: ' .. name)
  self:setEvent(self.labels[name])
end

-- ------------------------------------------------------------------------------------------------
-- Execution
-- ------------------------------------------------------------------------------------------------

--- Runs the script commands.
function EventSheet:execute()
  self:setUp()
  self:commands()
  if self.vars then
    self:runEvents()
  end
end
--- Runs the event created from the command execution.
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
--- Executes the event indicated by the current running index.
function EventSheet:runCurrentEvent()
  local event = self.events[self.vars.runningIndex]
  if not event.condition or event.condition(self) then
    event.execute(self, unpack(event.args))
  end
end
--- Sets any variable needed to indicate that this script is running.
function EventSheet:setUp()
  if self.data then
    if self.data.block then
      FieldManager.player.waitList:add(self)
    end
  end
end
--- Resets any variable that indicates that this script is running.
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
--- Overrides Fiber:finish.
function EventSheet:finish()
  Fiber.finish(self)
  self:clear()
end
--- Creates a new fiber in from the same root that executes given script.
-- @tparam table script Table with name (or func) and tags.
-- @treturn Fiber Newly created Fiber.
function EventSheet:forkFromScript(script, ...)
  return self.root:forkFromScript(script, self.char, ...)
end

return EventSheet
