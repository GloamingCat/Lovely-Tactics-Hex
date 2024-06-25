
-- ================================================================================================

--- A fiber that processes a list of sequential commands.
---------------------------------------------------------------------------------------------------
-- @basemod EventSheet
-- @extend Fiber
-- @extend EventUtil

-- ================================================================================================

-- Imports
local EventUtil = require('core/event/EventUtil')
local Fiber = require('core/fiber/Fiber')
local TextParser = require('core/graphics/TextParser')

-- Class table.
local EventSheet = class(Fiber, EventUtil)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam FiberList root The FiberList that originated this fiber.
-- @tparam table data Table with name (or func) and tags.
-- @tparam[opt] Character char Character associated with this fiber.
function EventSheet:init(root, data, char)
  if data.func then
    self.commands = data.func
  elseif tonumber(data.name) or Database.events[data.name] then
    self.sheet = Database.events[tonumber(data.name) or data.name]
    self.commands = self.processSheet
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
  self:setUp()
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
-- @param ... Any aditional argumentes to the event's function.
function EventSheet:addEvent(func, condition, ...)
  if condition ~= nil and type(condition) ~= 'function' then
    local value = condition
    condition = function()
      local val = self:evaluate(value)
      return val
    end
  end
  if type(func) == 'string' then
    if self[func] then
      func = self[func]
    else
      local body = func
      func = function(script)
        return loadfunction(TextParser.evaluate(body), 'script')(script)
      end
    end
  else
    assert(func, "nil event function")
  end
  self.events[#self.events + 1] = {
    execute = func,
    args = {...},
    condition = condition
  }
end
--- Adds each event in the event sheet.
-- The events `setLabel`, `skipEvents`, `setEvent`, `jumpTo` and `wait` are treated
-- differently.
function EventSheet:processSheet()
  for _, e in ipairs(self.sheet.events) do
    local args = Database.loadTags(e.tags)
    local condition = e.condition ~= '' and e.condition or nil
    if e.name == 'setLabel' then
      self:setLabel(args.name, args.index)
    else
      if e.name == 'skipEvents' then
        args = args.events
      elseif e.name == 'setEvent' then
        args = args.index
      elseif e.name == 'jumpTo' then
        args = args.name
      elseif e.name == 'wait' then
        args = args.time
      end
      self:addEvent(e.name, condition, args)
    end
  end
end
--- Changes the running index to skip a number of events.
-- @tparam number n Number of events to skip.
function EventSheet:skipEvents(n)
  self.vars.runningIndex = self.vars.runningIndex + n
end
--- Directly sets the running index.
-- @tparam number i Index of the next event.
function EventSheet:setEvent(i)
  if i == -1 then
    self.vars.runningIndex = #self.events
  else
    self.vars.runningIndex = i - 1
  end
end
--- Stores a label name.
-- @tparam string name Name of the label.
-- @tparam[opt=-1] number i The index that the label points to. If -1, sets as the last event.
function EventSheet:setLabel(name, i)
  if not i or i == -1 then
    i = #self.events + 1
  end
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

--- Implements `Fiber:execute`. Runs the script commands.
-- @implement
function EventSheet:execute()
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
  self.vars.collider = nil
  self.vars.collided = nil
  self.vars.interacting = nil
  self.vars.loading = nil
  self.vars.exit = nil
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
      FieldManager.currentField.blockingFibers:add(self)
    end
  end
end
--- Resets any variable that indicates that this script is running.
function EventSheet:clear()
  if self.menu then
    MenuManager:removeMenu(self.menu)
    self.menu = nil
  end
  if self.data then
    if self.data.block then
      FieldManager.currentField.blockingFibers:removeElement(self)
    end
    self.data.running = nil
  end
end
--- Overrides `Fiber:finish`. 
-- @override
function EventSheet:finish()
  Fiber.finish(self)
  self:clear()
end
--- Evaluates a raw string, replacing variable occurences and then parsing it as a Lua expression.
-- @tparam string value The raw string.
-- @return The evaluated expression.
function EventSheet:evaluate(value)
  if type(value) == 'function' then
    return value(self)
  elseif type(value) ~= 'string' then
    return value
  else
    return loadformula(TextParser.evaluate(value), "script")(self)
  end
end
--- Creates a new fiber in from the same root that executes given script.
-- @tparam table script Table with name (or func) and tags.
-- @treturn Fiber Newly created Fiber.
function EventSheet:forkFromScript(script, ...)
  return self.root:forkFromScript(script, self.char, ...)
end
-- For debugging.
function EventSheet:__tostring()
  local name = self.data and self.data.name
  name = name and (' ' .. name) or ''
  return 'EventSheet' .. name ..  ' from ' .. tostring(self.origin.name)
end

return EventSheet
