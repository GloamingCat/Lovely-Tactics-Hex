
--[[===============================================================================================

FiberList
---------------------------------------------------------------------------------------------------
A List of Fibers. Must be updated every frame.

=================================================================================================]]

-- Imports
local List = require('core/datastruct/List')
local Fiber = require('core/fiber/Fiber')

local FiberList = class(List)

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Updates all Fibers.
function FiberList:update()
  for i = 1, self.size do
    self[i]:update()
  end
  self:conditionalRemove(self.finished)
end

-- Function that resumes a Fiber.
-- @param(fiber : Fiber) Fiber to resume
-- @ret(boolean) true if Fiber ended, false otherwise
function FiberList.finished(fiber)
  return fiber.coroutine == nil
end

---------------------------------------------------------------------------------------------------
-- Fork
---------------------------------------------------------------------------------------------------

-- Creates new Fiber from function.
-- @param(func : function) the function of the Fiber
-- @param(...) any arguments to the function
-- @ret(Fiber) the newly created Fiber
function FiberList:fork(func, ...)
  return Fiber(self, func, ...)
end

-- Creates new Fiber from a script table.
-- @param(script : table) script table with "path" and "param" fields
-- @param(...) any other arguments to the Fiber
-- @ret(Fiber) the newly created Fiber (nil if path is empty)
function FiberList:forkFromScript(script, ...)
  return Fiber.fromScript(self, script, ...)
end

return FiberList
