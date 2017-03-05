
--[[

A queue datatype implementation. See more in:
http://en.wikipedia.org/wiki/Queue_(abstract_data_type)

]]

local Queue = require('core/class'):new()

function Queue:init()
  self.contents = {}
  self.back = 1
  self.front = 1
end

--@param(elem : A) The new element to push to the back of the queue
function Queue:push(elem)
  self.contents[self.back] = elem
  self.back = self.back + 1
end

--@ret(A) the element popped from the front of the queue
function Queue:pop()
  assert(not self:empty())

  --@var(unknown)
  local ret = self.contents[self.front]
  self.contents[self.front] = nil
  self.front = self.front + 1
  return ret
end

--@ret(boolean) whether or not the queue is empty
function Queue:empty()
  return self.front == self.back
end


return Queue
