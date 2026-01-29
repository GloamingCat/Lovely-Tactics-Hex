
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
local TagMap = require('core/datastruct/TagMap')
local Serializer = require('core/save/Serializer')

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
  local name = data.name
  if data.func then
    self.commands = data.func
    self.tags = Database.loadTags(nil)
  elseif data.sheet then
    self.sheet = data.sheet
    self.commands = self.processSheet
    self.tags = Database.loadTags(self.sheet.tags)
  elseif tonumber(name) or Database.events[name] then
    self.sheet = Database.events[tonumber(name) or name]
    self.commands = self.processSheet
    self.tags = Database.loadTags(self.sheet.tags)
    name = self.sheet.name
  else
    local func = require('custom/' .. name)
    assert(func, "Could not load event sheet file: " .. tostring(name))
    self.commands = func
    self.tags = Database.loadTags(nil)
  end
  self.data = data
  self.vars = data and data.vars
  self.args = Database.loadTags(data.tags)
  self.char = char
  if self.char then
    self.vars.key = self.char.key
  end
  if self.data then
    self.data.running = true
  end
  self.events = {}
  self.labels = {}
  Fiber.init(self, root, char, nil)
  self.name = name or self.name
  self:setUp()
end

-- ------------------------------------------------------------------------------------------------
-- Events
-- ------------------------------------------------------------------------------------------------

--- Adds an event to the execution list.
-- @tparam function|string func The function to be executed, the name of the event, or the
--  the function's code.
-- @tparam[opt] table args The arguments table passed to the event function.
-- @param[opt] condition A condition to execute the command.
--  Can be either a constant value or a `function` to be computed before the event executes.
-- @tparam[opt] boolean unskippable When true, the skip command will stop at this command.
function EventSheet:addEvent(func, args, condition, unskippable)
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
    condition = condition,
    args = args,
    unskippable = unskippable }
end
--- Adds each event in the event sheet and sets the indexes of each label.
function EventSheet:processSheet()
  self.labels['start'] = 1
  self.labels['end'] = -1
  for _, e in ipairs(self.sheet.events) do
    local condition = e.condition ~= '' and e.condition or nil
    if e.name == 'setLabel' then
      local name = findTag(e.tags, 'name').value
      self:setLabel(Serializer.decode(name) or name)
    else
      self:addEvent(e.name, e.tags, condition, e.unskippable)
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

--- Directly sets the running index.
-- @tparam number|table args Index of the next event.
--  If it's an argument table, this should be the field `args.index`.
function EventSheet:setEvent(args)
  local i = type(args) == 'table' and args.index or args
  if i == -1 then
    self.vars.runningIndex = #self.events
  else
    self.vars.runningIndex = i - 1
  end
end
--- Changes the running index to skip a number of events.
-- @tparam number|table args Number of events to skip.
--  If it's an argument table, this should be the field `args.events`.
function EventSheet:skipEvents(args)
  local n = type(args) == 'table' and args.events or args 
  self.vars.runningIndex = self.vars.runningIndex + n
end
--- Sets the next event to the one pointed by the given label.
-- @tparam string|table args Name of the label.
--  If it's an argument table, this should be the field `args.name`.
function EventSheet:jumpTo(args)
  local name = type(args) == 'table' and args.name or args 
  assert(self.labels[name], 'Label not defined: ' .. name)
  self:setEvent(self.labels[name])
end

-- ------------------------------------------------------------------------------------------------
-- Execution
-- ------------------------------------------------------------------------------------------------

--- Overrides `Fiber:update`.
-- @override
function EventSheet:update()
  if self.vars.runningIndex and self.sheet.skippable then
    if InputManager.keys["next"]:isTriggered() then
      self.skipped = true
    end
  end
  Fiber.update(self)
end
--- Implements `Fiber:execute`. Runs the script commands.
-- @implement
function EventSheet:execute()
  self:commands()
  if self.vars then
    self:runEvents()
  end
end
--- Runs the event created from the command execution.
-- @coroutine
function EventSheet:runEvents()
  self.startIndex = self.vars.runningIndex or 0
  if self.vars.runningIndex and not FieldManager:loadedFromSave() then
    local char = self.char and ' of character ' .. self.char.name or ''
    print('Script ' .. tostring(self.data.name) .. char .. " shouldn't be running.")
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
-- @coroutine
function EventSheet:runCurrentEvent()
  local event = self.events[self.vars.runningIndex]
  if event.unskippable then
    self.skipped = false
  end
  if not event.condition or event.condition(self) then
    event.execute(self, TagMap(event.args))
  end
end
--- Sets any variable needed to indicate that this script is running.
function EventSheet:setUp()
  if self.data.block then
    FieldManager.currentField.blockingFibers:add(self)
  end
  if self.data.skippable then
    self:createMenu()
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
  local str = 'EventSheet'
  if self.skipped then
    str = str .. ' (skipped)'
  end
  if not self.coroutine then
    str = str .. ' (finished)'
  end
  if self.char then
    return str .. ': ' .. self.char.key .. ':' .. tostring(self.name)
  else
    return str .. ': ' .. tostring(self.name)
  end
end

return EventSheet
