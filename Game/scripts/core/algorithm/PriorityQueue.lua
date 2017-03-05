
local sort = table.sort

--[[===========================================================================

A priority queue with numeric keys.
TODO: implement a more efficient version

=============================================================================]]

local PriorityQueue = require('core/class'):new()

local function comp(a, b)
  return a[2] > b[2]
end

function PriorityQueue:init(comp)
  self.size = 0
end

function PriorityQueue:enqueue(element, p)
  self.size = self.size + 1
  self[self.size] = {element, p}
  sort(self, comp)
end

function PriorityQueue:dequeue()
  assert(self.size > 0, 'Prioriry queue is empty!')
  local pair = self[self.size]
  self[self.size] = nil
  self.size = self.size - 1
  return pair[1], pair[2]
end

function PriorityQueue:isEmpty()
  return self.size == 0
end

return PriorityQueue
