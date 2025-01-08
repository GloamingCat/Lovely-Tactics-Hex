
-- ================================================================================================

--- A queue datatype implementation. See more in:
-- http://en.wikipedia.org/wiki/Queue_(abstract_data_type)
---------------------------------------------------------------------------------------------------
-- @basemod Queue

-- ================================================================================================

-- Class table.
local Queue = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
function Queue:init()
  self.back = 1
  self.front = 1
end

-- ------------------------------------------------------------------------------------------------
-- Operators
-- ------------------------------------------------------------------------------------------------

--- Adds new element at the end back of the queue.
-- @tparam unknown elem The new element to be added at the end of the queue.
function Queue:push(elem)
  self[self.back] = elem
  self.back = self.back + 1
end
--- Adds new elements at the end back of the queue.
-- @tparam table arr Array of new elements to push to the top of the stack.
function Queue:pushAll(arr)
  for i, elem in ipairs(arr) do
    self[self.back + i] = elem
  end
  self.back = self.back + #arr
end
--- Removes elements from the front of the queue.
-- @treturn unknown The element removed.
function Queue:pop()
  assert(not self:isEmpty())
  local ret = self[self.front]
  self[self.front] = nil
  self.front = self.front + 1
  return ret
end
--- Checks if queue is empty.
-- @treturn boolean True if queue is empty, false otherwise.
function Queue:isEmpty()
  return self.front == self.back
end
-- For debugging.
function Queue:__tostring()
  if self:isEmpty() then
    return 'Queue {}'
  end
  local s = 'Queue {' .. tostring(self[self.front])
  for i = self.front + 1, self.back do
    s = s .. ', ' .. tostring(self[i])
  end
  return s .. '}'
end

return Queue
