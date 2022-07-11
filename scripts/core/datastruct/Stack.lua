
--[[===============================================================================================

Stack
---------------------------------------------------------------------------------------------------
A stack datatype implementation. See more in:
http://en.wikipedia.org/wiki/Stack_(abstract_data_type)

=================================================================================================]]

local Stack = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor. Starts empty.
function Stack:init()
  self.size = 0
end

---------------------------------------------------------------------------------------------------
-- Operators
---------------------------------------------------------------------------------------------------

-- Adds new element at the top of the stack.
-- @param(elem : unknown) The new element to push to the top of the stack.
function Stack:push(elem)
  self.size = self.size + 1
  self[self.size] = elem
end
-- Adds new elements at the top of the stack.
-- @param(arr : table) Array of new elements to push to the top of the stack.
function Stack:pushAll(arr)
  for i, elem in ipairs(arr) do
    self[self.size + i] = elem
  end
  self.size = self.size + #arr
end
-- Gets the element in the top of the stack (does not remove it).
-- @ret(unknown) The element at the top of the stack.
function Stack:peek()
  return self[self.size]
end
-- Removes the element in the top of the stack (throws error if stack is empty).
-- @ret(unknown) The element popped from the top of the stack.
function Stack:pop()
  assert(self.size > 0, "Attempt to pop an empty stack")
  local elem = self[self.size]
  self[self.size] = nil
  self.size = self.size - 1
  return elem  
end
-- Checks if empty.
-- @ret(boolean) Whether or not the stack is empty.
function Stack:isEmpty()
  return self.size == 0
end

---------------------------------------------------------------------------------------------------
-- Convertion
---------------------------------------------------------------------------------------------------

-- Converting to string.
-- @ret(string) A string representation.
function Stack:__tostring()
  local i = self.size
  if i == 0 then
    return 'Stack {}'
  end
  local string = 'Stack {'
  for i = self.size, 2, -1 do
    string = string .. tostring(self[i]) .. ', '
  end
  return string .. tostring(self[1]) .. '}'
end

return Stack
