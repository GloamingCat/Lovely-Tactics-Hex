
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

-- Alias
local findTag = util.array.findByKey

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
  local name
  if data.func then
    self.commands = data.func
    name = data.name
  elseif tonumber(data.name) or Database.events[data.name] then
    self.sheet = Database.events[tonumber(data.name) or data.name]
    self.commands = self.processSheet
    self.tags = Database.loadTags(self.sheet.tags)
    name = self.sheet.name
  else
    local func = require('custom/' .. data.name)
    assert(func, "Could not load event sheet file: " .. tostring(data.name))
    self.commands = func
    name = data.name
  end
  self.data = data
  self.vars = data and data.vars
  self.args = Database.loadTags(data.tags)
  self.char = char
  if self.char then
    self.vars.char = self.char.key
  end
  if self.data then
    self.data.running = true
  end
  self.events = {}
  self.labels = {}
  Fiber.init(self, root, nil)
  self.name = name or self.name
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
function EventSheet:addEvent(func, condition, args)
  if condition ~= nil and type(condition) ~= 'function' then
    local value = condition
    condition = function()
      return self:evaluate(value)
    end
  end
  if type(func) == 'string' then
    if self[func] then
      func = self[func]
    else
      local body = func
      func = function(script)
        return loadfunction(self:interpolateString(body), 'script')(script)
      end
    end
  else
    assert(func, "nil event function")
  end
  self.events[#self.events + 1] = {
    execute = func,
    args = args,
    condition = condition
  }
end
--- Adds each event in the event sheet.
function EventSheet:processSheet()
  self.labels['start'] = 1
  self.labels['end'] = -1
  for _, e in ipairs(self.sheet.events) do
    local condition = e.condition ~= '' and e.condition or nil
    if e.name == 'setLabel' then
      local name = findTag(e.tags, 'name')
      self:setLabel(name.value)
    else
      self:addEvent(e.name, condition, e.tags)
    end
  end
end
--- Stores a label name.
-- @tparam string name Name of the label.
function EventSheet:setLabel(name)
  self.labels[name] = #self.events + 1
end

-- ------------------------------------------------------------------------------------------------
-- Flow Events
-- ------------------------------------------------------------------------------------------------

--- Changes the running index to skip a number of events.
-- @tparam[opt] table args Argument table when called from an event sheet.
-- @tparam number n Number of events to skip.
function EventSheet:skipEvents(args, n)
  n = n or args.events
  self.vars.runningIndex = self.vars.runningIndex + n
end
--- Directly sets the running index.
-- @tparam[opt] table args Argument table when called from an event sheet.
-- @tparam number i Index of the next event.
function EventSheet:setEvent(args, i)
  i = i or args.index
  if i == -1 then
    self.vars.runningIndex = #self.events
  else
    self.vars.runningIndex = i - 1
  end
end
--- Sets the next event to the one pointed by the given label.
-- @tparam[opt] table args Argument table when called from an event sheet.
-- @tparam string name Name of the label.
function EventSheet:jumpTo(args, name)
  name = name or args.name
  assert(self.labels[name], 'Label not defined: ' .. name)
  self:setEvent(nil, self.labels[name])
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
  self.startIndex = self.vars.runningIndex or 0
  if self.vars.runningIndex and not FieldManager:loadedFromSave() then
    local char = self.char and ' of character ' .. self.char.name or ''
    error('Script ' .. tostring(self.data.name) .. char .. " shouldn't be running.")
  end
  self.vars.runningIndex = self.vars.runningIndex or 0
  while self.vars.runningIndex < #self.events do
    self.vars.runningIndex = self.vars.runningIndex + 1
    self:runCurrentEvent()
    if not self:isRunning() or not self.vars.runningIndex then
      break
    end
  end
  self.vars.runningIndex = nil
  self.vars.collider = nil
  self.vars.collided = nil
  self.vars.interacting = nil
  self.vars.loading = nil
  self.vars.exit = nil
  self.vars.destroyer = nil
end
--- Executes the event indicated by the current running index.
function EventSheet:runCurrentEvent()
  local event = self.events[self.vars.runningIndex]
  if not event.condition or event.condition(self) then
    event.execute(self, Database.loadTags(event.args))
  end
end
--- Sets any variable needed to indicate that this script is running.
function EventSheet:setUp()
  if self.data.block then
    FieldManager.currentField.blockingFibers:add(self)
  end
end
--- Resets any variable that indicates that this script is running.
function EventSheet:clear()
  if self.menu then
    MenuManager:removeMenu(self.menu)
    self.menu = nil
  end
  if self.data.block then
    FieldManager.currentField.blockingFibers:removeElement(self)
  end
  self.data.running = nil
end
--- Overrides `Fiber:finish`. 
-- @override
function EventSheet:finish()
  Fiber.finish(self)
  self:clear()
end
--- Overrides `Fiber:printStackTrace`. 
-- @override
function EventSheet:printStackTrace(msg)
  local index = tostring(self.vars and self.vars.runningIndex or nil)
  local sindex = tostring(self.startIndex)
  Fiber.printStackTrace(self, msg .. ' (runningIndex: ' .. index .. '-' .. sindex .. ')')
end
-- For debugging.
function EventSheet:__tostring()
  if self.char then
    return 'EventSheet: ' .. self.char.key .. ':' .. tostring(self.name)
  else
    return 'EventSheet: ' .. tostring(self.name)
  end
end

return EventSheet
