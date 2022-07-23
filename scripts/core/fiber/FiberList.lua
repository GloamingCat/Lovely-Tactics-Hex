
--[[===============================================================================================

FiberList
---------------------------------------------------------------------------------------------------
A List of Fibers. Must be updated every frame.

=================================================================================================]]

-- Imports
local EventSheet = require('core/fiber/EventSheet')
local Fiber = require('core/fiber/Fiber')
local List = require('core/datastruct/List')

local FiberList = class(List)

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(char : Interactable) The character that created this list (optional).
function FiberList:init(char)
  List.init(self)
  self.char = char
end
-- Updates all Fibers.
function FiberList:update()
  local i = 1
  while i <= self.size do
    self[i]:update()
    i = i + 1
  end
  self:conditionalRemove(self.isFinished)
end
-- Function that resumes a Fiber.
-- @param(fiber : Fiber) Fiber to resume.
-- @ret(boolean) True if Fiber ended, false otherwise.
function FiberList.isFinished(fiber)
  return fiber.coroutine == nil
end

---------------------------------------------------------------------------------------------------
-- Fork
---------------------------------------------------------------------------------------------------

-- Creates new Fiber from function.
-- @param(func : function) The function of the Fiber.
-- @param(...) Any arguments to the function.
-- @ret(Fiber) The newly created Fiber.
function FiberList:fork(func, ...)
  return Fiber(self, func, ...)
end
-- Creates new EventSheet from a script table.
-- @param(script : table) Table with script's name and param.
-- @ret(EventSheet) The newly created Fiber.
function FiberList:forkFromScript(script, ...)
  local sheet = EventSheet(self, script, ...)
  return sheet
end
-- Creates new Fiber from a script table.
-- @param(func : function) The function of the Fiber.
-- @param(script : table) Table with script's name and param.
-- @ret(EventSheet) The newly created Fiber.
function FiberList:forkEvent(func, script, ...)
  local args = {...}
  local data = {
    func = function () func(script, unpack(args)) end, 
    vars = script.vars,
    block = script.block }
  return self:forkFromScript(data, script.char, ...)
end

return FiberList
