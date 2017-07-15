
--[[===============================================================================================

Stack
---------------------------------------------------------------------------------------------------
A stack datatype implementation. See more in:
http://en.wikipedia.org/wiki/Stack_(abstract_data_type)

TODO: implement toString

=================================================================================================]]

local Stack = class()

-- Constructor. Starts empty.
function Stack:init()
  self.size = 0
end

-- Adds new element at the top of the stack.
-- @param(elem : unknown) The new element to push to the top of the stack
function Stack:push(elem)
  self.size = self.size + 1
  self[self.size] = elem
end

-- Gets the element in the top of the stack (does not remove it).
-- @ret(unknown) the element at the top of the stack
function Stack:peek()
  return self[self.size]
end

-- Removes the element in the top of the stack (throws error if stack is empty).
-- @ret(unknown) the element popped from the top of the stack
function Stack:pop()
  assert(self.size > 0, "Attempt to pop an empty stack")
  local elem = self[self.size]
  self[self.size] = nil
  self.size = self.size - 1
  return elem  
end

-- Checks if empty.
-- @ret(boolean) whether or not the stack is empty
function Stack:isEmpty()
  return self.size == 0
end

return Stack
