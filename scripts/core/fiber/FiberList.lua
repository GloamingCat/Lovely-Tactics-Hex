
--[[===============================================================================================

@classmod FiberList
---------------------------------------------------------------------------------------------------
-- A List of Fibers. Must be updated every frame.

=================================================================================================]]

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
-- @tparam Interactable char The character that created this list (optional).
function FiberList:init(char)
  List.init(self)
  self.char = char
end
--- Updates all Fibers.
function FiberList:update()
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
end

-- ------------------------------------------------------------------------------------------------
-- Fork
-- ------------------------------------------------------------------------------------------------

--- Creates new Fiber from function.
-- @tparam function func The function of the Fiber.
-- @tparam(...) Any arguments to the function.
-- @treturn Fiber The newly created Fiber.
function FiberList:fork(func, ...)
  return Fiber(self, func, ...)
end
--- Creates new EventSheet from a script table.
-- @tparam table script Table with script's name and param.
-- @treturn EventSheet The newly created Fiber.
function FiberList:forkFromScript(script, ...)
  return EventSheet(self, script, ...)
end

return FiberList
