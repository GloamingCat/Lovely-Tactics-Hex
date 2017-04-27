
--[[===========================================================================

PriorityQueue
-------------------------------------------------------------------------------
A priority queue with numeric keys. Be default, the element in the front will 
be the one with the lowest key. See more in:
https://en.wikipedia.org/wiki/Priority_queue

TODO: implement a more efficient version (heap)
TODO: implement toString

=============================================================================]]

-- Imports
local List = require('core/algorithm/List')

-- Alias
local sort = table.sort

local PriorityQueue = require('core/class'):new()

-- @param(comp : function) the function to compares two pairs (optional)
function PriorityQueue:init(comp)
  self.comp = self.comp or comp
  self.size = 0
end

-- Default compare function
function PriorityQueue.comp(a, b)
  return a[2] > b[2]
end

-- Adds new pair to the queue.
-- @param(element : unknown) the new element to add
-- @param(p : number) the priority of the element
function PriorityQueue:enqueue(element, p)
  self.size = self.size + 1
  self[self.size] = {element, p}
  sort(self, self.comp)
end

-- Removes the front pair.
-- @ret(unknown) the element removed
-- @ret(number) the key/priority of the element removed
function PriorityQueue:dequeue()
  assert(self.size > 0, 'Priority queue is empty!')
  local pair = self[self.size]
  self[self.size] = nil
  self.size = self.size - 1
  return pair[1], pair[2]
end

-- Gets the element with the highest priority.
-- @ret(unknown) the front element
-- @ret(number) the key/priority of the front element
function PriorityQueue:front()
  assert(self.size > 0, 'Priority queue is empty!')
  local pair = self[self.size]
  return pair[1], pair[2]
end

-- Checks if empty.
function PriorityQueue:isEmpty()
  return self.size == 0
end

-- Transform this queue into a list of elements (does not include keys).
-- @ret(List) list of arbitrary elements
function PriorityQueue:toList()
  local list = List()
  while self.size > 0 do
    local e = self:dequeue()
    list:add(e)
  end
  return list
end

return PriorityQueue
