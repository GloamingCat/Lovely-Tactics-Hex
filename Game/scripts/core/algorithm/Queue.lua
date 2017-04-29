
--[[===============================================================================================

Queue
---------------------------------------------------------------------------------------------------
A queue datatype implementation. See more in:
http://en.wikipedia.org/wiki/Queue_(abstract_data_type)

=================================================================================================]]

local Queue = class()

-- Constructor.
function Queue:init()
  self.back = 1
  self.front = 1
end

-- Adds new element at the end back of the queue.
-- @param(elem : unknown) the new element
function Queue:push(elem)
  self[self.back] = elem
  self.back = self.back + 1
end

-- Removes elements from the front of the queue.
-- @ret(unknown) the element removed
function Queue:pop()
  assert(not self:empty())
  local ret = self[self.front]
  self[self.front] = nil
  self.front = self.front + 1
  return ret
end

-- @ret(boolean) true if queue is empty, false otherwise
function Queue:empty()
  return self.front == self.back
end

-- @ret(string) the string representation.
function Queue:__tostring()
  if self:empty() then
    return 'Queue {}'
  end
  local s = 'Queue {' .. tostring(self[self.front])
  for i = self.front + 1, self.back do
    s = s .. ', ' .. tostring(self[i])
  end
  return s .. '}'
end

return Queue
