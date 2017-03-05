
--[[===========================================================================

A stack datatype implementation. See more in:
http://en.wikipedia.org/wiki/Stack_(abstract_data_type)

=============================================================================]]

local Stack = require('core/class'):new()

function Stack:init()
  self.size = 0
end

-- @param(elem : unknown) The new element to push to the top of the stack
function Stack:push(elem)
  self.size = self.size + 1
  self[self.size] = elem
end

-- @ret(unknown) The element at the top of the stack
function Stack:peek()
  return self[self.size]
end

-- @ret(unknown) the element popped from the front of the queue
function Stack:pop()
  assert(self.size > 0, "Attempt to pop an empty stack")
  local elem = self[self.size]
  self[self.size] = nil
  self.size = self.size - 1
  return elem  
end

-- @ret(boolean) whether or not the queue is empty
function Stack:isEmpty()
  return self.size == 0
end

return Stack
