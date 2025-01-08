
-- ================================================================================================

--- A List of Fibers. Must be updated every frame.
---------------------------------------------------------------------------------------------------
-- @basemod FiberList

-- ================================================================================================

-- Imports
local EventSheet = require('core/fiber/EventSheet')
local Fiber = require('core/fiber/Fiber')
local List = require('core/datastruct/List')

-- Class table.
local FiberList = class(List)

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam[opt] InteractableObject char The character that created this list.
function FiberList:init(char)
  List.init(self)
  self.char = char
  self.finished = false
end
--- Updates all Fibers.
function FiberList:update()
  assert(not self.finished, "Tried to update a terminated fiber list.")
  local i = 1
  while i <= self.size do
    self[i]:update()
    i = i + 1
  end
  self:conditionalRemove(self.isFinished)
end
--- Function that resumes a Fiber.
-- @tparam Fiber fiber Fiber to resume.
-- @treturn boolean True if Fiber ended, false otherwise.
function FiberList.isFinished(fiber)
  return fiber.coroutine == nil
end
--- Interrupts all fibers in the list.
function FiberList:destroy()
  for i = 1, self.size do
    self[i]:interrupt()
  end
  self.finished = true
end

-- ------------------------------------------------------------------------------------------------
-- Fork
-- ------------------------------------------------------------------------------------------------

--- Creates new Fiber from function.
-- @tparam function func The function of the Fiber.
-- @param ... Any arguments to the function.
-- @treturn Fiber The newly created Fiber.
function FiberList:fork(func, ...)
  return Fiber(self, func, ...)
end
--- Creates new Fiber from function.
-- @tparam table obj The object containing the method.
-- @tparam string method Name of the method.
-- @param ... Any arguments to the method (not including the object).
-- @treturn Fiber The newly created Fiber.
function FiberList:forkMethod(obj, method, ...)
  local fiber = Fiber(self, obj[method], obj, ...)
  fiber.name = tostring(obj) .. ":" .. method .. '(' .. util.array.concat({...}) .. ')'
  return fiber
end
--- Creates new EventSheet from a script table.
-- @tparam table script Table with script's name and param.
-- @tparam InteractableObject char The interactable object associated with the event sheet.
-- @treturn EventSheet The newly created Fiber.
function FiberList:forkFromScript(script, char)
  return EventSheet(self, script, char)
end

return FiberList
